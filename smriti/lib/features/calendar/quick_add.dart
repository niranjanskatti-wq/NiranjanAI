import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import '../calendar_sync/calendar_import.dart' show matchPerson;

enum QuickKind { birthday, anniversary, other }

/// Saves a date added straight from the calendar. New names become new people;
/// a name already in Smriti is used as is. Returns the event id.
class QuickAdd {
  QuickAdd(this.db) : repo = Repository(db);

  final AppDatabase db;
  final Repository repo;

  /// The person's current birthday, if they already have one.
  Future<EventEntry?> existingBirthday(int personId) async => (await repo.watchEntriesForPerson(personId).first)
      .where((e) => e.type == EventType.birthday && e.kind == EventKind.person)
      .firstOrNull;

  Future<int> _person(String name, Relationship relation) async {
    final found = matchPerson(name, await repo.allPeople());
    if (found != null) return found.id;
    return repo.insertPerson(PeopleCompanion.insert(name: name.trim(), relationship: Value(relation.name)));
  }

  Future<int> save({
    required QuickKind kind,
    required int day,
    required int month,
    String name = '',
    String partner = '',
    String title = '',
    int? year,
    Relationship relation = Relationship.friend,
    Repeat repeat = Repeat.yearly,
    int? replaceEventId,
  }) async {
    switch (kind) {
      case QuickKind.birthday:
        final pid = await _person(name, relation);
        final data = EventsCompanion.insert(
            kind: EventKind.person.name, type: EventType.birthday.name, day: day, month: month, year: Value(realYear(year)));
        final id = await repo.saveEvent(id: replaceEventId, data: data, personIds: [pid]);
        if (realYear(year) != null) await repo.setBirthYear(pid, realYear(year));
        return id;
      case QuickKind.anniversary:
        final ids = [await _person(name, relation), if (partner.trim().isNotEmpty) await _person(partner, relation)];
        return repo.saveEvent(
          data: EventsCompanion.insert(
            kind: (ids.length > 1 ? EventKind.couple : EventKind.person).name,
            type: EventType.weddingAnniversary.name,
            day: day,
            month: month,
            year: Value(realYear(year)),
          ),
          personIds: ids,
        );
      case QuickKind.other:
        return repo.saveEvent(
          data: EventsCompanion.insert(
            kind: EventKind.other.name,
            type: EventType.otherDate.name,
            title: Value(title.trim()),
            day: day,
            month: month,
            repeat: Value(repeat.name),
            year: Value(repeat == Repeat.once ? year : null),
          ),
          personIds: const [],
        );
    }
  }
}

/// Bottom sheet: add a birthday, anniversary or other date on [date].
Future<void> showQuickAdd(BuildContext context, Day date) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _QuickAddSheet(date: date),
    );

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet({required this.date});

  final Day date;

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  QuickKind _kind = QuickKind.birthday;
  final _name = TextEditingController();
  final _partner = TextEditingController();
  final _title = TextEditingController();
  final _year = TextEditingController();
  Relationship _relation = Relationship.friend;
  Repeat _repeat = Repeat.yearly;
  bool _saving = false;

  Day get d => widget.date;

  @override
  void dispose() {
    _name.dispose();
    _partner.dispose();
    _title.dispose();
    _year.dispose();
    _nameFocus.dispose();
    _partnerFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (_kind != QuickKind.other && name.isEmpty) return showToast(context, 'Please type a name');
    if (_kind == QuickKind.other && _title.text.trim().isEmpty) return showToast(context, 'Please type what it is');
    final year = int.tryParse(_year.text.trim());
    if (_kind == QuickKind.other && _repeat == Repeat.once && year == null) {
      return showToast(context, 'A one-time date needs a year');
    }
    final q = QuickAdd(ref.read(databaseProvider));
    int? replace;
    if (_kind == QuickKind.birthday) {
      final existing = matchPerson(name, await q.repo.allPeople());
      final old = existing == null ? null : await q.existingBirthday(existing.id);
      if (old != null && mounted) {
        if (old.event.day == d.day && old.event.month == d.month) {
          return showToast(context, '${existing!.shortName} already has this birthday');
        }
        final ok = await confirm(context,
            title: '${existing!.shortName} already has a birthday',
            message: 'It is saved as ${fmtEventDate(day: old.event.day, month: old.event.month)}. '
                'Change it to ${d.day} ${monthNames[d.month - 1]}?',
            action: 'Change it');
        if (!ok) return;
        replace = old.event.id;
      }
    }
    setState(() => _saving = true);
    await q.save(
      kind: _kind,
      day: d.day,
      month: d.month,
      name: name,
      partner: _partner.text,
      title: _title.text,
      year: year,
      relation: _relation,
      repeat: _repeat,
      replaceEventId: replace,
    );
    HapticFeedback.lightImpact();
    if (!mounted) return;
    Navigator.pop(context);
    showToast(context, 'Added on ${d.day} ${monthNames[d.month - 1]}');
  }

  final _nameFocus = FocusNode();
  final _partnerFocus = FocusNode();

  Widget _nameField(TextEditingController controller, FocusNode focus, String label, List<Person> people) =>
      RawAutocomplete<Person>(
        textEditingController: controller,
        focusNode: focus,
        optionsBuilder: (v) {
          final q = v.text.trim().toLowerCase();
          if (q.isEmpty) return const Iterable<Person>.empty();
          return people
              .where((p) => p.name.toLowerCase().contains(q) || (p.nickname ?? '').toLowerCase().contains(q))
              .take(6);
        },
        displayStringForOption: (p) => p.name,
        fieldViewBuilder: (context, field, focus, onSubmit) => TextField(
          controller: field,
          focusNode: focus,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: label, helperText: 'Type a new name, or pick someone already saved'),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final p in options)
                    ListTile(
                      dense: true,
                      leading: PersonAvatar(person: p, size: 30),
                      title: Text(p.name),
                      onTap: () => onSelected(p),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final people = [...?ref.watch(peopleProvider).value];
    final kindLabel = switch (_kind) {
      QuickKind.birthday => 'Year of birth (optional)',
      QuickKind.anniversary => 'Year of marriage (optional)',
      QuickKind.other => _repeat == Repeat.once ? 'Year' : 'Year (optional)',
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Add on ${d.day} ${monthNames[d.month - 1]}', style: context.text.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<QuickKind>(
            segments: const [
              ButtonSegment(value: QuickKind.birthday, label: Text('Birthday')),
              ButtonSegment(value: QuickKind.anniversary, label: Text('Anniversary')),
              ButtonSegment(value: QuickKind.other, label: Text('Other')),
            ],
            selected: {_kind},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 12),
          if (_kind == QuickKind.other) ...[
            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What is it?', hintText: 'e.g. Car insurance, Rent'),
            ),
            const SizedBox(height: 8),
            SegmentedButton<Repeat>(
              segments: [for (final r in Repeat.values) ButtonSegment(value: r, label: Text(r.label))],
              selected: {_repeat},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _repeat = s.first),
            ),
          ] else ...[
            _nameField(_name, _nameFocus, _kind == QuickKind.anniversary ? 'Name' : 'Whose birthday?', people),
            if (_kind == QuickKind.anniversary) ...[
              const SizedBox(height: 8),
              _nameField(_partner, _partnerFocus, 'and (husband / wife, optional)', people),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final r = await pickRelationship(context, _relation);
                  if (r != null) setState(() => _relation = r);
                },
                icon: const Icon(Icons.people_outline, size: 18),
                label: Text('Relation for new people: ${_relation.label}'),
              ),
            ),
          ],
          const SizedBox(height: 4),
          TextField(
            controller: _year,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            decoration: InputDecoration(labelText: kindLabel),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Add')),
          TextButton(
            onPressed: () {
              final kind = switch (_kind) {
                QuickKind.birthday => 'person&type=birthday',
                QuickKind.anniversary => 'couple',
                QuickKind.other => 'other',
              };
              final router = GoRouter.of(context);
              Navigator.pop(context);
              router.push('/event/new?kind=$kind&day=${d.day}&month=${d.month}');
            },
            child: Text('More options', style: TextStyle(color: context.c.muted)),
          ),
        ]),
      ),
    );
  }
}

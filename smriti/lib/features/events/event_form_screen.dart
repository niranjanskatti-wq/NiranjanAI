import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/occurrence.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import 'age_input.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen(
      {super.key, this.id, this.initialKind, this.personId, this.initialType, this.initialDay, this.initialMonth});

  final int? id;

  /// Pre-filled date, e.g. when adding from a day on the calendar.
  final int? initialDay, initialMonth;
  final String? initialKind;
  final int? personId;
  final String? initialType;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _title = TextEditingController();
  final _customLabel = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = true;
  EventKind _kind = EventKind.person;
  EventType _type = EventType.birthday;
  Repeat _repeat = Repeat.yearly;
  Feb29Rule _feb29 = Feb29Rule.feb28;
  DateParts? _date;
  int? _stars;
  final List<Person?> _people = [null, null];
  Person? _sendTo;
  bool _repeatTouched = false;
  bool _saving = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    if (_isEdit) {
      final entry = await repo.watchEntry(widget.id!).first;
      if (entry != null) {
        final e = entry.event;
        _kind = entry.kind;
        _type = entry.type;
        _repeat = entry.repeat;
        _feb29 = entry.feb29;
        // A birthday's year may be saved on the person (e.g. imported from contacts).
        final personBirthday = entry.type == EventType.birthday && entry.kind == EventKind.person;
        _date = DateParts(e.day, e.month, realYear(e.year) ?? (personBirthday ? realYear(entry.primary?.birthYear) : null));
        _stars = e.stars;
        _title.text = e.title ?? '';
        _customLabel.text = e.customLabel ?? '';
        _notes.text = e.notes ?? '';
        if (e.sendWishesToId != null) _sendTo = await repo.getPerson(e.sendWishesToId!);
        for (var i = 0; i < entry.people.length && i < 2; i++) {
          _people[i] = entry.people[i];
        }
        _repeatTouched = true;
      }
    } else {
      _kind = EventKind.parse(widget.initialKind);
      if (widget.initialDay != null && widget.initialMonth != null) {
        _date = DateParts(widget.initialDay!, widget.initialMonth!, null);
      }
      if (widget.personId != null) _people[0] = await repo.getPerson(widget.personId!);
      _type = switch (_kind) {
        EventKind.person => EventType.parse(widget.initialType ?? EventType.birthday.name),
        EventKind.couple => EventType.weddingAnniversary,
        EventKind.other || EventKind.festival => EventType.insurance,
      };
      if (_kind == EventKind.other) {
        _stars = 3;
        _applyDefaultRepeat();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Sensible repeat for each important-date category, until the user picks one.
  void _applyDefaultRepeat() {
    if (_repeatTouched) return;
    _repeat = switch (_type) {
      EventType.bill || EventType.rent || EventType.subscription => Repeat.monthly,
      EventType.passport || EventType.licence => Repeat.once,
      _ => Repeat.yearly,
    };
  }

  List<EventType> get _types => switch (_kind) {
        EventKind.person => EventType.personTypes,
        EventKind.couple => EventType.coupleTypes,
        EventKind.other || EventKind.festival => EventType.otherTypes,
      };

  Future<void> _pickSendTo() async {
    final people = await ref.read(repoProvider).watchPeople().first;
    if (!mounted) return;
    final chosen = await showModalBottomSheet<Object>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => _PersonPickerSheet(people: people, noneLabel: 'Nobody else (send to them)'),
    );
    if (chosen is Person) setState(() => _sendTo = chosen);
    if (chosen == 'none') setState(() => _sendTo = null);
    if (chosen == 'new' && mounted) await context.push('/person/new');
  }

  Future<void> _pickPerson(int slot) async {
    final people = await ref.read(repoProvider).watchPeople().first;
    final me = await ref.read(repoProvider).getMe();
    if (!mounted) return;
    final choices = [?me, ...people];
    final chosen = await showModalBottomSheet<Object>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => _PersonPickerSheet(people: choices),
    );
    if (chosen is Person) setState(() => _people[slot] = chosen);
    if (chosen == 'new' && mounted) {
      await context.push('/person/new');
    }
  }

  Future<void> _save() async {
    if (_date == null) return showToast(context, 'Please pick a date');
    if (_kind == EventKind.person && _people[0] == null) return showToast(context, 'Please choose a person');
    if (_kind == EventKind.couple && (_people[0] == null || _people[1] == null)) {
      return showToast(context, 'Please choose both people');
    }
    if (_kind == EventKind.couple && _people[0]!.id == _people[1]!.id) {
      return showToast(context, 'Please choose two different people');
    }
    if (_kind == EventKind.other && _title.text.trim().isEmpty) {
      return showToast(context, 'Please give it a title');
    }
    if (_repeat == Repeat.once && _date!.year == null) {
      return showToast(context, 'A one-time date needs a year');
    }
    setState(() => _saving = true);
    final d = _date!;
    final data = EventsCompanion(
      kind: Value(_kind.name),
      type: Value(_type.name),
      customLabel: Value(_type == EventType.custom && _customLabel.text.trim().isNotEmpty ? _customLabel.text.trim() : null),
      title: Value(_kind == EventKind.other ? _title.text.trim() : null),
      day: Value(d.day),
      month: Value(d.month),
      year: Value(d.year),
      repeat: Value(_repeat.name),
      feb29Rule: Value(_feb29.name),
      stars: Value(_stars),
      notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
      sendWishesToId: Value(_kind == EventKind.other ? null : _sendTo?.id),
    );
    final ids = switch (_kind) {
      EventKind.person => [_people[0]!.id],
      EventKind.couple => [_people[0]!.id, _people[1]!.id],
      EventKind.other || EventKind.festival => <int>[],
    };
    final id = await ref.read(repoProvider).saveEvent(id: widget.id, data: data, personIds: ids);
    if (_kind == EventKind.person && _type == EventType.birthday) {
      // Keep the person's birth year the same as this birthday's year.
      await ref.read(repoProvider).setBirthYear(ids.first, realYear(d.year));
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, 'Saved');
    if (_isEdit) {
      context.pop();
    } else {
      context.pushReplacement('/event/$id');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _customLabel.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _nameForAge() => _people[0]?.shortName ?? 'they';

  /// Works out the year from the age they turn (or years married) on the next date.
  Future<void> _enterAge() async {
    final d = _date;
    if (d == null) return;
    final today = Day.today();
    var on = resolveYearly(today.year, d.month, d.day, Feb29Rule.feb28);
    if (on < today) on = resolveYearly(today.year + 1, d.month, d.day, Feb29Rule.feb28);
    final years = await askYears(context,
        birthday: _type == EventType.birthday, name: _nameForAge(), on: on);
    if (years == null || !mounted) return;
    setState(() => _date = DateParts(d.day, d.month, yearFor(years, on)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold();
    final c = context.c;
    final heading = switch (_kind) {
      EventKind.person => _isEdit ? 'Edit event' : 'Add event',
      EventKind.couple => _isEdit ? 'Edit couple event' : 'Couple event',
      EventKind.other || EventKind.festival => _isEdit ? 'Edit important date' : 'Important date',
    };
    final isFeb29 = _date?.day == 29 && _date?.month == 2;

    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            if (_kind == EventKind.other) ...[
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Car insurance'),
              ),
              const SizedBox(height: 16),
            ] else ...[
              _personField(0, _kind == EventKind.couple ? 'First person' : 'Person'),
              if (_kind == EventKind.couple) ...[
                const SizedBox(height: 12),
                _personField(1, 'Second person'),
              ],
              const SizedBox(height: 16),
            ],
            const SectionLabel('What is it?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _types)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 18, color: t == _type ? c.bg : groupColor(t.group)),
                    label: Text(t.label),
                    selected: t == _type,
                    showCheckmark: false,
                    labelStyle: context.text.titleSmall?.copyWith(color: t == _type ? c.bg : c.text),
                    onSelected: (_) => setState(() {
                      _type = t;
                      if (_kind == EventKind.other) _applyDefaultRepeat();
                    }),
                  ),
              ],
            ),
            if (_type == EventType.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customLabel,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name of the occasion', hintText: 'e.g. Housewarming'),
              ),
            ],
            const SizedBox(height: 16),
            _tapField(
              label: _repeat == Repeat.monthly ? 'Start date (day of month repeats)' : 'Date',
              value: _date == null
                  ? 'Pick a date'
                  : fmtEventDate(day: _date!.day, month: _date!.month, year: _date!.year),
              onTap: () async {
                final d = await pickDate(context,
                    initial: _date, yearRequired: _repeat == Repeat.once, title: 'Date');
                if (d != null) setState(() => _date = d);
              },
            ),
            if (_date != null && _date!.year == null && _repeat != Repeat.once && _kind != EventKind.other)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      _type == EventType.birthday
                          ? 'Add the year to see "Turning 60!" and say it in wishes.'
                          : 'Add the year to see how many years it has been.',
                      style: context.text.bodySmall,
                    ),
                  ),
                  if (_type == EventType.birthday || _type.isAnniversaryLike)
                    TextButton(
                      onPressed: _enterAge,
                      child: Text(_type == EventType.birthday ? "Don't know? Enter age" : 'Enter years'),
                    ),
                ]),
              ),
            const SizedBox(height: 16),
            const SectionLabel('Repeats'),
            SegmentedButton<Repeat>(
              showSelectedIcon: false,
              segments: [for (final r in Repeat.values) ButtonSegment(value: r, label: Text(r.label))],
              selected: {_repeat},
              onSelectionChanged: (s) => setState(() {
                _repeat = s.first;
                _repeatTouched = true;
              }),
            ),
            if (_repeat == Repeat.monthly && (_date?.day ?? 0) > 28)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text('In shorter months it falls on the last day.', style: context.text.bodySmall),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Importance', style: context.text.titleMedium),
                  Text(
                    _stars == null ? 'Using the person\'s rating' : 'Only for sorting and filters',
                    style: context.text.bodySmall,
                  ),
                ]),
              ),
              Stars(value: _stars ?? _peopleStars, size: 26, onChanged: (v) => setState(() => _stars = v)),
            ]),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text('More options', style: context.text.titleMedium),
                initiallyExpanded: isFeb29 || _notes.text.isNotEmpty || _sendTo != null,
                subtitle: Text(_kind == EventKind.other ? 'Notes, 29 February' : 'Send wishes to, notes, 29 February',
                    style: context.text.bodySmall),
                children: [
                  if (_kind != EventKind.other) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(Radii.button),
                      onTap: _pickSendTo,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Send wishes to',
                          helperText: 'Call and Share use this person\'s number; the message still uses the event person\'s name.',
                          helperMaxLines: 3,
                          suffixIcon: _sendTo == null
                              ? const Icon(Icons.chevron_right_rounded)
                              : IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () => setState(() => _sendTo = null),
                                  icon: const Icon(Icons.close_rounded)),
                        ),
                        child: Text(
                          _sendTo == null ? 'Them directly' : '${_sendTo!.shortName} · ${_sendTo!.relationLabel}',
                          style: context.text.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isFeb29) ...[
                    const SectionLabel('In years without 29 February'),
                    SegmentedButton<Feb29Rule>(
                      showSelectedIcon: false,
                      segments: [for (final r in Feb29Rule.values) ButtonSegment(value: r, label: Text(r.label))],
                      selected: {_feb29},
                      onSelectionChanged: (s) => setState(() => _feb29 = s.first),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Notes', hintText: 'Policy number, venue, anything'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
        ),
      ),
    );
  }

  int get _peopleStars {
    final ps = _people.whereType<Person>().where((p) => !p.isMe).map((p) => p.stars);
    return ps.isEmpty ? 3 : ps.reduce((a, b) => a > b ? a : b);
  }

  Widget _personField(int slot, String label) {
    final p = _people[slot];
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.button),
      onTap: () => _pickPerson(slot),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.chevron_right_rounded)),
        child: p == null
            ? Text('Choose', style: context.text.bodyLarge?.copyWith(color: context.c.muted))
            : Row(children: [
                PersonAvatar(person: p, size: 26),
                const SizedBox(width: 10),
                Expanded(child: Text(p.isMe ? 'You' : '${p.shortName} · ${p.relationLabel}', style: context.text.bodyLarge)),
              ]),
      ),
    );
  }

  Widget _tapField({required String label, required String value, required VoidCallback onTap}) => InkWell(
        borderRadius: BorderRadius.circular(Radii.button),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)),
          child: Text(value, style: context.text.bodyLarge),
        ),
      );
}

class _PersonPickerSheet extends StatefulWidget {
  const _PersonPickerSheet({required this.people, this.noneLabel});

  final List<Person> people;
  final String? noneLabel;

  @override
  State<_PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends State<_PersonPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = widget.people
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || (p.nickname ?? '').toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search people'),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          if (widget.noneLabel != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(widget.noneLabel!),
              onTap: () => Navigator.pop(context, 'none'),
            ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_outlined),
            title: const Text('Add a new person first'),
            onTap: () => Navigator.pop(context, 'new'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                return ListTile(
                  leading: PersonAvatar(person: p, size: 38),
                  title: Text(p.isMe ? 'You' : p.shortName),
                  subtitle: Text(p.isMe ? p.name : p.relationLabel),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

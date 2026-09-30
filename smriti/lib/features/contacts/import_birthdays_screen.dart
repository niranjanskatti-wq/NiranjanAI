import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/format.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'contacts_helper.dart';
import 'duplicates.dart';

/// One date found in the phone's contacts.
class _Found {
  _Found(this.contact, this.type, this.day, this.month, this.year, {this.existing, this.duplicate = false})
      : selected = !duplicate;

  final PickedContact contact;
  final EventType type;
  final int day, month;
  final int? year;
  final Person? existing; // already in Smriti (add to them)
  final bool duplicate; // this exact date is already saved
  bool selected;

  /// Birthday and anniversary saved on the same day for this contact.
  bool sameDay = false;

  /// Why this is left out as a double (another contact with the same name
  /// or number), shown under the name.
  String? copyOf;
}

enum _SameDayChoice { birthday, anniversary, both }

/// Imports birthdays and anniversaries saved in contacts, skipping duplicates.
class ImportBirthdaysScreen extends ConsumerStatefulWidget {
  const ImportBirthdaysScreen({super.key});

  @override
  ConsumerState<ImportBirthdaysScreen> createState() => _ImportBirthdaysScreenState();
}

class _ImportBirthdaysScreenState extends ConsumerState<ImportBirthdaysScreen> {
  List<_Found>? _found;
  bool _denied = false, _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!await ContactsHelper.ensurePermission(context)) {
      setState(() => _denied = true);
      return;
    }
    final repo = ref.read(repoProvider);
    final people = await repo.allPeople();
    final entries = await repo.watchEntries().first;
    final contacts = await ContactsHelper.all();
    final found = <_Found>[];
    for (final c in contacts) {
      final existing = people.where((p) =>
          p.contactId == c.id ||
          c.numbers.any((n) => samePhone(n.number, p.callNumber)) ||
          nameKey(p.name) == nameKey(c.name)).firstOrNull;
      for (final (ev, type) in [(c.birthday, EventType.birthday), (c.anniversary, EventType.weddingAnniversary)]) {
        if (ev == null) continue;
        final dup = existing != null && await repo.hasEvent(existing.id, type, ev.month, ev.day);
        final f = _Found(c, type, ev.day, ev.month, ev.year, existing: existing, duplicate: dup);
        if (existing != null && !dup) {
          // One number, one birthday (and one anniversary): the person already has another date.
          final other = entries
              .where((e) => e.type == type && e.people.length == 1 && e.people.single.id == existing.id)
              .firstOrNull;
          if (other != null) {
            f.copyOf = '${existing.name} already has a ${type == EventType.birthday ? 'birthday' : 'wedding anniversary'} '
                'on ${fmtEventDate(day: other.event.day, month: other.event.month)}';
            f.selected = false;
          }
        }
        found.add(f);
      }
    }
    _markProblems(found);
    found.sort((a, b) => a.duplicate != b.duplicate ? (a.duplicate ? 1 : -1) : a.contact.name.compareTo(b.contact.name));
    if (!mounted) return;
    setState(() => _found = found);
    await _askAboutProblems(found);
  }

  /// Finds double contacts and same-day birthday/anniversary pairs.
  void _markProblems(List<_Found> found) {
    // Double contacts: the same name with the same date, or one number with a
    // second birthday (or anniversary) under another name.
    final seen = <String, _Found>{};
    for (final f in found.where((f) => !f.duplicate && f.copyOf == null)) {
      final keys = [
        'n:${nameKey(f.contact.name)}|${f.day}|${f.month}',
        for (final n in f.contact.numbers) 'p:${n.number}',
      ].map((k) => '$k|${f.type.name}');
      final first = keys.map((k) => seen[k]).whereType<_Found>().where((o) => o.contact.id != f.contact.id).firstOrNull;
      if (first != null) {
        f.copyOf = first.day == f.day && first.month == f.month
            ? 'Double contact of ${first.contact.name}'
            : 'Same number as ${first.contact.name}, who has a different date';
        f.selected = false;
      } else {
        for (final k in keys) {
          seen[k] = f;
        }
      }
    }
    // Birthday and anniversary on the same day for one contact.
    for (final b in found.where((f) => f.type == EventType.birthday)) {
      for (final a in found.where((f) =>
          f.contact.id == b.contact.id && f.type == EventType.weddingAnniversary && f.day == b.day && f.month == b.month)) {
        b.sameDay = true;
        a.sameDay = true;
      }
    }
  }

  Future<void> _askAboutProblems(List<_Found> found) async {
    final clashes = found.where((f) => f.sameDay && f.type == EventType.birthday && !f.duplicate).length;
    final copies = found.where((f) => f.copyOf != null).length;
    if (clashes == 0 && copies == 0) return;
    final choice = await showDialog<_SameDayChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Please check'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (copies > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                  '$copies ${copies == 1 ? 'date comes' : 'dates come'} from double contacts (same name or number). '
                  'The extra copies are left out. You can still tick one if it really is a different person.'),
            ),
          if (clashes > 0)
            Text('$clashes ${clashes == 1 ? 'contact has' : 'contacts have'} a birthday and a wedding anniversary on the '
                'same day. Usually one of them is a mistake. Which should be kept?'),
        ]),
        actions: clashes == 0
            ? [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]
            : [
                TextButton(onPressed: () => Navigator.pop(ctx, _SameDayChoice.both), child: const Text('Keep both')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, _SameDayChoice.anniversary), child: const Text('Anniversary only')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, _SameDayChoice.birthday), child: const Text('Birthday only')),
              ],
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      for (final f in found.where((f) => f.sameDay && !f.duplicate && f.copyOf == null)) {
        f.selected = switch (choice) {
          _SameDayChoice.both => true,
          _SameDayChoice.birthday => f.type == EventType.birthday,
          _SameDayChoice.anniversary => f.type == EventType.weddingAnniversary,
        };
      }
    });
  }

  Future<void> _import() async {
    setState(() => _saving = true);
    final repo = ref.read(repoProvider);
    final created = <String, int>{}; // contact id → new person id
    var count = 0;
    for (final f in _found!.where((f) => f.selected && !f.duplicate)) {
      var personId = f.existing?.id ?? created[f.contact.id] ?? created['n:${nameKey(f.contact.name)}'];
      if (personId == null) {
        final full = await ContactsHelper.get(f.contact.id, withPhoto: true);
        final photo = full?.photo ?? f.contact.photo;
        personId = await repo.insertPerson(PeopleCompanion.insert(
          name: f.contact.name,
          callNumber: Value(f.contact.numbers.firstOrNull?.number),
          contactId: Value(f.contact.id),
          contactLookupKey: Value(f.contact.lookupKey),
          photoPath: Value(photo == null ? null : await savePhotoBytes(photo)),
          birthYear: Value(f.type == EventType.birthday ? realYear(f.year) : null),
        ));
        created[f.contact.id] = personId;
        created['n:${nameKey(f.contact.name)}'] = personId;
      }
      await repo.saveEvent(
        data: EventsCompanion.insert(
          kind: EventKind.person.name,
          type: f.type.name,
          day: f.day,
          month: f.month,
          year: Value(f.type == EventType.birthday ? null : realYear(f.year)),
        ),
        personIds: [personId],
      );
      count++;
    }
    final cleaned = await Duplicates.cleanSafely(ref.read(databaseProvider));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context,
        'Imported $count date${count == 1 ? '' : 's'}${cleaned > 0 ? ' · removed $cleaned double${cleaned == 1 ? '' : 's'}' : ''}');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final found = _found;
    final toImport = found?.where((f) => f.selected && !f.duplicate).length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Import birthdays')),
      body: _denied
          ? const Center(
              child: EmptyState(
                title: 'Contacts not allowed',
                message: 'Allow contacts for Smriti in your phone settings to import birthdays.',
              ),
            )
          : found == null
              ? const Center(child: CircularProgressIndicator())
              : found.isEmpty
                  ? const Center(
                      child: EmptyState(
                        title: 'No dates in your contacts',
                        message: 'None of your phone contacts have a birthday or anniversary saved.',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: found.length,
                      itemBuilder: (_, i) {
                        final f = found[i];
                        final date = fmtEventDate(day: f.day, month: f.month, year: realYear(f.year));
                        final note = f.duplicate
                            ? 'Already saved in Smriti'
                            : f.copyOf != null
                                ? f.copyOf!
                                : f.existing != null
                                    ? 'Will be added to ${f.existing!.name}'
                                    : 'New person';
                        final warn = f.copyOf != null || (f.sameDay && !f.duplicate);
                        return CheckboxListTile(
                          value: f.duplicate ? false : f.selected,
                          onChanged: f.duplicate ? null : (v) => setState(() => f.selected = v ?? false),
                          title: Text(f.contact.name),
                          secondary: warn ? Icon(Icons.warning_amber_rounded, color: context.c.alert) : null,
                          subtitle: Text([
                            '${f.type.label} · $date · $note',
                            if (f.sameDay && !f.duplicate) 'Birthday and anniversary on the same day',
                          ].join('\n')),
                        );
                      },
                    ),
      bottomNavigationBar: found == null || found.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: toImport == 0 || _saving ? null : _import,
                  child: Text(toImport == 0 ? 'Nothing new to import' : 'Import $toImport date${toImport == 1 ? '' : 's'}'),
                ),
              ),
            ),
    );
  }
}

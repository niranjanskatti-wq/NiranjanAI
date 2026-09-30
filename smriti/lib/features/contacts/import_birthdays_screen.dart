import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/occurrence.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'contacts_helper.dart';

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
}

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
    final contacts = await ContactsHelper.all();
    final found = <_Found>[];
    for (final c in contacts) {
      final numbers = c.numbers.map((n) => n.number).toSet();
      final existing = people.where((p) =>
          p.contactId == c.id ||
          (p.callNumber != null && numbers.contains(p.callNumber)) ||
          p.name.trim().toLowerCase() == c.name.trim().toLowerCase()).firstOrNull;
      for (final (ev, type) in [(c.birthday, EventType.birthday), (c.anniversary, EventType.weddingAnniversary)]) {
        if (ev == null) continue;
        final dup = existing != null && await repo.hasEvent(existing.id, type, ev.month, ev.day);
        found.add(_Found(c, type, ev.day, ev.month, ev.year, existing: existing, duplicate: dup));
      }
    }
    found.sort((a, b) => a.duplicate != b.duplicate ? (a.duplicate ? 1 : -1) : a.contact.name.compareTo(b.contact.name));
    if (mounted) setState(() => _found = found);
  }

  Future<void> _import() async {
    setState(() => _saving = true);
    final repo = ref.read(repoProvider);
    final created = <String, int>{}; // contact id → new person id
    var count = 0;
    for (final f in _found!.where((f) => f.selected && !f.duplicate)) {
      var personId = f.existing?.id ?? created[f.contact.id];
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
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, 'Imported $count date${count == 1 ? '' : 's'}');
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
                            : f.existing != null
                                ? 'Will be added to ${f.existing!.name}'
                                : 'New person';
                        return CheckboxListTile(
                          value: f.duplicate ? false : f.selected,
                          onChanged: f.duplicate ? null : (v) => setState(() => f.selected = v ?? false),
                          title: Text(f.contact.name),
                          subtitle: Text('${f.type.label} · $date · $note'),
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

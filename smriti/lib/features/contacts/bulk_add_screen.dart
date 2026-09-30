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
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import 'contacts_helper.dart';

/// Tick many contacts, then add their relationship and birthday in one list.
class BulkAddScreen extends ConsumerStatefulWidget {
  const BulkAddScreen({super.key});

  @override
  ConsumerState<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _Draft {
  _Draft(this.contact)
      : birthday = contact.birthday == null
            ? null
            : DateParts(contact.birthday!.day, contact.birthday!.month, contact.birthday!.year);

  final PickedContact contact;
  Relationship relation = Relationship.friend;
  DateParts? birthday;
}

class _BulkAddScreenState extends ConsumerState<BulkAddScreen> {
  List<PickedContact>? _contacts;
  Set<String> _linked = {};
  final _selected = <String>{};
  String _q = '';
  List<_Draft>? _drafts; // step 2 when not null
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
    final people = await ref.read(repoProvider).allPeople();
    final list = await ContactsHelper.all();
    if (!mounted) return;
    setState(() {
      _linked = people.map((p) => p.contactId).whereType<String>().toSet();
      _contacts = list;
    });
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    final repo = ref.read(repoProvider);
    for (final d in _drafts!) {
      final c = d.contact;
      final photo = c.photo == null ? null : await savePhotoBytes(c.photo!);
      final id = await repo.insertPerson(PeopleCompanion.insert(
        name: c.name,
        relationship: Value(d.relation.name),
        callNumber: Value(c.numbers.firstOrNull?.number),
        contactId: Value(c.id),
        contactLookupKey: Value(c.lookupKey),
        photoPath: Value(photo),
        birthYear: Value(realYear(d.birthday?.year)),
      ));
      if (d.birthday != null) {
        await repo.saveEvent(
          data: EventsCompanion.insert(
            kind: EventKind.person.name,
            type: EventType.birthday.name,
            day: d.birthday!.day,
            month: d.birthday!.month,
          ),
          personIds: [id],
        );
      }
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showToast(context, 'Added ${_drafts!.length} people');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_drafts != null) return _step2(context);
    final c = context.c;
    final contacts = _contacts;
    return Scaffold(
      appBar: AppBar(title: const Text('Add from contacts')),
      body: _denied
          ? const Center(
              child: EmptyState(
                title: 'Contacts not allowed',
                message: 'Allow contacts for Smriti in your phone settings to add many people at once.',
              ),
            )
          : contacts == null
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search contacts'),
                      onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: Builder(builder: (context) {
                      final list = contacts.where((x) => _q.isEmpty || x.name.toLowerCase().contains(_q)).toList();
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final x = list[i];
                          final added = _linked.contains(x.id);
                          return CheckboxListTile(
                            value: added || _selected.contains(x.id),
                            onChanged: added
                                ? null
                                : (v) => setState(() => v! ? _selected.add(x.id) : _selected.remove(x.id)),
                            secondary: CircleAvatar(
                              backgroundColor: c.raised,
                              foregroundImage: x.photo == null ? null : MemoryImage(x.photo!),
                              child: Text(x.name.isEmpty ? '?' : String.fromCharCode(x.name.runes.first),
                                  style: TextStyle(color: c.text)),
                            ),
                            title: Text(x.name),
                            subtitle: Text(added
                                ? 'Already in Smriti'
                                : [
                                    if (x.numbers.isNotEmpty) '${x.numbers.length} number${x.numbers.length > 1 ? 's' : ''}',
                                    if (x.birthday != null) 'Birthday saved',
                                  ].join(' · ')),
                          );
                        },
                      );
                    }),
                  ),
                ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => setState(() {
                      _drafts = [
                        for (final x in contacts!)
                          if (_selected.contains(x.id)) _Draft(x),
                      ];
                    }),
            child: Text(_selected.isEmpty ? 'Tick people to add' : 'Next: add dates (${_selected.length})'),
          ),
        ),
      ),
    );
  }

  Widget _step2(BuildContext context) {
    final drafts = _drafts!;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => setState(() => _drafts = null)),
        title: const Text('Add their dates'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: drafts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Text('Birthdays already saved in contacts are filled in. Anything left empty can be added later.',
                style: context.text.bodySmall);
          }
          final d = drafts[i - 1];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.contact.name, style: context.text.titleLarge),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ActionChip(
                    avatar: const Icon(Icons.people_outline, size: 18),
                    label: Text(d.relation.label),
                    onPressed: () async {
                      final r = await pickRelationship(context, d.relation);
                      if (r != null) setState(() => d.relation = r);
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.cake_outlined, size: 18, color: context.c.goldText),
                    label: Text(d.birthday == null
                        ? 'Add birthday'
                        : fmtEventDate(day: d.birthday!.day, month: d.birthday!.month, year: realYear(d.birthday!.year))),
                    onPressed: () async {
                      final b = await pickDate(context, initial: d.birthday, title: '${d.contact.name}\'s birthday');
                      if (b != null) setState(() => d.birthday = b);
                    },
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _saveAll,
            child: Text('Save ${drafts.length} ${drafts.length == 1 ? 'person' : 'people'}'),
          ),
        ),
      ),
    );
  }
}

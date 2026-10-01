import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../family/family.dart';
import 'duplicates.dart';

/// Finds birthdays and anniversaries on the same day, and people saved twice,
/// and lets you fix each one.
class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
    final people = ref.watch(peopleProvider).value ?? const <Person>[];
    final clashes = Duplicates.sameDay(entries);
    final doubles = Duplicates.people(people, entries);
    final couples = ref.watch(coupleSuggestionsProvider);
    final sameDate = ref.watch(sameDateGroupsProvider);
    final repo = ref.read(repoProvider);

    Future<void> remove(EventEntry e, String what) async {
      await repo.deleteEvent(e.event.id);
      HapticFeedback.lightImpact();
      if (context.mounted) showToast(context, '$what removed');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Check for duplicates')),
      body: clashes.isEmpty && doubles.isEmpty && couples.isEmpty && sameDate.isEmpty
          ? const Center(
              child: EmptyState(
                title: 'All clear',
                message: 'No one is saved twice, and no birthday and anniversary fall on the same day.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              children: [
                if (sameDate.isNotEmpty) ...[
                  const SectionLabel('Same date: same person?'),
                  Text('Often one person was saved twice with different names. Merging keeps the one with the '
                      'phone number (tap a name to keep that one instead), with all dates, gifts and wishes.',
                      style: context.text.bodySmall),
                  const SizedBox(height: 8),
                  for (final g in sameDate) _SameDateCard(group: g, entries: entries),
                ],
                if (couples.isNotEmpty) ...[
                  const SectionLabel('Anniversaries that could be one couple'),
                  Text('One anniversary for both means one reminder and one card, like "Mom & Dad · 35 years".',
                      style: context.text.bodySmall),
                  const SizedBox(height: 8),
                  for (final x in couples)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [
                            SizedBox(width: 52, height: 40, child: Stack(children: [
                              PersonAvatar(person: x.first, size: 34),
                              Positioned(left: 18, top: 6, child: PersonAvatar(person: x.second, size: 34)),
                            ])),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${x.first.shortName} & ${x.second.shortName}', style: context.text.titleMedium),
                                Text(
                                    '${fmtEventDate(day: x.firstEvent.event.day, month: x.firstEvent.event.month)} · ${x.reason}',
                                    style: context.text.bodySmall),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            FilledButton.tonal(
                              onPressed: () async {
                                await Duplicates(ref.read(databaseProvider)).combine(x);
                                HapticFeedback.lightImpact();
                                if (context.mounted) {
                                  showToast(context, 'Now one anniversary: ${x.first.shortName} & ${x.second.shortName}');
                                }
                              },
                              child: const Text('Make one couple anniversary'),
                            ),
                            FilledButton.tonal(
                              onPressed: () async {
                                final keepFirst = x.first.callNumber != null || x.second.callNumber == null;
                                final keep = keepFirst ? x.first : x.second, extra = keepFirst ? x.second : x.first;
                                await Duplicates(ref.read(databaseProvider)).merge(keep, extra);
                                HapticFeedback.lightImpact();
                                if (context.mounted) showToast(context, 'Merged into ${keep.name}');
                              },
                              child: const Text('Same person: merge'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final db = ref.read(databaseProvider);
                                final skips = {...?(await db.getSetting('coupleSkips'))?.split(','), coupleKey(x)};
                                await db.setSetting('coupleSkips', skips.where((k) => k.isNotEmpty).join(','));
                              },
                              child: const Text('Not a couple'),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                ],
                if (clashes.isNotEmpty) ...[
                  const SectionLabel('Birthday and anniversary on the same day'),
                  Text('Usually one of them was saved by mistake in contacts. Keep the right one.',
                      style: context.text.bodySmall),
                  const SizedBox(height: 8),
                  for (final x in clashes)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [
                            PersonAvatar(person: x.person, size: 38),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(x.person.name, style: context.text.titleMedium),
                                Text(
                                    'Birthday and ${x.anniversary.typeLabel.toLowerCase()} both on '
                                    '${fmtEventDate(day: x.birthday.event.day, month: x.birthday.event.month)}',
                                    style: context.text.bodySmall),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            FilledButton.tonal(
                              onPressed: () => remove(x.anniversary, 'Anniversary'),
                              child: const Text('Keep birthday'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => remove(x.birthday, 'Birthday'),
                              child: const Text('Keep anniversary'),
                            ),
                            TextButton(
                              onPressed: () => context.push('/person/${x.person.id}'),
                              child: const Text('Open'),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                ],
                if (doubles.isNotEmpty) ...[
                  const SectionLabel('Saved twice'),
                  Text('Merging keeps one person with all their dates, gift ideas and wish history.',
                      style: context.text.bodySmall),
                  const SizedBox(height: 8),
                  for (final d in doubles)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text(d.reason, style: context.text.labelMedium?.copyWith(color: c.alert)),
                          const SizedBox(height: 6),
                          for (final p in [d.keep, d.extra])
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: PersonAvatar(person: p, size: 34),
                              title: Text(p.name),
                              subtitle: Text(_summary(p, entries)),
                              onTap: () => context.push('/person/${p.id}'),
                            ),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            FilledButton.tonal(
                              onPressed: () async {
                                await Duplicates(ref.read(databaseProvider)).merge(d.keep, d.extra);
                                HapticFeedback.lightImpact();
                                if (context.mounted) showToast(context, 'Merged into ${d.keep.name}');
                              },
                              child: const Text('Merge into one'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final ok = await confirm(context,
                                    title: 'Remove the second ${d.extra.name}?',
                                    message: 'Their dates that are not on the first one are deleted too.',
                                    action: 'Remove',
                                    danger: true);
                                if (ok) await repo.deletePerson(d.extra.id);
                              },
                              child: const Text('Remove the second'),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  static String _summary(Person p, List<EventEntry> entries) {
    final mine = entries.where((e) => e.people.any((x) => x.id == p.id)).toList();
    final dates = mine.map((e) => '${e.shortLabel} ${fmtEventDate(day: e.event.day, month: e.event.month)}').join(', ');
    return [if (p.callNumber != null) p.callNumber!, if (dates.isNotEmpty) dates else 'No dates'].join(' · ');
  }
}

/// Remembers "Not a couple" answers.
String coupleKey(CoupleSuggestion x) => '${x.firstEvent.event.id}-${x.second.id}';

final coupleSuggestionsProvider = Provider<List<CoupleSuggestion>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
  final skips = (ref.watch(_coupleSkipsProvider).value ?? '').split(',').toSet();
  return Duplicates.couples(entries, ref.watch(spouseMapProvider)).where((x) => !skips.contains(coupleKey(x))).toList();
});

final _coupleSkipsProvider =
    StreamProvider<String?>((ref) => ref.watch(databaseProvider).watchSetting('coupleSkips'));

final _sameDateSkipsProvider =
    StreamProvider<String?>((ref) => ref.watch(databaseProvider).watchSetting('sameDateSkips'));

/// People sharing a birthday (or other date) on the same day, minus "Different people" answers.
final sameDateGroupsProvider = Provider<List<SameDateGroup>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
  final people = ref.watch(peopleProvider).value ?? const <Person>[];
  final skips = (ref.watch(_sameDateSkipsProvider).value ?? '').split(',').where((k) => k.isNotEmpty).toSet();
  return Duplicates.sameDate(people, entries, skip: skips);
});

class _SameDateCard extends ConsumerStatefulWidget {
  const _SameDateCard({required this.group, required this.entries});
  final SameDateGroup group;
  final List<EventEntry> entries;

  @override
  ConsumerState<_SameDateCard> createState() => _SameDateCardState();
}

class _SameDateCardState extends ConsumerState<_SameDateCard> {
  int? _keepId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final g = widget.group;
    final keep = g.all.firstWhere((p) => p.id == _keepId, orElse: () => g.keep);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${g.all.length} ${g.type.label.toLowerCase()}s on ${fmtEventDate(day: g.day, month: g.month)}',
              style: context.text.labelMedium?.copyWith(color: c.alert)),
          const SizedBox(height: 6),
          for (final p in g.all)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: PersonAvatar(person: p, size: 34),
              title: Text(p.name),
              subtitle: Text(DuplicatesScreen._summary(p, widget.entries)),
              trailing: p.id == keep.id
                  ? Chip(label: const Text('Keep'), avatar: Icon(Icons.check_rounded, size: 16, color: c.call))
                  : null,
              onTap: () => setState(() => _keepId = p.id),
            ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonal(
              onPressed: () async {
                final merged = SameDateGroup(g.type, g.day, g.month, keep, [for (final p in g.all) if (p.id != keep.id) p]);
                await Duplicates(ref.read(databaseProvider)).mergeGroup(merged);
                HapticFeedback.lightImpact();
                if (context.mounted) showToast(context, 'Merged into ${keep.name}');
              },
              child: Text('Same person: keep ${keep.shortName}'),
            ),
            TextButton(
              onPressed: () async {
                final db = ref.read(databaseProvider);
                final skips = {...?(await db.getSetting('sameDateSkips'))?.split(','), g.key};
                await db.setSetting('sameDateSkips', skips.where((k) => k.isNotEmpty).join(','));
              },
              child: const Text('Different people'),
            ),
          ]),
        ]),
      ),
    );
  }
}

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
    final repo = ref.read(repoProvider);

    Future<void> remove(EventEntry e, String what) async {
      await repo.deleteEvent(e.event.id);
      HapticFeedback.lightImpact();
      if (context.mounted) showToast(context, '$what removed');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Check for duplicates')),
      body: clashes.isEmpty && doubles.isEmpty
          ? const Center(
              child: EmptyState(
                title: 'All clear',
                message: 'No one is saved twice, and no birthday and anniversary fall on the same day.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              children: [
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

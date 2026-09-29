import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final entry = ref.watch(entryProvider(id));
    final today = ref.watch(todayProvider).value ?? Day.today();
    return entry.when(
      loading: () => const Scaffold(),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (e) {
        if (e == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('This event was deleted.')));
        final next = e.nextFrom(today);
        final item = next == null ? null : Upcoming(e, next, today.daysUntil(next));
        final ev = e.event;
        return Scaffold(
          appBar: AppBar(
            actions: [
              TextButton(onPressed: () => context.push('/event/$id/edit'), child: const Text('Edit')),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete_outline, color: c.alert),
                onPressed: () async {
                  final ok = await confirm(context,
                      title: 'Delete this event?',
                      message: '${e.typeLabel} for ${e.title} will be removed.',
                      action: 'Delete',
                      danger: true);
                  if (!ok) return;
                  await ref.read(repoProvider).deleteEvent(id);
                  if (context.mounted) {
                    context.pop();
                    showToast(context, 'Deleted');
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              children: [
                Center(child: EventAvatar(entry: e, size: 96, ring: true)),
                const SizedBox(height: 12),
                Text(e.title, textAlign: TextAlign.center, style: context.text.displayMedium),
                const SizedBox(height: 4),
                Text(
                  [if (e.kind != EventKind.other) e.relationLine, e.typeLabel].join(' · '),
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: 6),
                Center(child: Stars(value: e.stars, size: 18)),
                const SizedBox(height: 20),
                if (item == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('This one-time date has passed.',
                          textAlign: TextAlign.center, style: context.text.titleMedium),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text(fmtWeekday(item.date), style: context.text.headlineMedium),
                        if (item.yearsPhrase != null) ...[
                          const SizedBox(height: 6),
                          Badge2(item.milestone ? '${item.yearsPhrase}!' : item.yearsPhrase!, sparkle: item.milestone),
                        ],
                        const SizedBox(height: 14),
                        if (item.isToday)
                          Text('Today!', style: context.text.headlineLarge?.copyWith(color: c.goldText))
                        else
                          Countdown(target: item.date),
                        const SizedBox(height: 8),
                        Text(relativeDays(item.daysLeft), style: context.text.bodySmall),
                      ]),
                    ),
                  ),
                const SizedBox(height: 12),
                InfoCard(title: 'Details', children: [
                  _kv(context, 'Date', fmtEventDate(day: ev.day, month: ev.month, year: ev.year, monthly: e.repeat == Repeat.monthly)),
                  _kv(context, 'Repeats', e.repeat.label),
                  if (ev.day == 29 && ev.month == 2) _kv(context, 'Non-leap years', e.feb29.label),
                  if (ev.notes != null) ...[
                    const SizedBox(height: 6),
                    Text('Notes', style: context.text.bodySmall),
                    Text(ev.notes!, style: context.text.bodyMedium),
                  ],
                ]),
                if (e.people.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InfoCard(title: e.people.length > 1 ? 'People' : 'Person', children: [
                    for (final p in e.people)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: PersonAvatar(person: p, size: 40),
                        title: Text(p.isMe ? 'You' : p.shortName),
                        subtitle: Text(p.isMe ? p.name : p.relationLabel),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/person/${p.id}'),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(k, style: context.text.bodyMedium?.copyWith(color: context.c.muted))),
          Text(v, style: context.text.titleSmall),
        ]),
      );
}

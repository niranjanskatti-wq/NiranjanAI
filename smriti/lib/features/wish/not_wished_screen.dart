import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'share_sheet.dart';
import 'wish_service.dart';

/// People with no confirmed wish in the last 12 months, most important first.
class NotWishedScreen extends ConsumerWidget {
  const NotWishedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).value ?? const <Person>[];
    final logs = ref.watch(wishLogsProvider).value ?? const <WishLog>[];
    final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
    final cutoff = DateTime.now().subtract(const Duration(days: 365));

    // Latest confirmed wish per person, counting wishes for their events too.
    final last = <int, DateTime>{};
    for (final l in logs.where((l) => l.confirmed)) {
      final ids = {
        ?l.personId,
        for (final e in entries.where((e) => e.event.id == l.eventId)) ...e.people.map((p) => p.id),
      };
      for (final id in ids) {
        if (last[id] == null || l.createdAt.isAfter(last[id]!)) last[id] = l.createdAt;
      }
    }
    final list = people.where((p) => last[p.id] == null || last[p.id]!.isBefore(cutoff)).toList()
      ..sort((a, b) => b.stars != a.stars ? b.stars.compareTo(a.stars) : a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Not wished in 12+ months')),
      body: list.isEmpty
          ? const Center(
              child: EmptyState(title: 'All caught up', message: 'You have wished everyone in the last year.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                final l = last[p.id];
                return ListTile(
                  leading: PersonAvatar(person: p, size: 42),
                  title: Text(p.shortName),
                  subtitle: Row(children: [
                    Stars(value: p.stars, size: 11),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(l == null ? 'Never wished from Smriti' : 'Last: ${fmtFull(Day.of(l))}',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: 'Call',
                      onPressed: () => callTarget(context, ref, _target(p)),
                      icon: Icon(Icons.call_rounded, color: context.c.call),
                    ),
                    IconButton(
                      tooltip: 'Share',
                      onPressed: () => showShareSheet(context, ref, _target(p)),
                      icon: Icon(Icons.send_rounded, color: context.c.goldText),
                    ),
                  ]),
                  onTap: () => context.push('/person/${p.id}'),
                );
              },
            ),
    );
  }
}

WishTarget _target(Person p) => WishTarget(date: Day.today(), recipients: [p], about: p);

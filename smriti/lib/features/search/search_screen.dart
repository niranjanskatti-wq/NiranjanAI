import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/occurrence.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/event_row.dart';
import '../festivals/festival_model.dart';

/// Search people by name, nickname or relationship, and events by title or type.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider).value ?? const [];
    final entries = ref.watch(allEntriesProvider);
    final today = ref.watch(todayProvider).value ?? Day.today();
    final q = _q.toLowerCase();

    final matchedPeople = q.isEmpty
        ? const []
        : people
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                (p.nickname ?? '').toLowerCase().contains(q) ||
                p.relationLabel.toLowerCase().contains(q))
            .toList();
    final matchedEvents = q.isEmpty
        ? const <Upcoming>[]
        : computeUpcoming(
            entries.where((e) =>
                e.title.toLowerCase().contains(q) ||
                e.typeLabel.toLowerCase().contains(q) ||
                (e.event.notes ?? '').toLowerCase().contains(q)),
            today);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(hintText: 'Name, relationship or event', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
      ),
      body: q.isEmpty
          ? Center(
              child: Text('Try "Appa", "Sister" or "insurance"',
                  style: context.text.bodyMedium?.copyWith(color: context.c.muted)),
            )
          : (matchedPeople.isEmpty && matchedEvents.isEmpty)
              ? Center(child: Text('No matches for "$_q"', style: context.text.bodyMedium))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    if (matchedPeople.isNotEmpty) ...[
                      const SectionLabel('People'),
                      for (final p in matchedPeople)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: PersonAvatar(person: p, size: 40),
                          title: Text(p.shortName),
                          subtitle: Text(p.relationLabel),
                          onTap: () => context.push('/person/${p.id}'),
                        ),
                    ],
                    if (matchedEvents.isNotEmpty) ...[
                      const SectionLabel('Events'),
                      for (final u in matchedEvents)
                        Padding(padding: const EdgeInsets.only(bottom: 8), child: UpcomingRow(item: u)),
                    ],
                  ],
                ),
    );
  }
}

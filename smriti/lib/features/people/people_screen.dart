import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/add_sheet.dart';
import '../../widgets/common.dart';

enum PeopleSort { name, stars, next }

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  PeopleSort _sort = PeopleSort.name;
  Relationship? _relation;
  int _minStars = 0;
  int? _group;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final people = ref.watch(peopleProvider);
    final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
    final today = ref.watch(todayProvider).value ?? Day.today();
    final groups = ref.watch(groupsProvider).value ?? const <PersonGroup>[];
    final members = ref.watch(groupMembersProvider).value ?? const <int, Set<int>>{};
    if (_group != null && !groups.any((g) => g.id == _group)) _group = null;

    // Next date per person, for sorting and the subtitle.
    final next = <int, Upcoming>{};
    for (final u in computeUpcoming(entries, today)) {
      for (final p in u.entry.people) {
        next.putIfAbsent(p.id, () => u);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(tooltip: 'Search', onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) => context.push(v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/import/contacts', child: Text('Add many from contacts')),
              PopupMenuItem(value: '/import/birthdays', child: Text('Import birthdays from contacts')),
              PopupMenuItem(value: '/import/calendar', child: Text('Import from Google Calendar')),
              PopupMenuItem(value: '/groups', child: Text('Groups')),
              PopupMenuItem(value: '/gifts', child: Text('Gift planner')),
              PopupMenuItem(value: '/not-wished', child: Text('Not wished in 12+ months')),
              PopupMenuItem(value: '/archived', child: Text('Archived people')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add',
        onPressed: () => showAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: people.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          if (all.isEmpty) {
            return Center(
              child: EmptyState(
                title: 'Your people live here',
                message: 'Add family and friends one by one, or pick many from your contacts at once.',
                actionLabel: 'Add many from contacts',
                onAction: () => context.push('/import/contacts'),
                secondaryLabel: 'Add one person',
                onSecondary: () => showAddSheet(context),
              ),
            );
          }
          var list = all
              .where((p) =>
                  (_relation == null || p.relation == _relation) &&
                  p.stars >= _minStars &&
                  (_group == null || (members[_group] ?? const {}).contains(p.id)))
              .toList();
          switch (_sort) {
            case PeopleSort.name:
              break;
            case PeopleSort.stars:
              list.sort((a, b) => b.stars != a.stars ? b.stars.compareTo(a.stars) : a.name.compareTo(b.name));
            case PeopleSort.next:
              list.sort((a, b) {
                final da = next[a.id]?.daysLeft ?? 99999, db = next[b.id]?.daysLeft ?? 99999;
                return da.compareTo(db);
              });
          }
          return Column(children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _menuChip<PeopleSort>(
                    icon: Icons.sort_rounded,
                    label: switch (_sort) {
                      PeopleSort.name => 'A–Z',
                      PeopleSort.stars => 'Most important',
                      PeopleSort.next => 'Next date',
                    },
                    items: {PeopleSort.name: 'A–Z', PeopleSort.stars: 'Most important', PeopleSort.next: 'Next date'},
                    onSelected: (v) => setState(() => _sort = v),
                  ),
                  const SizedBox(width: 6),
                  _menuChip<Relationship?>(
                    icon: Icons.people_outline,
                    label: _relation?.label ?? 'All relationships',
                    active: _relation != null,
                    items: {null: 'All relationships', for (final r in Relationship.choices) r: r.label},
                    onSelected: (v) => setState(() => _relation = v),
                  ),
                  const SizedBox(width: 6),
                  _menuChip<int>(
                    icon: Icons.star_outline_rounded,
                    label: _minStars == 0 ? 'Any stars' : '$_minStars★ and up',
                    active: _minStars > 0,
                    items: {0: 'Any stars', for (var i = 5; i >= 1; i--) i: '$i★ and up'},
                    onSelected: (v) => setState(() => _minStars = v),
                  ),
                  const SizedBox(width: 6),
                  _menuChip<int?>(
                    icon: Icons.workspaces_outline,
                    label: _group == null ? 'All groups' : groups.firstWhere((g) => g.id == _group).name,
                    active: _group != null,
                    items: {null: 'All groups', for (final g in groups) g.id: g.name, -1: 'Manage groups…'},
                    onSelected: (v) => v == -1 ? context.push('/groups') : setState(() => _group = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('No one matches these filters.', style: TextStyle(color: c.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _PersonRow(person: list[i], next: next[list[i].id]),
                    ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _menuChip<T>({
    required IconData icon,
    required String label,
    required Map<T, String> items,
    required ValueChanged<T> onSelected,
    bool active = false,
  }) {
    final c = context.c;
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (_) => [for (final e in items.entries) PopupMenuItem(value: e.key, child: Text(e.value))],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.text : c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? c.text : c.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: active ? c.bg : c.muted),
          const SizedBox(width: 6),
          Text(label, style: context.text.titleSmall?.copyWith(color: active ? c.bg : c.text)),
          Icon(Icons.arrow_drop_down_rounded, size: 18, color: active ? c.bg : c.muted),
        ]),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, this.next});

  final Person person;
  final Upcoming? next;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final n = next;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/person/${person.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(children: [
            PersonAvatar(person: person, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(person.shortName, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [
                    person.relationLabel,
                    if (n != null) '${n.entry.typeLabel} ${fmtDayMonth(n.date)}',
                  ].join(' · '),
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Stars(value: person.stars, size: 11),
              ]),
            ),
            if (n != null)
              Text(relativeDays(n.daysLeft), style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

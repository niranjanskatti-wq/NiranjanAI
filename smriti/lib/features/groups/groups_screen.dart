import 'package:drift/drift.dart' show Value;
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

const groupColors = [
  Color(0xFFC9A45C), Color(0xFF5E86B8), Color(0xFF4F9A6E), Color(0xFFC0605E),
  Color(0xFF8C6BB8), Color(0xFFD08A3C), Color(0xFF3F9AA5), Color(0xFFB0587F),
];

Color teamColor(PersonGroup g) => groupColors[g.color % groupColors.length];

/// Asks for a group name. Returns null when cancelled.
Future<String?> askGroupName(BuildContext context, {String initial = '', String title = 'New group'}) {
  final t = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: t,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Family, Office, College friends'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, t.text.trim()), child: const Text('Save')),
      ],
    ),
  ).then((v) => v == null || v.isEmpty ? null : v);
}

/// Tick several people. Returns the chosen ids, or null when cancelled.
Future<Set<int>?> pickPeople(BuildContext context, List<Person> people, Set<int> selected, {String title = 'Choose people'}) {
  final chosen = {...selected};
  var query = '';
  return showModalBottomSheet<Set<int>>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final list = people.where((p) => p.name.toLowerCase().contains(query) || (p.nickname ?? '').toLowerCase().contains(query)).toList();
        return SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.85,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(children: [
                Expanded(child: Text(title, style: ctx.text.titleLarge)),
                TextButton(onPressed: () => Navigator.pop(ctx, chosen), child: Text('Done (${chosen.length})')),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
                onChanged: (v) => set(() => query = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return CheckboxListTile(
                    value: chosen.contains(p.id),
                    onChanged: (v) => set(() => v! ? chosen.add(p.id) : chosen.remove(p.id)),
                    secondary: PersonAvatar(person: p, size: 36),
                    title: Text(p.name),
                    subtitle: Text(p.relationLabel),
                  );
                },
              ),
            ),
          ]),
        );
      },
    ),
  );
}

/// Makes a group and lets you pick its people straight away.
Future<void> createGroup(BuildContext context, WidgetRef ref) async {
  final name = await askGroupName(context);
  if (name == null || !context.mounted) return;
  final repo = ref.read(repoProvider);
  final count = (ref.read(groupsProvider).value ?? const []).length;
  final id = await repo.addGroup(name, color: count % groupColors.length);
  if (!context.mounted) return;
  final people = ref.read(peopleProvider).value ?? const <Person>[];
  final chosen = await pickPeople(context, people.where((p) => !p.isMe).toList(), const {}, title: 'Who is in $name?');
  if (chosen != null) await repo.setGroupMembers(id, chosen);
}

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final groups = ref.watch(groupsProvider).value ?? const [];
    final members = ref.watch(groupMembersProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createGroup(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New group'),
      ),
      body: groups.isEmpty
          ? const Center(
              child: EmptyState(
                title: 'Keep people together',
                message: 'Make groups like Family, Office or College friends. Use them to filter People, '
                    'choose who to wish in Wish Mode, and export to Excel.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                for (final g in groups)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: teamColor(g).withValues(alpha: 0.2),
                        child: Icon(Icons.workspaces_outline, color: teamColor(g)),
                      ),
                      title: Text(g.name),
                      subtitle: Text(_count(members[g.id]?.length ?? 0), style: TextStyle(color: c.muted)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/group/${g.id}'),
                    ),
                  ),
              ],
            ),
    );
  }
}

String _count(int n) => n == 1 ? '1 person' : '$n people';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final g = (ref.watch(groupsProvider).value ?? const []).where((g) => g.id == id).firstOrNull;
    if (g == null) return Scaffold(appBar: AppBar());
    final repo = ref.read(repoProvider);
    final memberIds = ref.watch(groupMembersProvider).value?[id] ?? const <int>{};
    final people = ref.watch(peopleProvider).value ?? const <Person>[];
    final members = people.where((p) => memberIds.contains(p.id)).toList();
    final today = ref.watch(todayProvider).value ?? Day.today();
    final next = <int, Upcoming>{};
    for (final u in computeUpcoming(ref.watch(entriesProvider).value ?? const [], today)) {
      for (final p in u.entry.people) {
        next.putIfAbsent(p.id, () => u);
      }
    }
    members.sort((a, b) => (next[a.id]?.daysLeft ?? 99999).compareTo(next[b.id]?.daysLeft ?? 99999));

    Future<void> edit() async {
      final chosen = await pickPeople(context, people.where((p) => !p.isMe).toList(), memberIds, title: 'Who is in ${g.name}?');
      if (chosen != null) await repo.setGroupMembers(id, chosen);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final name = await askGroupName(context, initial: g.name, title: 'Rename group');
                if (name != null) await repo.renameGroup(id, name);
              } else if (v == 'colour') {
                final colour = await showDialog<int>(
                  context: context,
                  builder: (ctx) => SimpleDialog(title: const Text('Colour'), children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(spacing: 12, runSpacing: 12, children: [
                        for (var i = 0; i < groupColors.length; i++)
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx, i),
                            child: CircleAvatar(backgroundColor: groupColors[i], radius: 20),
                          ),
                      ]),
                    ),
                  ]),
                );
                if (colour != null) {
                  final db = ref.read(databaseProvider);
                  await (db.update(db.groups)..where((t) => t.id.equals(id))).write(GroupsCompanion(color: Value(colour)));
                }
              } else if (v == 'delete' && context.mounted) {
                final ok = await confirm(context,
                    title: 'Delete ${g.name}?', message: 'The people stay in Smriti; only the group is removed.', action: 'Delete', danger: true);
                if (ok) {
                  await repo.deleteGroup(id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'colour', child: Text('Colour')),
              PopupMenuItem(value: 'delete', child: Text('Delete group')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Add or remove'),
      ),
      body: members.isEmpty
          ? Center(
              child: EmptyState(
                title: 'No one here yet',
                message: 'Tick the people who belong in ${g.name}.',
                actionLabel: 'Choose people',
                onAction: edit,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                SectionLabel(_count(members.length)),
                for (final p in members)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: PersonAvatar(person: p, size: 40),
                      title: Text(p.name),
                      subtitle: Text(
                        next[p.id] == null
                            ? p.relationLabel
                            : '${next[p.id]!.entry.typeLabel} · ${relativeDays(next[p.id]!.daysLeft)}',
                        style: TextStyle(color: c.muted),
                      ),
                      onTap: () => context.push('/person/${p.id}'),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Profile card: which groups this person is in.
class PersonGroupsCard extends ConsumerWidget {
  const PersonGroupsCard({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final groups = ref.watch(groupsProvider).value ?? const <PersonGroup>[];
    final mine = ref.watch(personGroupIdsProvider(person.id));
    final repo = ref.read(repoProvider);

    Future<void> edit() async {
      final chosen = {...mine};
      final result = await showModalBottomSheet<Set<int>>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => SafeArea(
            child: ListView(shrinkWrap: true, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                child: Row(children: [
                  Expanded(child: Text('Groups', style: ctx.text.titleLarge)),
                  TextButton(onPressed: () => Navigator.pop(ctx, chosen), child: const Text('Done')),
                ]),
              ),
              for (final g in ref.read(groupsProvider).value ?? const <PersonGroup>[])
                CheckboxListTile(
                  value: chosen.contains(g.id),
                  onChanged: (v) => set(() => v! ? chosen.add(g.id) : chosen.remove(g.id)),
                  title: Text(g.name),
                  secondary: Icon(Icons.circle, size: 14, color: teamColor(g)),
                ),
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: const Text('New group'),
                onTap: () async {
                  final name = await askGroupName(ctx);
                  if (name == null) return;
                  final count = (ref.read(groupsProvider).value ?? const []).length;
                  final gid = await repo.addGroup(name, color: count % groupColors.length);
                  set(() => chosen.add(gid));
                },
              ),
            ]),
          ),
        ),
      );
      if (result != null) await repo.setPersonGroups(person.id, result);
    }

    final list = groups.where((g) => mine.contains(g.id)).toList();
    return InfoCard(
      title: 'Groups',
      trailing: TextButton.icon(onPressed: edit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit')),
      children: [
        if (list.isEmpty)
          Text('Not in any group yet.', style: context.text.bodyMedium?.copyWith(color: c.muted))
        else
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final g in list)
              ActionChip(
                avatar: Icon(Icons.circle, size: 12, color: teamColor(g)),
                label: Text(g.name),
                onPressed: () => context.push('/group/${g.id}'),
              ),
          ]),
      ],
    );
  }
}

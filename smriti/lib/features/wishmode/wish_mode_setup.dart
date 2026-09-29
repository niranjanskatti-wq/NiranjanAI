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
import '../festivals/festival_model.dart';
import '../messages/message_engine.dart';
import '../wish/wish_buttons.dart';
import 'wish_mode_repo.dart';

enum _Pick { suggested, stars, everyone, choose }

/// Choose who to wish for a festival, or everyone with an event today.
class WishModeSetupScreen extends ConsumerStatefulWidget {
  const WishModeSetupScreen({super.key, this.festivalKey});

  /// Null means "everyone with an event today".
  final String? festivalKey;

  @override
  ConsumerState<WishModeSetupScreen> createState() => _WishModeSetupScreenState();
}

class _WishModeSetupScreenState extends ConsumerState<WishModeSetupScreen> {
  _Pick _pick = _Pick.suggested;
  int _minStars = 4;
  final _chosen = <int>{};
  bool _initialised = false;
  int? _groupId;

  bool _matches(Person p, Festival? f) => switch (_pick) {
        _Pick.suggested => f == null || f.suggest.isEmpty || f.suggest.contains('all') ||
            f.suggest.contains(p.relation.name) || f.suggest.contains(relationGroup(p.relation)),
        _Pick.stars => p.stars >= _minStars,
        _Pick.everyone => true,
        _Pick.choose => _chosen.contains(p.id),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final today = ref.watch(todayProvider).value ?? Day.today();
    final people = (ref.watch(peopleProvider).value ?? const <Person>[]).toList()
      ..sort((a, b) => b.stars != a.stars ? b.stars.compareTo(a.stars) : a.name.compareTo(b.name));
    final groupMembers = ref.watch(groupMemberIdsProvider(_groupId));

    // ----- Today mode: everyone with an event today -----
    if (widget.festivalKey == null) {
      final todays = computeUpcoming(ref.watch(entriesProvider).value ?? const [], today)
          .where((u) => u.isToday && canWish(u.entry))
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text("Today's wishes")),
        body: todays.isEmpty
            ? const Center(child: EmptyState(title: 'Nothing today', message: 'No birthdays or anniversaries today.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  Text('Go through everyone celebrating today, one at a time.', style: context.text.bodyMedium),
                  const SizedBox(height: 12),
                  for (final u in todays)
                    ListTile(
                      leading: EventAvatar(entry: u.entry, size: 40),
                      title: Text(u.entry.title),
                      subtitle: Text('${u.entry.relationLine} · ${u.entry.typeLabel}'),
                    ),
                ],
              ),
        bottomNavigationBar: todays.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    onPressed: () async {
                      final id = await WishModeRepo(ref.read(databaseProvider)).create(
                        title: "Today's wishes · ${fmtDayMonth(today)}",
                        date: today.toString(),
                        people: [
                          for (final u in todays)
                            if (u.entry.primary != null) (u.entry.people.firstWhere((p) => !p.isMe).id, u.entry.event.id),
                        ],
                      );
                      if (context.mounted) context.pushReplacement('/wish-mode/$id');
                    },
                    child: Text('Start · ${todays.length} to wish'),
                  ),
                ),
              ),
      );
    }

    // ----- Festival mode -----
    final f = ref.watch(festivalsProvider).where((x) => x.key == widget.festivalKey).firstOrNull;
    if (f == null) return Scaffold(appBar: AppBar());
    final date = f.nextFrom(today) ?? today;
    if (!_initialised && people.isNotEmpty) {
      _initialised = true;
      if (f.suggest.isEmpty || f.suggest.contains('all')) _pick = _Pick.stars;
      _chosen.addAll(people.where((p) => _matches(p, f)).map((p) => p.id));
    }
    final selected = people
        .where((p) => (_pick == _Pick.choose ? _chosen.contains(p.id) : _matches(p, f)))
        .where((p) => groupMembers == null || groupMembers.contains(p.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Wish Mode · ${f.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          Text('${fmtWeekday(date)} · ${relativeDays(today.daysUntil(date))}', style: context.text.bodySmall),
          const SizedBox(height: 12),
          const SectionLabel('Who to wish'),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (p, label) in [
              if (f.suggest.isNotEmpty && !f.suggest.contains('all')) (_Pick.suggested, 'Suggested (${f.suggest.join(', ')})'),
              (_Pick.stars, 'By stars'),
              (_Pick.everyone, 'Everyone'),
              (_Pick.choose, 'Choose people'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _pick == p,
                showCheckmark: false,
                labelStyle: context.text.titleSmall?.copyWith(color: _pick == p ? c.bg : c.text),
                onSelected: (_) => setState(() {
                  if (p == _Pick.choose) {
                    _chosen
                      ..clear()
                      ..addAll(selected.map((x) => x.id));
                  }
                  _pick = p;
                }),
              ),
          ]),
          if (_pick == _Pick.stars) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text('At least', style: context.text.bodyMedium),
              const SizedBox(width: 8),
              Stars(value: _minStars, size: 26, onChanged: (v) => setState(() => _minStars = v)),
            ]),
          ],
          GroupFilter(value: _groupId, onChanged: (g) => setState(() => _groupId = g)),
          const SizedBox(height: 12),
          SectionLabel('${selected.length} people'),
          for (final p in people.where((p) => groupMembers == null || groupMembers.contains(p.id)))
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: selected.contains(p),
              onChanged: (v) => setState(() {
                if (_pick != _Pick.choose) {
                  _chosen
                    ..clear()
                    ..addAll(selected.map((x) => x.id));
                  _pick = _Pick.choose;
                }
                v! ? _chosen.add(p.id) : _chosen.remove(p.id);
              }),
              secondary: PersonAvatar(person: p, size: 38),
              title: Text(p.shortName),
              subtitle: Row(children: [
                Text(p.relationLabel),
                const SizedBox(width: 8),
                Stars(value: p.stars, size: 10),
                if (p.callNumber == null && p.whatsappNumber == null) ...[
                  const SizedBox(width: 8),
                  Text('no number', style: TextStyle(color: c.alert, fontSize: 11)),
                ],
              ]),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: selected.isEmpty
                ? null
                : () async {
                    final id = await WishModeRepo(ref.read(databaseProvider)).create(
                      title: '${f.name} wishes',
                      festivalKey: f.key,
                      date: date.toString(),
                      people: [for (final p in selected) (p.id, null)],
                    );
                    if (context.mounted) context.pushReplacement('/wish-mode/$id');
                  },
            child: Text('Start · ${selected.length} to wish'),
          ),
        ),
      ),
    );
  }
}

/// Optional group filter (groups arrive in Phase 7; hidden when there are none).
final groupMemberIdsProvider = Provider.family<Set<int>?, int?>((ref, groupId) => null);

class GroupFilter extends StatelessWidget {
  const GroupFilter({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

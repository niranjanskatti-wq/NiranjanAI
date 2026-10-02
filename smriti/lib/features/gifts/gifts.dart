import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

final _rupees = NumberFormat.decimalPattern('en_IN');
String rupees(int n) => '₹${_rupees.format(n)}';

/// Add or edit a gift idea for [personId]. [eventId] preselects the occasion.
Future<void> editGift(BuildContext context, WidgetRef ref, {required int personId, GiftIdea? gift, int? eventId}) async {
  final idea = TextEditingController(text: gift?.idea ?? '');
  final budget = TextEditingController(text: gift?.budget?.toString() ?? '');
  var forEvent = gift?.eventId ?? eventId;
  var bought = gift?.purchased ?? false;
  final events = (await ref.read(repoProvider).watchEntriesForPerson(personId).first).where((e) => !e.isArchived).toList();
  if (forEvent != null && !events.any((e) => e.event.id == forEvent)) forEvent = null;
  if (!context.mounted) return;
  final repo = ref.read(repoProvider);
  final result = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(gift == null ? 'Gift idea' : 'Edit gift idea', style: ctx.text.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: idea,
            autofocus: gift == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Idea', hintText: 'e.g. Mysore Pak from Guru Sweets'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: budget,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Budget (optional)', prefixText: '₹ '),
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: forEvent,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'For'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any occasion')),
                for (final e in events)
                  DropdownMenuItem(
                    value: e.event.id,
                    child: Text('${e.typeLabel} · ${fmtDayMonth(Day(2000, e.event.month, e.event.day))}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => set(() => forEvent = v),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bought'),
            value: bought,
            onChanged: (v) => set(() => bought = v),
          ),
          Row(children: [
            if (gift != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: Text('Delete', style: TextStyle(color: ctx.c.alert)),
              ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save')),
          ]),
        ]),
      ),
    ),
  );
  final text = idea.text.trim();
  final amount = int.tryParse(budget.text.trim());
  if (result == 'delete' && gift != null) {
    await repo.deleteGift(gift.id);
  } else if (result == 'save' && text.isNotEmpty) {
    if (gift == null) {
      await repo.addGift(personId, text, budget: amount, eventId: forEvent);
      if (bought) {
        final all = await repo.watchGifts(personId).first;
        await repo.setGiftPurchased(all.last.id, true);
      }
    } else {
      await repo.updateGift(gift.id, idea: text, budget: amount, eventId: forEvent, purchased: bought);
    }
  }
}

/// One gift line with a tick box.
class GiftRow extends ConsumerWidget {
  const GiftRow({super.key, required this.gift, this.eventLabel, this.showPerson});

  final GiftIdea gift;
  final String? eventLabel;
  final Person? showPerson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final g = gift;
    final sub = [
      if (showPerson != null) showPerson!.shortName,
      ?eventLabel,
      if (g.budget != null) rupees(g.budget!),
    ].join(' · ');
    return InkWell(
      onTap: () => editGift(context, ref, personId: g.personId, gift: g),
      child: Row(children: [
        Checkbox(value: g.purchased, onChanged: (v) => ref.read(repoProvider).setGiftPurchased(g.id, v ?? false)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                g.idea,
                style: context.text.bodyMedium?.copyWith(
                  decoration: g.purchased ? TextDecoration.lineThrough : null,
                  color: g.purchased ? c.muted : c.text,
                ),
              ),
              if (sub.isNotEmpty) Text(sub, style: context.text.bodySmall?.copyWith(color: c.muted)),
            ]),
          ),
        ),
        Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
      ]),
    );
  }
}

/// Profile card listing a person's gift ideas.
class GiftCard extends ConsumerWidget {
  const GiftCard({super.key, required this.personId, required this.gifts, required this.entries});

  final int personId;
  final List<GiftIdea> gifts;
  final List<EventEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = {for (final e in entries) e.event.id: e.typeLabel};
    final planned = gifts.where((g) => !g.purchased && g.budget != null).fold(0, (a, g) => a + g.budget!);
    return InfoCard(
      title: planned > 0 ? 'Gift ideas · ${rupees(planned)} planned' : 'Gift ideas',
      trailing: TextButton.icon(
        onPressed: () => editGift(context, ref, personId: personId),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add'),
      ),
      children: [
        if (gifts.isEmpty) Text('Jot down ideas as you think of them.', style: context.text.bodyMedium),
        for (final g in gifts) GiftRow(gift: g, eventLabel: labels[g.eventId]),
      ],
    );
  }
}

/// Upcoming occasions with their gift plans, and every idea in one place.
class GiftPlannerScreen extends ConsumerStatefulWidget {
  const GiftPlannerScreen({super.key});

  @override
  ConsumerState<GiftPlannerScreen> createState() => _GiftPlannerScreenState();
}

class _GiftPlannerScreenState extends ConsumerState<GiftPlannerScreen> {
  int _days = 60;
  bool _hideBought = true;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final gifts = ref.watch(allGiftsProvider).value ?? const <GiftIdea>[];
    final people = {for (final p in ref.watch(peopleProvider).value ?? const <Person>[]) p.id: p};
    final entries = ref.watch(entriesProvider).value ?? const <EventEntry>[];
    final today = ref.watch(todayProvider).value ?? Day.today();
    final upcoming = computeUpcoming(entries, today)
        .where((u) => u.daysLeft <= _days && (u.entry.kind == EventKind.person || u.entry.kind == EventKind.couple))
        .toList();
    final labels = {for (final e in entries) e.event.id: e.typeLabel};
    final planned = gifts.where((g) => !g.purchased && g.budget != null).fold(0, (a, g) => a + g.budget!);
    final bought = gifts.where((g) => g.purchased && g.budget != null).fold(0, (a, g) => a + g.budget!);

    List<GiftIdea> giftsFor(EventEntry e) {
      final ids = e.people.map((p) => p.id).toSet();
      return gifts
          .where((g) => (g.eventId == e.event.id || (g.eventId == null && ids.contains(g.personId))) && !(g.purchased && _hideBought))
          .toList();
    }

    final byPerson = <int, List<GiftIdea>>{};
    for (final g in gifts.where((g) => !(g.purchased && _hideBought))) {
      (byPerson[g.personId] ??= []).add(g);
    }
    final order = byPerson.keys.where(people.containsKey).toList()..sort((a, b) => people[a]!.name.compareTo(people[b]!.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Gift planner'), actions: [
        PopupMenuButton<String>(
          onSelected: (v) => setState(() => v == 'bought' ? _hideBought = !_hideBought : _days = int.parse(v)),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(value: 'bought', checked: !_hideBought, child: const Text('Show bought')),
            const PopupMenuDivider(),
            for (final d in [30, 60, 90])
              CheckedPopupMenuItem(value: '$d', checked: _days == d, child: Text('Next $d days')),
          ],
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Row(children: [
            Expanded(child: _Total(label: 'Planned', value: rupees(planned), color: c.goldText)),
            const SizedBox(width: 10),
            Expanded(child: _Total(label: 'Bought', value: rupees(bought), color: c.call)),
          ]),
          SectionLabel('Coming up · next $_days days'),
          if (upcoming.isEmpty) Text('Nothing in the next $_days days.', style: context.text.bodyMedium?.copyWith(color: c.muted)),
          for (final u in upcoming)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    EventAvatar(entry: u.entry, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u.entry.title, style: context.text.titleMedium),
                        Text('${u.entry.typeLabel} · ${relativeDays(u.daysLeft)}',
                            style: context.text.bodySmall?.copyWith(color: c.muted)),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Add gift idea',
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => editGift(context, ref, personId: u.entry.people.first.id, eventId: u.entry.event.id),
                    ),
                  ]),
                  for (final g in giftsFor(u.entry)) GiftRow(gift: g, eventLabel: labels[g.eventId]),
                  if (giftsFor(u.entry).isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(46, 0, 0, 6),
                      child: Text('No gift idea yet', style: context.text.bodySmall?.copyWith(color: c.muted)),
                    ),
                ]),
              ),
            ),
          SectionLabel(_hideBought ? 'All ideas still to buy' : 'All ideas'),
          if (order.isEmpty)
            Text('Add ideas from anyone’s profile, or with + above.', style: context.text.bodyMedium?.copyWith(color: c.muted)),
          for (final id in order)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  InkWell(
                    onTap: () => context.push('/person/$id'),
                    child: Row(children: [
                      PersonAvatar(person: people[id], size: 28),
                      const SizedBox(width: 8),
                      Expanded(child: Text(people[id]!.name, style: context.text.titleSmall)),
                    ]),
                  ),
                  for (final g in byPerson[id]!) GiftRow(gift: g, eventLabel: labels[g.eventId]),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.color});

  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: context.text.labelSmall),
            const SizedBox(height: 4),
            Text(value, style: context.text.headlineSmall?.copyWith(color: color, fontFamily: serif, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

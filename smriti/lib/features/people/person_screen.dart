import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../memories/memories.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../wish/wish_buttons.dart';
import '../wish/wish_history.dart';

class PersonScreen extends ConsumerWidget {
  const PersonScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(personProvider(id));
    return person.when(
      loading: () => const Scaffold(),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (p) {
        if (p == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('This person was deleted.')));
        }
        return _PersonView(person: p);
      },
    );
  }
}

class _PersonView extends ConsumerWidget {
  const _PersonView({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final p = person;
    final today = ref.watch(todayProvider).value ?? Day.today();
    final entries = ref.watch(entriesForPersonProvider(p.id)).value ?? const <EventEntry>[];
    final upcoming = computeUpcoming(entries, today, includeArchived: true);
    final past = entries.where((e) => e.nextFrom(today) == null).toList();
    final gifts = ref.watch(giftsProvider(p.id)).value ?? const <GiftIdea>[];

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: () => context.push('/person/${p.id}/edit'), child: const Text('Edit')),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) => _menu(context, ref, v),
            itemBuilder: (_) => [
              if (!p.isMe)
                PopupMenuItem(value: 'archive', child: Text(p.isArchived ? 'Move back to People' : 'Archive')),
              PopupMenuItem(
                  value: 'delete', child: Text('Delete', style: TextStyle(color: c.alert))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            Center(child: PersonAvatar(person: p, size: 104, ring: true)),
            const SizedBox(height: 12),
            Text(p.shortName, textAlign: TextAlign.center, style: context.text.displayMedium),
            const SizedBox(height: 4),
            Text(
              [if (p.nickname != null && p.nickname!.isNotEmpty) p.name, p.isMe ? 'You' : p.relationLabel]
                  .join(' · '),
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
            if (!p.isMe) ...[
              const SizedBox(height: 6),
              Center(child: Stars(value: p.stars, size: 18)),
            ],
            if (p.isArchived) ...[
              const SizedBox(height: 8),
              Center(child: Text('Archived', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700))),
            ],
            if (!p.isMe) ...[
              const SizedBox(height: 16),
              PersonCallShare(person: p, next: upcoming.where((u) => canWish(u.entry)).firstOrNull),
            ],
            const SizedBox(height: 20),
            InfoCard(
              title: 'Events',
              trailing: TextButton.icon(
                onPressed: () => context.push('/event/new?kind=person&person=${p.id}'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
              children: [
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No dates yet. Add a birthday or anniversary.', style: context.text.bodyMedium),
                  ),
                for (final u in upcoming) _EventLine(item: u),
                for (final e in past)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(e.type.icon, color: c.muted),
                    title: Text(e.typeLabel),
                    subtitle: Text('Past · ${fmtEventDate(day: e.event.day, month: e.event.month, year: e.event.year)}'),
                    onTap: () => context.push('/event/${e.event.id}'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _GiftCard(personId: p.id, gifts: gifts),
            const SizedBox(height: 12),
            MemoriesCard(person: p),
            if (!p.isMe) ...[
              const SizedBox(height: 12),
              WishHistoryCard(person: p, eventIds: entries.map((e) => e.event.id).toSet()),
            ],
            const SizedBox(height: 12),
            InfoCard(
              title: 'Details',
              children: [
                _kv(context, 'Call', p.callNumber == null ? 'Not added' : formatPhone(p.callNumber)),
                _kv(context, 'WhatsApp',
                    p.whatsappNumber == null ? (p.callNumber == null ? 'Not added' : 'Same as call') : formatPhone(p.whatsappNumber)),
                if (p.birthYear != null) _kv(context, 'Birth year', '${p.birthYear}'),
                if (p.timeZone != null) _kv(context, 'Time zone', p.timeZone!.replaceAll('_', ' ')),
                _kv(context, 'Phone contact', p.contactId == null ? 'Not linked' : 'Linked'),
              ],
            ),
            if ([p.notes, p.likes, p.dislikes, p.clothingSize, p.favouriteSweets].any((v) => v != null && v.isNotEmpty)) ...[
              const SizedBox(height: 12),
              InfoCard(
                title: 'About ${p.shortName}',
                children: [
                  if (p.notes?.isNotEmpty ?? false) _para(context, 'Notes', p.notes!),
                  if (p.likes?.isNotEmpty ?? false) _para(context, 'Likes', p.likes!),
                  if (p.dislikes?.isNotEmpty ?? false) _para(context, 'Dislikes', p.dislikes!),
                  if (p.clothingSize?.isNotEmpty ?? false) _para(context, 'Clothing size', p.clothingSize!),
                  if (p.favouriteSweets?.isNotEmpty ?? false) _para(context, 'Favourite sweets', p.favouriteSweets!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, String v) async {
    final repo = ref.read(repoProvider);
    if (v == 'archive') {
      await repo.setArchived(person.id, !person.isArchived);
      if (context.mounted) {
        showToast(context, person.isArchived ? 'Moved back to People' : 'Archived. Find them in People › Archived.');
      }
    } else if (v == 'delete') {
      final ok = await confirm(context,
          title: 'Delete ${person.shortName}?',
          message: 'This removes them and their events from Smriti. Your phone contacts are not touched.',
          action: 'Delete',
          danger: true);
      if (!ok) return;
      await repo.deletePerson(person.id);
      if (context.mounted) {
        context.pop();
        showToast(context, 'Deleted');
      }
    }
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(k, style: context.text.bodyMedium?.copyWith(color: context.c.muted)),
          const SizedBox(width: 16),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: context.text.titleSmall)),
        ]),
      );

  Widget _para(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: context.text.bodySmall),
          const SizedBox(height: 2),
          Text(v, style: context.text.bodyMedium),
        ]),
      );
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.item});

  final Upcoming item;

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final c = context.c;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push('/event/${e.event.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: groupColor(e.type.group), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.kind.name == 'couple' ? '${e.typeLabel} · ${e.title}' : e.typeLabel,
                  style: context.text.titleMedium),
              Text(
                [fmtWeekday(item.date), ?item.yearsPhrase, relativeDays(item.daysLeft)].join(' · '),
                style: context.text.bodySmall,
              ),
            ]),
          ),
          if (item.milestone) Badge2('${item.years}') else Icon(Icons.chevron_right_rounded, color: c.muted),
        ]),
      ),
    );
  }
}

class _GiftCard extends ConsumerWidget {
  const _GiftCard({required this.personId, required this.gifts});

  final int personId;
  final List<GiftIdea> gifts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final repo = ref.read(repoProvider);
    return InfoCard(
      title: 'Gift ideas',
      trailing: TextButton.icon(
        onPressed: () async {
          final t = TextEditingController();
          final idea = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Gift idea'),
              content: TextField(
                controller: t,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'e.g. Mysore Pak from Guru Sweets'),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, t.text), child: const Text('Add')),
              ],
            ),
          );
          if (idea != null && idea.trim().isNotEmpty) await repo.addGift(personId, idea.trim());
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add'),
      ),
      children: [
        if (gifts.isEmpty) Text('Jot down ideas as you think of them.', style: context.text.bodyMedium),
        for (final g in gifts)
          Row(children: [
            Checkbox(
              value: g.purchased,
              onChanged: (v) => repo.setGiftPurchased(g.id, v ?? false),
            ),
            Expanded(
              child: Text(
                g.idea,
                style: context.text.bodyMedium?.copyWith(
                  decoration: g.purchased ? TextDecoration.lineThrough : null,
                  color: g.purchased ? c.muted : c.text,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: () => repo.deleteGift(g.id),
              icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
            ),
          ]),
      ],
    );
  }
}

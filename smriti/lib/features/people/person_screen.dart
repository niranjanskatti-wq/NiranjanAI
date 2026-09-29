import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../gifts/gifts.dart';
import '../groups/groups_screen.dart';
import '../memories/memories.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/enums.dart';
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
    final birthday = upcoming.where((u) => u.entry.type == EventType.birthday && u.entry.kind == EventKind.person).firstOrNull;
    final turning = birthday?.years;
    final ageNow = turning == null ? null : (birthday!.isToday ? turning : turning - 1);

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
            if (ageNow != null && ageNow >= 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  birthday!.isToday ? 'Turns $ageNow today 🎉' : 'Age $ageNow · turning ${ageNow + 1} ${relativeDays(birthday.daysLeft)}',
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: c.goldText),
                ),
              ),
            ],
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
                for (final u in upcoming) _DateTile(item: u, showPartner: u.entry.kind == EventKind.couple),
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
            if (!p.isMe) ...[
              PersonGroupsCard(person: p),
              const SizedBox(height: 12),
            ],
            GiftCard(personId: p.id, gifts: gifts, entries: entries),
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

/// One date on the profile, large and clear: what it is, the date, the age and how long to go.
class _DateTile extends StatelessWidget {
  const _DateTile({required this.item, this.showPartner = false});

  final Upcoming item;
  final bool showPartner;

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final c = context.c;
    final color = groupColor(e.type.group);
    final ev = e.event;
    final monthly = e.repeat == Repeat.monthly;
    final date = monthly ? 'Every month on the ${ordinal(ev.day)}' : '${ev.day} ${monthNames[ev.month - 1]}';
    final since = e.startYear;
    final phrase = item.yearsPhrase;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: item.milestone ? c.gold : color.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/event/${ev.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  KindPill(entry: e, large: true),
                  if (showPartner) ...[
                    const SizedBox(height: 4),
                    Text(e.title, style: context.text.bodySmall),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    since != null && !monthly ? '$date $since' : date,
                    style: context.text.headlineSmall?.copyWith(fontFamily: serif, fontWeight: FontWeight.w700),
                  ),
                  if (phrase != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Flexible(
                        child: Text(
                          phrase,
                          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: c.goldText),
                        ),
                      ),
                      if (item.milestone) ...[const SizedBox(width: 6), Icon(Icons.auto_awesome, size: 16, color: c.gold)],
                    ]),
                  ],
                  if (phrase == null && e.type == EventType.birthday && e.kind == EventKind.person && e.primary != null)
                    GestureDetector(
                      onTap: () => context.push('/person/${e.primary!.id}/edit'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Add birth year to see the age',
                            style: context.text.bodyMedium?.copyWith(
                                color: c.goldText, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text('Next: ${fmtWeekday(item.date)} ${item.date.year}', style: context.text.bodySmall),
                ]),
              ),
              const SizedBox(width: 12),
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (item.isToday)
                  const Badge2('Today')
                else ...[
                  Text('${item.daysLeft}',
                      style: TextStyle(
                          fontFamily: sans, fontSize: 28, fontWeight: FontWeight.w800, height: 1, color: c.text)),
                  const SizedBox(height: 2),
                  Text(item.daysLeft == 1 ? 'day to go' : 'days to go', style: context.text.bodySmall),
                ],
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

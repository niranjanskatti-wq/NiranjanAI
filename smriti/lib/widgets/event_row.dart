import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import '../core/util/format.dart';
import '../data/enums.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../features/festivals/festival_route.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/wish/wish_buttons.dart';
import 'common.dart';

/// One line in the upcoming list: avatar, name, what and when, stars, days left.
class UpcomingRow extends ConsumerWidget {
  const UpcomingRow({super.key, required this.item, this.belated = false});

  final Upcoming item;
  final bool belated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final e = item.entry;
    final bell = (ref.watch(allRemindersProvider).value?[e.event.id] ?? const []).any((s) => s.enabled);
    final festival = e.kind == EventKind.festival;
    final saffron = groupColor(EventGroup.festival);
    final age = item.ageText;
    final details = [
      if (e.relationLine.isNotEmpty && (e.kind == EventKind.person || e.kind == EventKind.couple)) e.relationLine,
      fmtWeekday(item.date),
    ].join(' · ');
    return Material(
      color: festival ? Color.alphaBlend(saffron.withValues(alpha: 0.09), c.surface) : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: festival ? saffron.withValues(alpha: 0.45) : (item.milestone ? c.gold : c.line),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openEntry(context, e),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A coloured edge so festivals stand apart from people's days.
              if (festival) Container(width: 4, color: saffron),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(festival ? 8 : 12, 10, 14, 10),
                  child: Row(
                    children: [
                      EventAvatar(entry: e, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(children: [
                              Flexible(
                                child: Text(e.title,
                                    style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              if (e.kind == EventKind.person || e.kind == EventKind.couple) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.star_rounded, size: 13, color: c.gold),
                                Text('${e.stars}', style: context.text.labelSmall?.copyWith(color: c.muted)),
                              ],
                              if (bell) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.notifications_none_rounded, size: 14, color: c.muted),
                              ],
                            ]),
                            const SizedBox(height: 4),
                            // Kind and age wrap onto a new line rather than ever being cut off.
                            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                              KindPill(entry: e),
                              if (age != null)
                                Text(
                                  age,
                                  style: TextStyle(
                                    fontFamily: sans,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: item.milestone ? c.goldText : c.text,
                                  ),
                                )
                              else if (e.type == EventType.birthday && e.kind == EventKind.person)
                                Text('No birth year', style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                              // Why the row has a gold border: a big birthday or anniversary.
                              if (item.milestone) const Badge2('Milestone', sparkle: true),
                            ]),
                            const SizedBox(height: 4),
                            Text(details, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (canWish(e)) ...[
                        const SizedBox(width: 6),
                        MiniCallShare(entry: e, date: item.date, belated: belated, vertical: true),
                      ],
                      const SizedBox(width: 10),
                      belated
                          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${-item.daysLeft}d ago',
                                  style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              // Wished outside Smriti? One tap takes it off the Missed list.
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => ref
                                    .read(repoProvider)
                                    .markWished(eventId: e.event.id, occasionDate: item.date.toString(), personId: e.primary?.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: c.call),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.check_rounded, size: 14, color: c.call),
                                    const SizedBox(width: 3),
                                    Text('Wished', style: context.text.labelSmall?.copyWith(color: c.call)),
                                  ]),
                                ),
                              ),
                            ])
                          : _DaysLeft(days: item.daysLeft, color: festival ? saffron : null),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysLeft extends StatelessWidget {
  const _DaysLeft({required this.days, this.color});

  final int days;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (days == 0) return const Badge2('Today');
    if (days < 0) return Text('Passed', style: context.text.bodySmall);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$days',
            style: TextStyle(
                fontFamily: sans,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1,
                color: color ?? c.text,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 2),
        Text(days == 1 ? 'day' : 'days', style: context.text.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}

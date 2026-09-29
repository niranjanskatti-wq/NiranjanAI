import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';
import '../core/util/format.dart';
import '../data/enums.dart';
import '../data/models.dart';
import 'common.dart';

/// One line in the upcoming list: avatar, name, what and when, stars, days left.
class UpcomingRow extends StatelessWidget {
  const UpcomingRow({super.key, required this.item});

  final Upcoming item;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final e = item.entry;
    final sub = [
      if (e.kind != EventKind.other) e.relationLine,
      e.typeLabel,
      fmtDayMonth(item.date),
      ?item.yearsPhrase,
    ].join(' · ');
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: item.milestone ? c.gold : c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/event/${e.event.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(
            children: [
              EventAvatar(entry: e, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(e.title,
                            style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (item.milestone) ...[const SizedBox(width: 6), Icon(Icons.auto_awesome, size: 14, color: c.gold)],
                    ]),
                    const SizedBox(height: 2),
                    Text(sub, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (e.kind != EventKind.other) ...[
                      const SizedBox(height: 3),
                      Stars(value: e.stars, size: 11),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DaysLeft(days: item.daysLeft),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysLeft extends StatelessWidget {
  const _DaysLeft({required this.days});

  final int days;

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
                color: c.text,
                fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 2),
        Text(days == 1 ? 'day' : 'days', style: context.text.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}

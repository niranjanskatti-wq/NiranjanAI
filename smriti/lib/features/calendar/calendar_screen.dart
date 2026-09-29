import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/event_row.dart';
import '../festivals/festival_model.dart';

/// Month grid with coloured dots for each event; tap a day to see its events.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Day? _selected;

  /// Every event happening in the shown month, keyed by day.
  Map<int, List<Upcoming>> _byDay(List<EventEntry> entries, Day today) {
    final first = Day(_month.year, _month.month, 1);
    final last = Day(_month.year, _month.month, daysInMonth(_month.year, _month.month));
    final out = <int, List<Upcoming>>{};
    for (final e in entries) {
      if (e.isArchived) continue;
      // Every repeat type happens at most once in a month.
      final d = e.nextFrom(first);
      if (d != null && !(last < d)) {
        out.putIfAbsent(d.day, () => []).add(Upcoming(e, d, today.daysUntil(d)));
      }
    }
    for (final list in out.values) {
      list.sort((a, b) => b.entry.stars.compareTo(a.entry.stars));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final entries = ref.watch(allEntriesProvider);
    final today = ref.watch(todayProvider).value ?? Day.today();
    final byDay = _byDay(entries, today);
    final daysCount = daysInMonth(_month.year, _month.month);
    final leading = (DateTime(_month.year, _month.month, 1).weekday + 6) % 7; // Monday first
    final selected = _selected != null && _selected!.year == _month.year && _selected!.month == _month.month
        ? _selected
        : null;
    final shown = selected == null
        ? [for (final d in byDay.keys.toList()..sort()) ...byDay[d]!]
        : (byDay[selected.day] ?? const <Upcoming>[]);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar'), actions: [
        IconButton(
          tooltip: 'Export to Excel',
          icon: const Icon(Icons.table_chart_outlined),
          onPressed: () => context.push('/export'),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Row(children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(fmtMonthYear(_month), textAlign: TextAlign.center, style: context.text.headlineMedium),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(child: Text(d, textAlign: TextAlign.center, style: context.text.labelSmall)),
          ]),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.9),
            itemCount: leading + daysCount,
            itemBuilder: (_, i) {
              if (i < leading) return const SizedBox.shrink();
              final day = i - leading + 1;
              final d = Day(_month.year, _month.month, day);
              final items = byDay[day] ?? const <Upcoming>[];
              final isToday = d == today;
              final isSel = d == selected;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selected = isSel ? null : d),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSel ? c.text : (isToday ? c.gold.withValues(alpha: 0.16) : null),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSel ? Border.all(color: c.gold) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day',
                          style: context.text.titleSmall?.copyWith(
                            color: isSel ? c.bg : c.text,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          )),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final u in items.take(3))
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(color: groupColor(u.entry.type.group), shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            selected == null ? 'This month' : fmtWeekday(selected),
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(selected == null ? 'Nothing this month.' : 'Nothing on this day.',
                  style: context.text.bodyMedium?.copyWith(color: c.muted)),
            ),
          for (final u in shown) Padding(padding: const EdgeInsets.only(bottom: 8), child: UpcomingRow(item: u)),
        ],
      ),
    );
  }
}

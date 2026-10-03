import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/stats.dart';
import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/demo.dart';
import '../../data/providers.dart';
import '../../ui/charts.dart';
import '../../ui/widgets.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int? range;
  bool loadingDemo = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final r = range ?? s.i('insights.defaultRange');
    final sessionsA = ref.watch(sessionsProvider);
    final distractionsA = ref.watch(distractionsProvider);
    final tasks = ref.watch(tasksProvider).value ?? const <TaskItem>[];
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final reasons = ref.watch(reasonsProvider).value ?? const <DistractionReason>[];
    final since = rangeStart(r);
    final all = sessionsA.value ?? const <FocusSession>[];
    final sessions = all.where((x) => x.startedAt >= since).toList();
    final distractions = (distractionsA.value ?? const <Distraction>[]).where((d) => d.timestamp >= since).toList();
    final charts = s.strings('insights.charts').toSet();
    bool show(String id, [String? module]) => charts.contains(id) && (module == null || s.on(module));
    final cards = s.on('insightCards')
        ? computeInsightCards(settings: s, sessions: sessions, allSessions: all, distractions: distractions, tasks: tasks, projects: projects, range: r)
        : const <InsightCard>[];
    final hours = (sessions.fold<int>(0, (a, x) => a + x.actualDuration) / 360).round() / 10;
    final wide = MediaQuery.sizeOf(context).width >= 760;

    Widget grid(List<Widget> items) {
      if (!wide) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final w in items) Padding(padding: EdgeInsets.only(bottom: context.density.gap), child: w)]);
      final rows = <Widget>[];
      for (var i = 0; i < items.length; i += 2) {
        rows.add(Padding(
          padding: EdgeInsets.only(bottom: context.density.gap),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: items[i]),
              SizedBox(width: context.density.gap),
              Expanded(child: i + 1 < items.length ? items[i + 1] : const SizedBox()),
            ]),
          ),
        ));
      }
      return Column(children: rows);
    }

    return Scaffold(
      body: PageBody(maxWidth: 1100, children: [
        PageHeader(
          title: 'Insights',
          subtitle: 'Calculated on this device from your own data.',
          action: (s.on('eveningReview') || s.on('weeklyReview')) ? Btn('Reviews', icon: Icons.edit_note_rounded, kind: BtnKind.ghost, small: true, onPressed: () => context.push('/reviews')) : null,
        ),
        Row(children: [
          Segmented<int>(value: r, onChanged: (v) => setState(() => range = v), options: const [(7, '7d'), (14, '14d'), (30, '30d'), (90, '90d'), (0, 'All')]),
          const Spacer(),
          if (wide) Text('${sessions.length} sessions · $hours h', style: TextStyle(color: p.muted, fontSize: 13, fontFeatures: tabular)),
        ]),
        const Gap(),
        if (sessionsA.hasError)
          ErrorBlock(sessionsA.error!)
        else if (!sessionsA.hasValue || !distractionsA.hasValue)
          ...List.generate(3, (_) => const LoadingBlock(height: 220))
        else if (sessions.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.insights_rounded,
              title: all.isEmpty ? 'No data yet' : 'No sessions in this range',
              description: all.isEmpty
                  ? 'Complete a few focus sessions and your charts and insights will appear here. Or preview with demo data.'
                  : 'Try a longer date range.',
              action: all.isEmpty
                  ? Btn(loadingDemo ? 'Loading…' : 'Load demo data', kind: BtnKind.subtle, onPressed: loadingDemo
                      ? null
                      : () async {
                          setState(() => loadingDemo = true);
                          await loadDemoData(ref.read(databaseProvider));
                          await ref.read(settingsProvider.notifier).set('demoLoaded', true);
                          if (!context.mounted) return;
                          setState(() => loadingDemo = false);
                          toast(context, 'Demo data loaded. Clear it any time in Settings → Data.');
                        })
                  : null,
            ),
          )
        else ...[
          if (s.on('insightCards')) ...[
            if (cards.isEmpty)
              AppCard(
                child: Row(children: [
                  Icon(Icons.lightbulb_outline_rounded, color: p.muted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Insight cards appear once there's enough data — usually after a week or two of sessions.", style: TextStyle(color: p.muted, fontSize: 13.5))),
                ]),
              )
            else
              grid([for (final c in cards) _InsightCardView(card: c)]),
            if (cards.isEmpty) const Gap(),
          ],
          grid([
            if (show('focusHours')) _FocusHours(sessions: sessions, all: all, range: r),
            if (show('completionRate')) _Completion(sessions: sessions, all: all, range: r),
            if (show('distractionReasons', 'distractions')) _Distractions(distractions: distractions, reasonOrder: reasons.map((e) => e.label).toList()),
            if (show('byProject', 'tasks')) _ByProject(sessions: sessions, tasks: tasks, projects: projects),
          ]),
          if (show('heatmap')) _Heatmap(sessions: sessions),
        ],
      ]),
    );
  }
}

class _InsightCardView extends StatelessWidget {
  const _InsightCardView({required this.card});
  final InsightCard card;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (icon, color) = switch (card.tone) {
      Tone.attention => (Icons.warning_amber_rounded, p.warning),
      Tone.positive => (Icons.trending_up_rounded, p.success),
      Tone.neutral => (Icons.lightbulb_outline_rounded, p.accent),
    };
    return AppCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.3)),
            const SizedBox(height: 4),
            Text(card.body, style: TextStyle(color: p.muted, fontSize: 13, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

/// Day buckets for short ranges, week buckets for long ones.
List<(String, int, int)> _buckets(int range, List<FocusSession> all) {
  final days = rangeDays(range, all);
  if (days.length <= 31) {
    return [for (final d in days) (days.length <= 7 ? DateFormat('EEE').format(d) : DateFormat('d MMM').format(d), d.millisecondsSinceEpoch, addDays(d, 1).millisecondsSinceEpoch)];
  }
  var w = addDays(days.first, -((days.first.weekday + 6) % 7));
  final out = <(String, int, int)>[];
  while (!w.isAfter(days.last)) {
    out.add((DateFormat('d MMM').format(w), w.millisecondsSinceEpoch, addDays(w, 7).millisecondsSinceEpoch));
    w = addDays(w, 7);
  }
  return out;
}

class _FocusHours extends StatelessWidget {
  const _FocusHours({required this.sessions, required this.all, required this.range});
  final List<FocusSession> sessions, all;
  final int range;
  @override
  Widget build(BuildContext context) {
    final b = _buckets(range, all);
    final values = [for (final (_, s, e) in b) (sessions.where((x) => x.startedAt >= s && x.startedAt < e).fold<int>(0, (a, x) => a + x.actualDuration) / 360).round() / 10];
    final total = values.fold<double>(0, (a, v) => a + v);
    return ChartCard(
      title: 'Focus hours',
      subtitle: '${(total * 10).round() / 10} h ${rangeDays(range, all).length > 31 ? 'by week' : 'by day'}',
      child: SimpleBarChart(labels: [for (final x in b) x.$1], values: values, unit: 'h'),
    );
  }
}

class _Completion extends StatelessWidget {
  const _Completion({required this.sessions, required this.all, required this.range});
  final List<FocusSession> sessions, all;
  final int range;
  @override
  Widget build(BuildContext context) {
    final b = _buckets(range, all);
    final lists = [for (final (_, s, e) in b) sessions.where((x) => x.startedAt >= s && x.startedAt < e).toList()];
    final rates = [for (final l in lists) completionRate(l) == null ? null : (completionRate(l)! * 100).roundToDouble()];
    final overall = completionRate(sessions);
    return ChartCard(
      title: 'Completion rate',
      subtitle: '${overall == null ? '—' : '${(overall * 100).round()}%'} of sessions marked done',
      child: SimpleLineChart(
        labels: [for (final x in b) x.$1],
        values: rates,
        maxY: 100,
        suffix: '%',
        tooltip: (i) => rates[i] == null ? 'no sessions' : '${rates[i]!.round()}% of ${lists[i].length}',
      ),
    );
  }
}

class _Distractions extends StatelessWidget {
  const _Distractions({required this.distractions, required this.reasonOrder});
  final List<Distraction> distractions;
  final List<String> reasonOrder;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final palette = categorical(context);
    final counts = <String, int>{};
    for (final d in distractions) {
      counts[d.reason] = (counts[d.reason] ?? 0) + 1;
    }
    // Color follows the reason's configured order (identity), not its rank. Beyond 7, fold into "Other reasons".
    final ordered = [...reasonOrder.where(counts.containsKey), ...counts.keys.where((k) => !reasonOrder.contains(k))];
    final main = ordered.take(7).toList();
    final rest = ordered.skip(7).fold<int>(0, (a, k) => a + counts[k]!);
    int colorIndex(String k) {
      final i = reasonOrder.indexOf(k);
      return (i < 0 ? reasonOrder.length + ordered.indexOf(k) : i) % palette.length;
    }

    final items = [
      for (final k in main) (k, counts[k]!.toDouble(), palette[colorIndex(k)]),
      if (rest > 0) ('Other reasons', rest.toDouble(), p.muted),
    ];
    return ChartCard(
      title: 'Distractions by reason',
      subtitle: '${distractions.length} logged',
      child: distractions.isEmpty
          ? Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text('No distractions logged in this range.', textAlign: TextAlign.center, style: TextStyle(color: p.muted)))
          : DonutChart(items: items),
    );
  }
}

class _ByProject extends StatelessWidget {
  const _ByProject({required this.sessions, required this.tasks, required this.projects});
  final List<FocusSession> sessions;
  final List<TaskItem> tasks;
  final List<Project> projects;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final taskProject = {for (final t in tasks) t.id: t.projectId};
    final agg = <String, List<int>>{};
    for (final x in sessions) {
      final pid = (x.taskId == null ? null : taskProject[x.taskId]) ?? 'none';
      final v = agg.putIfAbsent(pid, () => [0, 0]);
      v[0]++;
      v[1] += x.actualDuration;
    }
    final rows = agg.entries.map((e) {
      final proj = projects.where((x) => x.id == e.key).firstOrNull;
      return (proj?.name ?? 'No project', proj == null ? p.muted : colorFromHex(proj.color), e.value[0], (e.value[1] / 360).round() / 10);
    }).toList()
      ..sort((a, b) => b.$3.compareTo(a.$3));
    final maxN = rows.fold<int>(1, (m, r) => math.max(m, r.$3));
    return ChartCard(
      title: 'Sessions by project',
      subtitle: pluralize(rows.length, 'project'),
      child: Column(children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(r.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                Text('${r.$3} · ${r.$4} h', style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: tabular)),
              ]),
              const SizedBox(height: 5),
              ProgressLine(value: r.$3 / maxN, color: r.$2, height: 8),
            ]),
          ),
      ]),
    );
  }
}

class _Heatmap extends StatefulWidget {
  const _Heatmap({required this.sessions});
  final List<FocusSession> sessions;
  @override
  State<_Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<_Heatmap> {
  (int, int)? hover;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final grid = heatmap(widget.sessions);
    final maxV = grid.expand((r) => r).fold<double>(1, math.max);
    final used = [for (var h = 0; h < 24; h++) grid.any((row) => row[h] > 0)];
    var first = used.indexOf(true), last = used.lastIndexOf(true);
    if (first < 0) {
      first = 8;
      last = 18;
    }
    first = math.min(first, 8);
    last = math.max(last, 18);
    final hours = [for (var h = first; h <= last; h++) h];
    const order = [1, 2, 3, 4, 5, 6, 0];
    Color cell(double v) => v <= 0 ? p.card2 : Color.lerp(p.card2, p.accent, 0.15 + 0.85 * (v / maxV))!;
    return ChartCard(
      title: 'Best hours',
      subtitle: hover == null ? 'Focus minutes by weekday and hour' : '${dayShort[hover!.$1]} ${formatHour(hover!.$2)}: ${grid[hover!.$1][hover!.$2].round()} focus minutes',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, cons) {
          final cellW = ((cons.maxWidth - 40) / hours.length).clamp(12.0, 40.0);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const SizedBox(width: 38),
                for (final h in hours)
                  SizedBox(width: cellW, child: Text(h % 3 == 0 ? formatHour(h).replaceAll(' ', '') : '', textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 9.5))),
              ]),
              const SizedBox(height: 4),
              for (final d in order)
                Row(children: [
                  SizedBox(width: 38, child: Text(dayShort[d], style: TextStyle(color: p.muted, fontSize: 11))),
                  for (final h in hours)
                    GestureDetector(
                      onTap: () => setState(() => hover = (d, h)),
                      child: Container(
                        width: cellW - 3,
                        height: 22,
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: cell(grid[d][h]),
                          borderRadius: BorderRadius.circular(4),
                          border: hover == (d, h) ? Border.all(color: p.fg, width: 1.5) : null,
                        ),
                      ),
                    ),
                ]),
            ]),
          );
        }),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Less', style: TextStyle(color: p.muted, fontSize: 11)),
          for (final t in [0.15, 0.4, 0.65, 1.0]) Container(width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: Color.lerp(p.card2, p.accent, t), borderRadius: BorderRadius.circular(3))),
          Text('More', style: TextStyle(color: p.muted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

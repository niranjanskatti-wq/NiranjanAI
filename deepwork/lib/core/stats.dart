// On-device, rule-based statistics. No network, no AI — arithmetic over local records.
import 'dart:math' as math;

import '../data/database.dart';
import 'settings.dart';
import 'util/format.dart';

bool counted(FocusSession s) => s.result != 'interrupted';

class DayStats {
  int focusSec = 0;
  int sessions = 0; // completed (non-interrupted)
  int allSessions = 0;
  int tasksDone = 0;
  int distractions = 0;
}

final emptyDay = DayStats();

Map<String, DayStats> buildDayIndex(List<FocusSession> sessions, List<TaskItem> tasks, List<Distraction> distractions) {
  final map = <String, DayStats>{};
  DayStats get(String k) => map.putIfAbsent(k, DayStats.new);
  for (final s in sessions) {
    final d = get(dateKeyMs(s.startedAt));
    d.focusSec += s.actualDuration;
    d.allSessions++;
    if (counted(s)) d.sessions++;
  }
  for (final t in tasks) {
    if (t.status == 'done' && t.completedAt != null) get(dateKeyMs(t.completedAt!)).tasksDone++;
  }
  for (final x in distractions) {
    get(dateKeyMs(x.timestamp)).distractions++;
  }
  return map;
}

class GoalProgress {
  GoalProgress(this.value, this.target, this.unit);
  final int value, target;
  final String unit;
  double get ratio => target > 0 ? math.min(1, value / target) : 0;
}

GoalProgress goalProgress(AppSettings s, DayStats day) {
  final type = s.s('dailyGoal.type');
  final target = s.i('dailyGoal.target');
  final value = type == 'minutes' ? (day.focusSec / 60).round() : type == 'sessions' ? day.sessions : day.tasksDone;
  final unit = type == 'minutes' ? 'min' : type;
  return GoalProgress(value, target, unit);
}

// ---------------------------------------------------------------- streaks

bool dayQualifies(AppSettings s, DayStats? d) {
  if (d == null) return false;
  final amount = math.max(1, s.i('streaks.amount'));
  return switch (s.s('streaks.countsAs')) {
    'session' => d.sessions >= amount,
    'minutes' => d.focusSec / 60 >= amount,
    _ => d.tasksDone >= amount,
  };
}

String streakRuleLabel(AppSettings s) {
  final amount = math.max(1, s.i('streaks.amount'));
  final unit = switch (s.s('streaks.countsAs')) {
    'session' => pluralize(amount, 'session'),
    'minutes' => '$amount focus minutes',
    _ => pluralize(amount, 'task'),
  };
  final rule = switch (s.s('streaks.rule')) { 'strict' => 'every day', 'weekdays' => 'every weekday', _ => 'never missing twice' };
  return '$unit, $rule';
}

class StreakInfo {
  const StreakInfo(this.current, this.best, this.todayDone, this.atRisk);
  final int current, best;
  final bool todayDone, atRisk;
}

StreakInfo computeStreak(AppSettings s, Map<String, DayStats> index, [DateTime? today]) {
  final todayStart = startOfDay(today ?? DateTime.now());
  if (index.isEmpty) return const StreakInfo(0, 0, false, false);
  final first = parseDateKey((index.keys.toList()..sort()).first);
  final days = math.max(0, todayStart.difference(first).inDays);
  final rule = s.s('streaks.rule');
  var cur = 0, misses = 0, best = 0, prev = 0, prevMisses = 0;
  var todayQ = false;
  for (var i = 0; i <= days; i++) {
    final d = addDays(first, i);
    final q = dayQualifies(s, index[dateKey(d)]);
    prev = cur;
    prevMisses = misses;
    if (q) {
      cur++;
      misses = 0;
    } else if (rule == 'weekdays' && isWeekend(d)) {
      // weekends neither count nor break the streak
    } else if (rule == 'neverMissTwice') {
      misses++;
      if (misses >= 2) cur = 0;
    } else {
      cur = 0;
    }
    if (i == days) todayQ = q;
    best = math.max(best, cur);
  }
  // Today is still in progress: until it qualifies, the streak stands at yesterday's value.
  final current = todayQ ? cur : prev;
  final atRisk = rule == 'neverMissTwice' && !todayQ && prevMisses == 1 && current > 0;
  return StreakInfo(current, best, todayQ, atRisk);
}

// ---------------------------------------------------------------- planned vs done

List<TaskItem> plannedTasksForDay(String day, List<TaskItem> tasks, List<TimeBlock> blocks) {
  final ids = <String>{
    for (final t in tasks)
      if (t.isPriority && t.priorityDate == day) t.id,
    for (final b in blocks)
      if (b.date == day && b.taskId != null) b.taskId!,
  };
  return tasks.where((t) => ids.contains(t.id)).toList();
}

class PlannedVsDone {
  PlannedVsDone(this.planned, this.done, this.unplannedDone);
  final List<TaskItem> planned, done, unplannedDone;
}

PlannedVsDone plannedVsDone(String day, List<TaskItem> tasks, List<TimeBlock> blocks) {
  final planned = plannedTasksForDay(day, tasks, blocks);
  final ids = planned.map((t) => t.id).toSet();
  return PlannedVsDone(
    planned,
    planned.where((t) => t.status == 'done').toList(),
    tasks.where((t) => t.status == 'done' && t.completedAt != null && dateKeyMs(t.completedAt!) == day && !ids.contains(t.id)).toList(),
  );
}

// ---------------------------------------------------------------- best focus time

class BestTime {
  const BestTime(this.startHour, this.endHour, this.rate, this.count);
  final int startHour, endHour, count;
  final double rate;
  String get label => '${formatHour(startHour)} – ${formatHour(endHour % 24)}';
}

const bestTimeMinSessions = 8;
const bestTimeMinBucket = 3;

/// Two-hour window with the highest completion rate over the last 14 days.
BestTime? bestFocusTime(List<FocusSession> sessions, {DateTime? now, int days = 14}) {
  final since = startOfDay(addDays(now ?? DateTime.now(), -(days - 1))).millisecondsSinceEpoch;
  final recent = sessions.where((s) => s.startedAt >= since).toList();
  if (recent.length < bestTimeMinSessions) return null;
  final buckets = <int, List<int>>{}; // hour -> [done, total]
  for (final s in recent) {
    final b = (DateTime.fromMillisecondsSinceEpoch(s.startedAt).hour ~/ 2) * 2;
    final v = buckets.putIfAbsent(b, () => [0, 0]);
    v[1]++;
    if (s.result == 'done') v[0]++;
  }
  BestTime? best;
  for (final e in buckets.entries) {
    if (e.value[1] < bestTimeMinBucket) continue;
    final rate = e.value[0] / e.value[1];
    if (best == null || rate > best.rate || (rate == best.rate && e.value[1] > best.count)) {
      best = BestTime(e.key, e.key + 2, rate, e.value[1]);
    }
  }
  return best;
}

// ---------------------------------------------------------------- ranges

int rangeStart(int range, [DateTime? now]) => range == 0 ? 0 : startOfDay(addDays(now ?? DateTime.now(), -(range - 1))).millisecondsSinceEpoch;

List<DateTime> rangeDays(int range, List<FocusSession> sessions, [DateTime? now]) {
  final n = now ?? DateTime.now();
  if (range > 0) return lastNDays(range, n);
  final first = sessions.fold<int>(n.millisecondsSinceEpoch, (m, s) => math.min(m, s.startedAt));
  final count = (startOfDay(n).difference(startOfDay(DateTime.fromMillisecondsSinceEpoch(first))).inDays + 1).clamp(7, 730);
  return lastNDays(count, n);
}

double? completionRate(List<FocusSession> list) => list.isEmpty ? null : list.where((s) => s.result == 'done').length / list.length;

/// Focus minutes per weekday (Sunday = 0) × hour, spreading each session over the hours it spanned.
List<List<double>> heatmap(List<FocusSession> sessions) {
  final grid = List.generate(7, (_) => List<double>.filled(24, 0));
  for (final s in sessions) {
    var t = s.startedAt;
    final end = s.startedAt + s.actualDuration * 1000;
    var guard = 0;
    while (t < end && guard++ < 48) {
      final d = DateTime.fromMillisecondsSinceEpoch(t);
      final hourEnd = DateTime(d.year, d.month, d.day, d.hour + 1).millisecondsSinceEpoch;
      final chunk = math.min(end, hourEnd) - t;
      grid[weekday0(d)][d.hour] += chunk / 60000;
      t += chunk;
    }
  }
  return grid;
}

// ---------------------------------------------------------------- insight cards

enum Tone { neutral, positive, attention }

class InsightCard {
  const InsightCard(this.id, this.title, this.body, this.tone);
  final String id, title, body;
  final Tone tone;
}

const _periods = <(String, bool Function(int))>[
  ('before 10 am', _before10),
  ('between 10 am and noon', _morning),
  ('between noon and 3 pm', _midday),
  ('after 3 pm', _after3),
];
bool _before10(int h) => h < 10;
bool _morning(int h) => h >= 10 && h < 12;
bool _midday(int h) => h >= 12 && h < 15;
bool _after3(int h) => h >= 15;

List<InsightCard> computeInsightCards({
  required AppSettings settings,
  required List<FocusSession> sessions, // filtered to range
  required List<FocusSession> allSessions,
  required List<Distraction> distractions, // filtered to range
  required List<TaskItem> tasks,
  required List<Project> projects,
  required int range,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final cards = <InsightCard>[];
  final enabled = settings.strings('insights.cards').toSet();
  bool mod(String m) => settings.on(m);

  // When do interruptions happen?
  if (enabled.contains('interruptionTime') && mod('distractions') && distractions.length >= 5) {
    final counts = [for (final p in _periods) distractions.where((d) => p.$2(DateTime.fromMillisecondsSinceEpoch(d.timestamp).hour)).length];
    final mx = counts.reduce(math.max);
    final idx = counts.indexOf(mx);
    final share = mx / distractions.length;
    if (share >= 0.4) {
      cards.add(InsightCard(
        'interruptionTime',
        'Most interruptions happen ${_periods[idx].$1}.',
        '${(share * 100).round()}% of ${distractions.length} logged distractions. Consider protecting that window or scheduling lighter work there.',
        Tone.attention,
      ));
    }
  }

  // Which session length finishes best?
  if (enabled.contains('bestLength')) {
    final byLen = <int, List<FocusSession>>{};
    for (final s in sessions) {
      byLen.putIfAbsent((s.plannedDuration / 60).round(), () => []).add(s);
    }
    final eligible = byLen.entries.where((e) => e.value.length >= 3).toList();
    if (eligible.length >= 2) {
      final ranked = eligible.map((e) => (m: e.key, rate: completionRate(e.value)!, n: e.value.length)).toList()
        ..sort((a, b) => b.rate.compareTo(a.rate) != 0 ? b.rate.compareTo(a.rate) : b.n.compareTo(a.n));
      final top = ranked.first, low = ranked.last;
      cards.add(InsightCard(
        'bestLength',
        'Your ${top.m}-minute sessions have the highest completion rate.',
        '${(top.rate * 100).round()}% marked done across ${top.n} sessions, compared with ${(low.rate * 100).round()}% for ${low.m}-minute sessions.',
        Tone.positive,
      ));
    }
  }

  // Planned priorities finished
  if (enabled.contains('priorityCompletion') && mod('priorities')) {
    final start = dateKey(DateTime.fromMillisecondsSinceEpoch(rangeStart(range, n)));
    final end = dateKey(n);
    final planned = tasks.where((t) => t.isPriority && t.priorityDate != null && t.priorityDate!.compareTo(start) >= 0 && t.priorityDate!.compareTo(end) <= 0).toList();
    if (planned.length >= 3) {
      final done = planned.where((t) => t.status == 'done').length;
      final pct = (done / planned.length * 100).round();
      final when = range == 7 ? 'this week' : range == 0 ? 'overall' : 'in the last $range days';
      cards.add(InsightCard(
        'priorityCompletion',
        'You finished $pct% of planned priorities $when.',
        '$done of ${planned.length} priorities done.${pct < 60 ? ' Picking fewer priorities may help them actually get finished.' : ''}',
        pct >= 70 ? Tone.positive : Tone.neutral,
      ));
    }
  }

  // Top distraction
  if (enabled.contains('topDistraction') && mod('distractions') && distractions.length >= 3) {
    final counts = <String, int>{};
    for (final d in distractions) {
      counts[d.reason] = (counts[d.reason] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    final perSession = sessions.isEmpty ? 0 : distractions.length / sessions.length;
    cards.add(InsightCard(
      'topDistraction',
      '${top.key} is your most common distraction.',
      '${(top.value / distractions.length * 100).round()}% of distractions. You average ${perSession.toStringAsFixed(1)} distractions per session.',
      Tone.attention,
    ));
  }

  // Best weekday
  if (enabled.contains('bestDay') && sessions.length >= 7) {
    final totals = List<double>.filled(7, 0);
    final seen = List.generate(7, (_) => <String>{});
    for (final s in sessions) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
      totals[weekday0(d)] += s.actualDuration.toDouble();
      seen[weekday0(d)].add(dateKey(d));
    }
    final avg = [for (var i = 0; i < 7; i++) seen[i].isEmpty ? 0.0 : totals[i] / seen[i].length];
    final best = avg.indexOf(avg.reduce(math.max));
    if (avg[best] > 0) {
      cards.add(InsightCard('bestDay', '${dayNames[best]}s are your most focused day.', 'You average ${(avg[best] / 60).round()} focus minutes on ${dayNames[best]}s.', Tone.positive));
    }
  }

  // Trend: last 7 days vs previous 7
  if (enabled.contains('trend')) {
    final thisStart = rangeStart(7, n);
    final prevStart = thisStart - 7 * 86400000;
    final cur = allSessions.where((s) => s.startedAt >= thisStart).fold<int>(0, (a, s) => a + s.actualDuration);
    final prev = allSessions.where((s) => s.startedAt >= prevStart && s.startedAt < thisStart).fold<int>(0, (a, s) => a + s.actualDuration);
    if (prev >= 1800 && cur > 0) {
      final change = (cur - prev) / prev;
      final pct = (change.abs() * 100).round();
      cards.add(InsightCard(
        'trend',
        pct < 5 ? 'Your focus time is steady compared with last week.' : 'Focus time is ${change > 0 ? 'up' : 'down'} $pct% compared with the previous 7 days.',
        '${(cur / 360).round() / 10} h in the last 7 days vs ${(prev / 360).round() / 10} h before.',
        change >= 0 ? Tone.positive : Tone.neutral,
      ));
    }
  }

  // Best focus time
  if (enabled.contains('bestTime')) {
    final b = bestFocusTime(allSessions, now: n);
    if (b != null) {
      cards.add(InsightCard('bestTime', 'Your best focus window is ${b.label}.', '${(b.rate * 100).round()}% of ${b.count} sessions started then were marked done (last 14 days).', Tone.positive));
    }
  }

  // Stuck by project
  if (enabled.contains('stuckProject') && mod('tasks')) {
    final taskProject = {for (final t in tasks) t.id: t.projectId};
    final stuck = <String, List<int>>{};
    for (final s in sessions) {
      final pid = s.taskId == null ? null : taskProject[s.taskId];
      if (pid == null) continue;
      final v = stuck.putIfAbsent(pid, () => [0, 0]);
      v[1]++;
      if (s.result == 'stuck') v[0]++;
    }
    final candidates = stuck.entries.where((e) => e.value[1] >= 4 && e.value[0] >= 2).toList()
      ..sort((a, b) => (b.value[0] / b.value[1]).compareTo(a.value[0] / a.value[1]));
    if (candidates.isNotEmpty) {
      final worst = candidates.first;
      final p = projects.where((x) => x.id == worst.key).firstOrNull;
      if (p != null) {
        cards.add(InsightCard(
          'stuckProject',
          'You get stuck most often on ${p.name}.',
          '${worst.value[0]} of ${worst.value[1]} sessions ended stuck. Breaking those tasks into smaller next steps may help.',
          Tone.attention,
        ));
      }
    }
  }
  return cards;
}

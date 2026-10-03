import 'package:deepwork/core/settings.dart';
import 'package:deepwork/core/stats.dart';
import 'package:deepwork/core/util/format.dart';
import 'package:deepwork/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final today = DateTime(2026, 10, 7, 18); // a Wednesday
  DateTime day(int ago, [int hour = 10]) => DateTime(today.year, today.month, today.day - ago, hour);

  group('streaks', () {
    final s = AppSettings.defaults();

    test('strict: consecutive days ending yesterday while today is in progress', () {
      final idx = buildDayIndex([for (final a in [1, 2, 3]) session(day(a))], [], []);
      final info = computeStreak(s.set('streaks.rule', 'strict'), idx, today);
      expect(info.current, 3);
      expect(info.todayDone, isFalse);
    });

    test('strict: a missed day resets', () {
      final idx = buildDayIndex([for (final a in [0, 1, 3, 4, 5]) session(day(a))], [], []);
      final info = computeStreak(s.set('streaks.rule', 'strict'), idx, today);
      expect(info.current, 2);
      expect(info.best, 3);
    });

    test('never miss twice: one gap is forgiven, two in a row reset', () {
      final idx = buildDayIndex([for (final a in [0, 2, 3, 6, 7]) session(day(a))], [], []);
      final info = computeStreak(s.set('streaks.rule', 'neverMissTwice'), idx, today);
      expect(info.current, 3); // days 3,2,0 (gap on day 1 forgiven); days 4-5 missed twice
    });

    test('never miss twice: at risk after missing yesterday', () {
      final idx = buildDayIndex([session(day(2)), session(day(3))], [], []);
      final info = computeStreak(s.set('streaks.rule', 'neverMissTwice'), idx, today);
      expect(info.current, 2);
      expect(info.atRisk, isTrue);
    });

    test('weekdays only: weekends neither count nor break', () {
      // today is Wednesday; Mon/Tue + previous Thu/Fri done, weekend empty.
      final idx = buildDayIndex([for (final a in [1, 2, 5, 6]) session(day(a))], [], []);
      final info = computeStreak(s.set('streaks.rule', 'weekdays'), idx, today);
      expect(info.current, 4);
    });

    test('counts as minutes / tasks', () {
      final idx = buildDayIndex([session(day(1), minutes: 30), session(day(2), minutes: 90)], [], []);
      final m = s.set('streaks.rule', 'strict').set('streaks.countsAs', 'minutes').set('streaks.amount', 60);
      expect(computeStreak(m, idx, today).current, 0);
      expect(computeStreak(m, idx, today).best, 1);
      final t = buildDayIndex([], [task('a', status: 'done', completedAt: day(1).millisecondsSinceEpoch)], []);
      expect(computeStreak(s.set('streaks.rule', 'strict').set('streaks.countsAs', 'tasks'), t, today).current, 1);
    });

    test('interrupted sessions do not count as a session', () {
      final idx = buildDayIndex([session(day(1), result: 'interrupted')], [], []);
      expect(computeStreak(s.set('streaks.rule', 'strict'), idx, today).current, 0);
    });
  });

  test('daily goal progress', () {
    final idx = buildDayIndex([session(day(0), minutes: 60), session(day(0), minutes: 30, result: 'interrupted')], [], []);
    final g = goalProgress(AppSettings.defaults(), idx[dateKey(today)]!);
    expect(g.value, 90);
    expect(g.target, 120);
    expect(g.ratio, closeTo(0.75, 0.001));
  });

  test('planned vs done includes priorities and time-blocked tasks', () {
    final key = dateKey(today);
    final tasks = [
      task('p1', prio: true, prioDate: key, status: 'done', completedAt: today.millisecondsSinceEpoch),
      task('p2', prio: true, prioDate: key),
      task('b1'),
      task('x', status: 'done', completedAt: today.millisecondsSinceEpoch),
    ];
    final blocks = [TimeBlock(id: 'b', date: key, startTime: '09:00', endTime: '10:00', taskId: 'b1', label: '', isDemo: false)];
    final r = plannedVsDone(key, tasks, blocks);
    expect(r.planned.map((t) => t.id), containsAll(['p1', 'p2', 'b1']));
    expect(r.done.map((t) => t.id), ['p1']);
    expect(r.unplannedDone.map((t) => t.id), ['x']);
  });

  test('best focus time needs enough data, then picks the best 2-hour window', () {
    expect(bestFocusTime([session(day(1, 9))], now: today), isNull);
    final list = [
      for (var i = 0; i < 4; i++) session(day(i + 1, 9), result: 'done'),
      for (var i = 0; i < 4; i++) session(day(i + 1, 15), result: i == 0 ? 'done' : 'partly'),
    ];
    final b = bestFocusTime(list, now: today)!;
    expect(b.startHour, 8);
    expect(b.rate, 1.0);
    expect(b.label, '8 am – 10 am');
  });

  test('insight cards: best session length and top distraction', () {
    final sessions = [
      for (var i = 0; i < 4; i++) session(day(i, 9), minutes: 45),
      for (var i = 0; i < 4; i++) session(day(i, 11), minutes: 90, result: 'partly'),
    ];
    final distractions = [
      for (var i = 0; i < 5; i++) Distraction(id: 'd$i', sessionId: 'x', timestamp: day(1, 16).millisecondsSinceEpoch, reason: i < 4 ? 'Phone' : 'Noise', note: '', isDemo: false),
    ];
    final cards = computeInsightCards(settings: AppSettings.defaults(), sessions: sessions, allSessions: sessions, distractions: distractions, tasks: const [], projects: const [], range: 14, now: today);
    final ids = cards.map((c) => c.id).toList();
    expect(ids, contains('bestLength'));
    expect(cards.firstWhere((c) => c.id == 'bestLength').title, contains('45-minute'));
    expect(cards.firstWhere((c) => c.id == 'topDistraction').title, startsWith('Phone'));
    expect(cards.firstWhere((c) => c.id == 'interruptionTime').title, contains('after 3 pm'));
  });

  test('heatmap spreads a session across the hours it spans', () {
    final grid = heatmap([session(DateTime(2026, 10, 7, 9, 30), minutes: 60)]);
    expect(grid[3][9], closeTo(30, 0.01));
    expect(grid[3][10], closeTo(30, 0.01));
  });
}

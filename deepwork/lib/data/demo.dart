// Demo data to preview Insights. Every record has isDemo = true and can be cleared without touching
// your own data.
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../core/util/format.dart';
import 'database.dart';
import 'repository.dart';

const _projects = [('Thesis', '#7C7CFF'), ('Client work', '#22C3A6'), ('Learning', '#F59E0B'), ('Admin', '#F472B6')];
const _titles = {
  'Thesis': ['Draft chapter 3 methods', 'Revise literature review', 'Clean experiment data', 'Write results section', 'Make figures for chapter 4', 'Outline discussion'],
  'Client work': ['Homepage redesign', 'Fix checkout bug', 'Write API docs', 'Prepare sprint demo', 'Refactor auth flow', 'Review pull requests'],
  'Learning': ['Rust ownership chapter', 'Statistics course week 4', 'Read "Deep Work" ch. 2', 'Practice SQL window functions'],
  'Admin': ['Tax paperwork', 'Plan next week', 'Inbox zero', 'Update invoices'],
};

Future<int> loadDemoData(AppDatabase db) async {
  await clearDemoData(db);
  final r = Random(42);
  final now = DateTime.now();
  final today = startOfDay(now);
  final reasonsRows = await (db.select(db.distractionReasons)..orderBy([(t) => OrderingTerm.asc(t.sort)])).get();
  final reasons = reasonsRows.isEmpty ? defaultReasons : reasonsRows.map((e) => e.label).toList();
  const weights = [0.38, 0.18, 0.12, 0.14, 0.12, 0.06];

  final projectCount = (await db.select(db.projects).get()).length;
  final projects = [
    for (var i = 0; i < _projects.length; i++) Project(id: newId(), name: _projects[i].$1, color: _projects[i].$2, sort: projectCount + i, isDemo: true),
  ];
  var order = (await db.select(db.tasks).get()).length + 1;
  final tasks = <TaskItem>[];
  for (final p in projects) {
    for (final title in _titles[p.name]!) {
      tasks.add(TaskItem(
        id: newId(),
        title: title,
        projectId: p.id,
        estimateSessions: 1 + r.nextInt(5),
        dueDate: r.nextDouble() < 0.4 ? dateKey(addDays(today, r.nextInt(14) - 3)) : null,
        status: 'todo',
        flagged: r.nextDouble() < 0.2,
        isPriority: false,
        priorityDate: null,
        priorityOrder: 0,
        sort: order++,
        createdAt: addDays(today, -r.nextInt(50) - 10).millisecondsSinceEpoch,
        completedAt: null,
        isDemo: true,
      ));
    }
  }
  final subtasks = <Subtask>[
    for (final t in tasks.take(8))
      for (var i = 0; i < 2 + r.nextInt(3); i++) Subtask(id: newId(), taskId: t.id, title: 'Step ${i + 1}', done: r.nextBool(), sort: i, isDemo: true),
  ];

  final sessions = <FocusSession>[];
  final distractions = <Distraction>[];
  final reviews = <Review>[];
  final blocks = <TimeBlock>[];
  const durations = [25, 25, 45, 45, 60, 90, 15];

  for (var d = 59; d >= 0; d--) {
    final day = addDays(today, -d);
    if (isWeekend(day) && r.nextDouble() < 0.6) continue;
    if (r.nextDouble() < 0.08) continue;
    final count = d == 0 ? min(2, now.hour ~/ 5) : 2 + r.nextInt(4);
    var cursor = 8 * 60 + r.nextInt(90);
    final key = dateKey(day);
    // Keep enough open tasks around as demo work gets finished.
    if (tasks.where((t) => t.status != 'done').length < 8) {
      for (final t in tasks.where((t) => t.status == 'done').take(6).toList()) {
        tasks.add(t.copyWith(id: newId(), title: '${t.title.replaceAll(RegExp(r' \(part \d+\)$'), '')} (part ${2 + r.nextInt(3)})', status: 'todo', completedAt: const Value(null), isPriority: false, priorityDate: const Value(null), sort: order++));
      }
    }
    final open = tasks.where((t) => t.status != 'done').toList()..shuffle(r);
    final prios = open.take(3).toList();
    for (var i = 0; i < prios.length; i++) {
      final idx = tasks.indexWhere((t) => t.id == prios[i].id);
      tasks[idx] = tasks[idx].copyWith(isPriority: true, priorityDate: Value(key), priorityOrder: i);
    }
    for (var i = 0; i < count; i++) {
      final planned = durations[r.nextInt(durations.length)];
      final start = DateTime(day.year, day.month, day.day, 0, cursor);
      if (start.isAfter(now.subtract(Duration(minutes: planned)))) break;
      final taskIndex = r.nextDouble() < 0.9 ? (prios.isEmpty ? r.nextInt(tasks.length) : tasks.indexWhere((t) => t.id == prios[r.nextInt(prios.length)].id)) : -1;
      final afternoon = start.hour >= 15;
      final roll = r.nextDouble();
      final bonus = planned == 45 ? 0.18 : planned == 90 ? -0.15 : 0.0;
      final result = roll < (afternoon ? 0.2 : 0.08)
          ? 'interrupted'
          : roll < 0.62 + bonus
              ? 'done'
              : roll < 0.86
                  ? 'partly'
                  : 'stuck';
      final actual = result == 'interrupted' ? max(3, (planned * (0.2 + r.nextDouble() * 0.6)).floor()) : planned;
      final sid = newId();
      sessions.add(FocusSession(
        id: sid,
        taskId: taskIndex >= 0 ? tasks[taskIndex].id : null,
        plannedDuration: planned * 60,
        actualDuration: actual * 60,
        startedAt: start.millisecondsSinceEpoch,
        endedAt: start.millisecondsSinceEpoch + actual * 60000,
        result: result,
        note: result == 'done' ? 'Finished the planned chunk.' : result == 'stuck' ? 'Unsure how to structure the next part.' : '',
        isDemo: true,
      ));
      final nd = (r.nextDouble() * (afternoon ? 4 : 2.2)).floor();
      for (var k = 0; k < nd; k++) {
        var x = r.nextDouble();
        var idx = 0;
        while (idx < weights.length - 1 && x > weights[idx]) {
          x -= weights[idx++];
        }
        distractions.add(Distraction(
          id: newId(),
          sessionId: sid,
          timestamp: start.millisecondsSinceEpoch + r.nextInt(actual * 60000),
          reason: reasons[min(idx, reasons.length - 1)],
          note: '',
          isDemo: true,
        ));
      }
      final isPrio = taskIndex >= 0 && prios.any((x) => x.id == tasks[taskIndex].id);
      if (taskIndex >= 0 && result == 'done' && r.nextDouble() < (isPrio ? 0.45 : 0.1) && tasks[taskIndex].status != 'done') {
        tasks[taskIndex] = tasks[taskIndex].copyWith(status: 'done', completedAt: Value(start.millisecondsSinceEpoch + actual * 60000));
      }
      cursor += actual + 10 + r.nextInt(50);
      if (i == 1) cursor += 45;
    }
    if (d == 0) {
      for (var i = 0; i < prios.length; i++) {
        final h = 9 + i * 2;
        blocks.add(TimeBlock(id: newId(), date: key, startTime: minutesToTime(h * 60), endTime: minutesToTime((h + 1) * 60), taskId: prios[i].id, label: '', isDemo: true));
      }
    }
    if (d > 0 && r.nextDouble() < 0.6) {
      const answers = ['Start with the hardest task.', 'Phone in another room.', 'Smaller first step.', 'Block the afternoon.'];
      reviews.add(Review(
        id: newId(),
        type: 'daily',
        date: key,
        answers: jsonEncode([
          {'question': 'One thing to do differently tomorrow?', 'answer': answers[r.nextInt(4)]},
        ]),
        nextPriorities: '[]',
        stats: '{}',
        createdAt: day.add(const Duration(hours: 20)).millisecondsSinceEpoch,
        isDemo: true,
      ));
    }
    if (d > 0 && day.weekday == DateTime.sunday) {
      reviews.add(Review(
        id: newId(),
        type: 'weekly',
        date: key,
        answers: jsonEncode([
          {'question': 'What went well?', 'answer': 'Mornings were consistently productive.'},
          {'question': 'What should I cut?', 'answer': 'Late-afternoon meetings.'},
          {'question': 'Top 3 priorities for next week?', 'answer': 'Chapter 3, sprint demo, invoices.'},
        ]),
        nextPriorities: '[]',
        stats: '{}',
        createdAt: day.add(const Duration(hours: 17)).millisecondsSinceEpoch,
        isDemo: true,
      ));
    }
  }

  await db.batch((b) {
    b.insertAll(db.projects, projects);
    b.insertAll(db.tasks, tasks);
    b.insertAll(db.subtasks, subtasks);
    b.insertAll(db.sessions, sessions);
    b.insertAll(db.distractions, distractions);
    b.insertAll(db.reviews, reviews);
    b.insertAll(db.timeBlocks, blocks);
  });
  return sessions.length;
}

Future<void> clearDemoData(AppDatabase db) => db.transaction(() async {
      await (db.delete(db.projects)..where((t) => t.isDemo.equals(true))).go();
      await (db.delete(db.tasks)..where((t) => t.isDemo.equals(true))).go();
      await (db.delete(db.subtasks)..where((t) => t.isDemo.equals(true))).go();
      await (db.delete(db.sessions)..where((t) => t.isDemo.equals(true))).go();
      await (db.delete(db.distractions)..where((t) => t.isDemo.equals(true))).go();
      await (db.delete(db.reviews)..where((t) => t.isDemo.equals(true))).go();
      await (db.delete(db.timeBlocks)..where((t) => t.isDemo.equals(true))).go();
    });

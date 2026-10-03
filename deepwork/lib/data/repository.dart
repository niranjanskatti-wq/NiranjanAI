import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/util/format.dart';
import 'database.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

const defaultReasons = ['Phone', 'Person', 'Noise', 'Boredom', 'Unclear task', 'Other'];
const defaultProjects = [('Work', '#7C7CFF'), ('Personal', '#4ADE80')];

/// All writes to the database go through here.
class Repository {
  Repository(this.db);
  final AppDatabase db;

  Future<void> seedDefaults() async {
    await db.transaction(() async {
      if (await db.getValue('seeded') != null) return;
      if ((await db.select(db.distractionReasons).get()).isEmpty) {
        await db.batch((b) => b.insertAll(db.distractionReasons, [
              for (var i = 0; i < defaultReasons.length; i++) DistractionReasonsCompanion.insert(id: newId(), label: defaultReasons[i], sort: Value(i)),
            ]));
      }
      if ((await db.select(db.projects).get()).isEmpty) {
        await db.batch((b) => b.insertAll(db.projects, [
              for (var i = 0; i < defaultProjects.length; i++)
                ProjectsCompanion.insert(id: newId(), name: defaultProjects[i].$1, color: defaultProjects[i].$2, sort: Value(i)),
            ]));
      }
      await db.setValue('seeded', '1');
    });
  }

  // ------------------------------------------------------------------ tasks
  Future<TaskItem> createTask({
    required String title,
    String? projectId,
    String? dueDate,
    bool isPriority = false,
    String? priorityDate,
    int priorityOrder = 0,
    int? estimate,
  }) async {
    final maxSort = await (db.selectOnly(db.tasks)..addColumns([db.tasks.sort.max()])).map((r) => r.read(db.tasks.sort.max())).getSingle();
    final t = TaskItem(
      id: newId(),
      title: title,
      projectId: projectId,
      estimateSessions: estimate,
      dueDate: dueDate,
      status: 'todo',
      flagged: false,
      isPriority: isPriority,
      priorityDate: priorityDate,
      priorityOrder: priorityOrder,
      sort: (maxSort ?? 0) + 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      completedAt: null,
      isDemo: false,
    );
    await db.into(db.tasks).insert(t);
    return t;
  }

  Future<void> updateTask(String id, TasksCompanion patch) => (db.update(db.tasks)..where((t) => t.id.equals(id))).write(patch);

  Future<void> setTaskDone(String id, bool done) => updateTask(
        id,
        TasksCompanion(status: Value(done ? 'done' : 'todo'), completedAt: Value(done ? DateTime.now().millisecondsSinceEpoch : null)),
      );

  Future<void> setTaskStatus(String id, String status) => updateTask(
        id,
        TasksCompanion(status: Value(status), completedAt: Value(status == 'done' ? DateTime.now().millisecondsSinceEpoch : null)),
      );

  Future<void> deleteTask(String id) => db.transaction(() async {
        await (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
        await (db.delete(db.subtasks)..where((t) => t.taskId.equals(id))).go();
        await (db.update(db.timeBlocks)..where((t) => t.taskId.equals(id))).write(const TimeBlocksCompanion(taskId: Value(null)));
        await (db.update(db.sessions)..where((t) => t.taskId.equals(id))).write(const SessionsCompanion(taskId: Value(null)));
      });

  Future<List<TaskItem>> prioritiesFor(String day) async {
    final list = await (db.select(db.tasks)..where((t) => t.priorityDate.equals(day) & t.isPriority.equals(true))).get();
    list.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
    return list;
  }

  /// Adds a task to a day's priorities. Returns false when the limit is reached.
  Future<bool> addToPriorities(String id, int limit, [String? day]) async {
    final d = day ?? todayKey();
    final current = await prioritiesFor(d);
    if (current.any((t) => t.id == id)) return true;
    if (current.length >= limit) return false;
    await updateTask(id, TasksCompanion(isPriority: const Value(true), priorityDate: Value(d), priorityOrder: Value(current.length)));
    return true;
  }

  Future<void> removeFromPriorities(String id) =>
      updateTask(id, const TasksCompanion(isPriority: Value(false), priorityDate: Value(null)));

  Future<void> reorderPriorities(List<String> ids) => db.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
          await updateTask(ids[i], TasksCompanion(priorityOrder: Value(i)));
        }
      });

  /// Sets exactly [ids] (in order) as the priorities for [day].
  Future<void> setPriorities(String day, List<String> ids) => db.transaction(() async {
        for (final t in await prioritiesFor(day)) {
          if (!ids.contains(t.id)) await removeFromPriorities(t.id);
        }
        for (var i = 0; i < ids.length; i++) {
          await updateTask(ids[i], TasksCompanion(isPriority: const Value(true), priorityDate: Value(day), priorityOrder: Value(i)));
        }
      });

  // ------------------------------------------------------------------ subtasks
  Future<void> addSubtask(String taskId, String title) async {
    final existing = await (db.select(db.subtasks)..where((s) => s.taskId.equals(taskId))).get();
    await db.into(db.subtasks).insert(SubtasksCompanion.insert(id: newId(), taskId: taskId, title: title, sort: Value(existing.length + 1)));
  }

  Future<void> updateSubtask(String id, SubtasksCompanion patch) => (db.update(db.subtasks)..where((s) => s.id.equals(id))).write(patch);
  Future<void> deleteSubtask(String id) => (db.delete(db.subtasks)..where((s) => s.id.equals(id))).go();
  Future<void> reorderSubtasks(List<String> ids) => db.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
          await updateSubtask(ids[i], SubtasksCompanion(sort: Value(i)));
        }
      });

  // ------------------------------------------------------------------ projects
  Future<void> addProject(String name, String color) async {
    final n = (await db.select(db.projects).get()).length;
    await db.into(db.projects).insert(ProjectsCompanion.insert(id: newId(), name: name, color: color, sort: Value(n + 1)));
  }

  Future<void> updateProject(String id, ProjectsCompanion patch) => (db.update(db.projects)..where((p) => p.id.equals(id))).write(patch);

  Future<void> deleteProject(String id) => db.transaction(() async {
        await (db.delete(db.projects)..where((p) => p.id.equals(id))).go();
        await (db.update(db.tasks)..where((t) => t.projectId.equals(id))).write(const TasksCompanion(projectId: Value(null)));
      });

  // ------------------------------------------------------------------ time blocks
  Future<void> createBlock(int startMin, int len, String? taskId, {String label = '', String? date}) =>
      db.into(db.timeBlocks).insert(TimeBlocksCompanion.insert(
            id: newId(),
            date: date ?? todayKey(),
            startTime: minutesToTime(startMin),
            endTime: minutesToTime(startMin + len),
            taskId: Value(taskId),
            label: Value(label),
          ));

  Future<void> moveBlock(String id, int startMin) async {
    final b = await (db.select(db.timeBlocks)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (b == null) return;
    final dur = (timeToMinutes(b.endTime) - timeToMinutes(b.startTime)).clamp(5, 1440);
    await updateBlock(id, TimeBlocksCompanion(startTime: Value(minutesToTime(startMin)), endTime: Value(minutesToTime(startMin + dur))));
  }

  Future<void> updateBlock(String id, TimeBlocksCompanion patch) => (db.update(db.timeBlocks)..where((t) => t.id.equals(id))).write(patch);
  Future<void> deleteBlock(String id) => (db.delete(db.timeBlocks)..where((t) => t.id.equals(id))).go();

  // ------------------------------------------------------------------ sessions & distractions
  Future<void> saveSession(FocusSession s) => db.into(db.sessions).insertOnConflictUpdate(s);

  Future<void> logDistraction(String sessionId, String reason, String note, [int? at]) => db.into(db.distractions).insert(
        DistractionsCompanion.insert(id: newId(), sessionId: sessionId, timestamp: at ?? DateTime.now().millisecondsSinceEpoch, reason: reason, note: Value(note)),
      );

  Future<void> deleteDistractionsFor(String sessionId) => (db.delete(db.distractions)..where((d) => d.sessionId.equals(sessionId))).go();

  Future<int> distractionCount(String sessionId) async =>
      (await (db.select(db.distractions)..where((d) => d.sessionId.equals(sessionId))).get()).length;

  // ------------------------------------------------------------------ distraction reasons
  Future<void> addReason(String label) async {
    final n = (await db.select(db.distractionReasons).get()).length;
    await db.into(db.distractionReasons).insert(DistractionReasonsCompanion.insert(id: newId(), label: label, sort: Value(n)));
  }

  Future<void> renameReason(String id, String label) =>
      (db.update(db.distractionReasons)..where((r) => r.id.equals(id))).write(DistractionReasonsCompanion(label: Value(label)));
  Future<void> deleteReason(String id) => (db.delete(db.distractionReasons)..where((r) => r.id.equals(id))).go();
  Future<void> reorderReasons(List<String> ids) => db.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
          await (db.update(db.distractionReasons)..where((r) => r.id.equals(ids[i]))).write(DistractionReasonsCompanion(sort: Value(i)));
        }
      });
  Future<void> resetReasons() => db.transaction(() async {
        await db.delete(db.distractionReasons).go();
        for (var i = 0; i < defaultReasons.length; i++) {
          await db.into(db.distractionReasons).insert(DistractionReasonsCompanion.insert(id: newId(), label: defaultReasons[i], sort: Value(i)));
        }
      });

  // ------------------------------------------------------------------ reviews
  Future<void> saveReview({
    String? id,
    required String type,
    required String date,
    required List<Map<String, String>> answers,
    List<Map<String, String>> nextPriorities = const [],
    Map<String, Object?> stats = const {},
    int? createdAt,
  }) =>
      db.into(db.reviews).insertOnConflictUpdate(Review(
            id: id ?? newId(),
            type: type,
            date: date,
            answers: jsonEncode(answers),
            nextPriorities: jsonEncode(nextPriorities),
            stats: jsonEncode(stats),
            createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
            isDemo: false,
          ));

  Future<void> deleteReview(String id) => (db.delete(db.reviews)..where((r) => r.id.equals(id))).go();
}

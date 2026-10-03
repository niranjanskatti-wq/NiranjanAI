import 'package:deepwork/data/database.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

FocusSession session(DateTime start, {int minutes = 25, String result = 'done', String? taskId, int? planned}) => FocusSession(
      id: '${start.millisecondsSinceEpoch}-$minutes-$result',
      taskId: taskId,
      plannedDuration: (planned ?? minutes) * 60,
      actualDuration: minutes * 60,
      startedAt: start.millisecondsSinceEpoch,
      endedAt: start.add(Duration(minutes: minutes)).millisecondsSinceEpoch,
      result: result,
      note: '',
      isDemo: false,
    );

TaskItem task(String id, {String status = 'todo', bool prio = false, String? prioDate, int? completedAt, String? projectId}) => TaskItem(
      id: id,
      title: 'Task $id',
      projectId: projectId,
      estimateSessions: null,
      dueDate: null,
      status: status,
      flagged: false,
      isPriority: prio,
      priorityDate: prioDate,
      priorityOrder: 0,
      sort: 0,
      createdAt: 0,
      completedAt: completedAt,
      isDemo: false,
    );

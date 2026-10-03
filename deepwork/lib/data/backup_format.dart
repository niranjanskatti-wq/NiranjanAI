// Full-data export / import and CSV export. The JSON format (with a schema version) is shared with
// Deepwork's earlier web version, so backups can be restored by either and migrated forward.
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../core/settings.dart';
import 'database.dart';
import 'repository.dart';

const schemaVersion = 1;
const dataTables = ['projects', 'tasks', 'subtasks', 'timeBlocks', 'sessions', 'distractions', 'distractionReasons', 'reviews'];
const tableLabels = {
  'projects': 'Projects',
  'tasks': 'Tasks',
  'subtasks': 'Subtasks',
  'timeBlocks': 'Time blocks',
  'sessions': 'Sessions',
  'distractions': 'Distractions',
  'distractionReasons': 'Distraction reasons',
  'reviews': 'Reviews',
};

class BackupFile {
  BackupFile(this.exportedAt, this.schema, this.data);
  final String exportedAt;
  final int schema;
  final Map<String, dynamic> data;

  Map<String, int> get counts => {for (final t in dataTables) t: (data[t] as List?)?.length ?? 0};
  DateTime? get exportedDate => DateTime.tryParse(exportedAt)?.toLocal();

  String encode() => jsonEncode({'app': 'deepwork', 'schema_version': schema, 'exported_at': exportedAt, 'data': data});
}

String backupFilename([DateTime? d]) => 'deepwork-backup-${DateFormat('yyyy-MM-dd').format(d ?? DateTime.now())}.json';

// ------------------------------------------------------------------ row <-> JSON
Map<String, dynamic> projectJson(Project p) => {'id': p.id, 'name': p.name, 'color': p.color, 'order': p.sort, 'is_demo': p.isDemo};
Map<String, dynamic> taskJson(TaskItem t) => {
      'id': t.id,
      'title': t.title,
      'project_id': t.projectId,
      'estimate_sessions': t.estimateSessions,
      'due_date': t.dueDate,
      'status': t.status,
      'flagged': t.flagged,
      'is_priority': t.isPriority,
      'priority_date': t.priorityDate,
      'priority_order': t.priorityOrder,
      'order': t.sort,
      'created_at': t.createdAt,
      'completed_at': t.completedAt,
      'is_demo': t.isDemo,
    };
Map<String, dynamic> subtaskJson(Subtask s) => {'id': s.id, 'task_id': s.taskId, 'title': s.title, 'done': s.done, 'order': s.sort, 'is_demo': s.isDemo};
Map<String, dynamic> blockJson(TimeBlock b) =>
    {'id': b.id, 'date': b.date, 'start_time': b.startTime, 'end_time': b.endTime, 'task_id': b.taskId, 'label': b.label, 'is_demo': b.isDemo};
Map<String, dynamic> sessionJson(FocusSession s) => {
      'id': s.id,
      'task_id': s.taskId,
      'planned_duration': s.plannedDuration,
      'actual_duration': s.actualDuration,
      'started_at': s.startedAt,
      'ended_at': s.endedAt,
      'result': s.result,
      'note': s.note,
      'is_demo': s.isDemo,
    };
Map<String, dynamic> distractionJson(Distraction d) =>
    {'id': d.id, 'session_id': d.sessionId, 'timestamp': d.timestamp, 'reason': d.reason, 'note': d.note, 'is_demo': d.isDemo};
Map<String, dynamic> reasonJson(DistractionReason r) => {'id': r.id, 'label': r.label, 'order': r.sort};
Map<String, dynamic> reviewJson(Review r) => {
      'id': r.id,
      'type': r.type,
      'date': r.date,
      'answers': jsonDecode(r.answers),
      'next_priorities': jsonDecode(r.nextPriorities),
      'stats': jsonDecode(r.stats),
      'created_at': r.createdAt,
      'is_demo': r.isDemo,
    };

int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
int? _in(Object? v) => v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
String? _sn(Object? v) => v == null ? null : '$v';
bool _b(Object? v) => v == true || v == 1 || v == 'true';

Project projectFrom(Map m) => Project(id: '${m['id']}', name: '${m['name'] ?? ''}', color: '${m['color'] ?? '#7C7CFF'}', sort: _i(m['order']), isDemo: _b(m['is_demo']));
TaskItem taskFrom(Map m) => TaskItem(
      id: '${m['id']}',
      title: '${m['title'] ?? ''}',
      projectId: _sn(m['project_id']),
      estimateSessions: _in(m['estimate_sessions']),
      dueDate: _sn(m['due_date']),
      status: '${m['status'] ?? 'todo'}',
      flagged: _b(m['flagged']),
      isPriority: _b(m['is_priority']),
      priorityDate: _sn(m['priority_date']),
      priorityOrder: _i(m['priority_order']),
      sort: _i(m['order']),
      createdAt: _i(m['created_at'], DateTime.now().millisecondsSinceEpoch),
      completedAt: _in(m['completed_at']),
      isDemo: _b(m['is_demo']),
    );
Subtask subtaskFrom(Map m) => Subtask(id: '${m['id']}', taskId: '${m['task_id']}', title: '${m['title'] ?? ''}', done: _b(m['done']), sort: _i(m['order']), isDemo: _b(m['is_demo']));
TimeBlock blockFrom(Map m) => TimeBlock(
      id: '${m['id']}',
      date: '${m['date']}',
      startTime: '${m['start_time']}',
      endTime: '${m['end_time']}',
      taskId: _sn(m['task_id']),
      label: '${m['label'] ?? ''}',
      isDemo: _b(m['is_demo']),
    );
FocusSession sessionFrom(Map m) => FocusSession(
      id: '${m['id']}',
      taskId: _sn(m['task_id']),
      plannedDuration: _i(m['planned_duration']),
      actualDuration: _i(m['actual_duration']),
      startedAt: _i(m['started_at']),
      endedAt: _i(m['ended_at']),
      result: '${m['result'] ?? 'done'}',
      note: '${m['note'] ?? ''}',
      isDemo: _b(m['is_demo']),
    );
Distraction distractionFrom(Map m) => Distraction(
      id: '${m['id']}',
      sessionId: '${m['session_id']}',
      timestamp: _i(m['timestamp']),
      reason: '${m['reason'] ?? 'Other'}',
      note: '${m['note'] ?? ''}',
      isDemo: _b(m['is_demo']),
    );
DistractionReason reasonFrom(Map m) => DistractionReason(id: '${m['id']}', label: '${m['label'] ?? ''}', sort: _i(m['order']));
Review reviewFrom(Map m) => Review(
      id: '${m['id']}',
      type: '${m['type'] ?? 'daily'}',
      date: '${m['date']}',
      answers: jsonEncode(m['answers'] ?? []),
      nextPriorities: jsonEncode(m['next_priorities'] ?? []),
      stats: jsonEncode(m['stats'] ?? {}),
      createdAt: _i(m['created_at']),
      isDemo: _b(m['is_demo']),
    );

/// Settings without device-specific secrets (PIN hash, Drive state).
Map<String, dynamic> portableSettings(AppSettings s) {
  final copy = Map<String, dynamic>.from(deepCopy(s.json) as Map);
  copy.remove('lock');
  copy.remove('backup');
  copy.remove('demoLoaded');
  return copy;
}

Future<BackupFile> buildBackup(AppDatabase db, AppSettings settings) async {
  final data = <String, dynamic>{
    'settings': portableSettings(settings),
    'projects': (await db.select(db.projects).get()).map(projectJson).toList(),
    'tasks': (await db.select(db.tasks).get()).map(taskJson).toList(),
    'subtasks': (await db.select(db.subtasks).get()).map(subtaskJson).toList(),
    'timeBlocks': (await db.select(db.timeBlocks).get()).map(blockJson).toList(),
    'sessions': (await db.select(db.sessions).get()).map(sessionJson).toList(),
    'distractions': (await db.select(db.distractions).get()).map(distractionJson).toList(),
    'distractionReasons': (await db.select(db.distractionReasons).get()).map(reasonJson).toList(),
    'reviews': (await db.select(db.reviews).get()).map(reviewJson).toList(),
  };
  return BackupFile(DateTime.now().toUtc().toIso8601String(), schemaVersion, data);
}

class BackupFormatException implements Exception {
  BackupFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Parses and migrates a backup file to the current schema. Add steps here when the schema changes.
BackupFile parseBackup(String text) {
  Object? raw;
  try {
    raw = jsonDecode(text);
  } catch (_) {
    throw BackupFormatException('The file is not valid JSON.');
  }
  if (raw is! Map || raw['app'] != 'deepwork' || raw['data'] is! Map) throw BackupFormatException('This file is not a Deepwork backup.');
  final version = _i(raw['schema_version']);
  if (version > schemaVersion) throw BackupFormatException('This backup was made by a newer version of Deepwork (schema $version). Please update the app first.');
  final data = Map<String, dynamic>.from(raw['data'] as Map);
  for (final t in dataTables) {
    if (data[t] is! List) data[t] = <dynamic>[];
  }
  // Validate rows parse before anything is replaced.
  try {
    for (final m in (data['tasks'] as List).cast<Map>()) {
      taskFrom(m);
    }
    for (final m in (data['sessions'] as List).cast<Map>()) {
      sessionFrom(m);
    }
  } catch (e) {
    throw BackupFormatException('The backup contains damaged records.');
  }
  return BackupFile('${raw['exported_at'] ?? ''}', schemaVersion, data);
}

/// Replaces all local data with the backup. Device lock and Drive connection are kept.
Future<AppSettings> restoreBackup(AppDatabase db, BackupFile file, AppSettings current) async {
  List<Map> rows(String t) => (file.data[t] as List).cast<Map>();
  await db.transaction(() async {
    for (final TableInfo t in [db.projects, db.tasks, db.subtasks, db.timeBlocks, db.sessions, db.distractions, db.distractionReasons, db.reviews]) {
      await db.delete(t).go();
    }
    await db.batch((b) {
      b.insertAll(db.projects, rows('projects').map(projectFrom), mode: InsertMode.insertOrReplace);
      b.insertAll(db.tasks, rows('tasks').map(taskFrom), mode: InsertMode.insertOrReplace);
      b.insertAll(db.subtasks, rows('subtasks').map(subtaskFrom), mode: InsertMode.insertOrReplace);
      b.insertAll(db.timeBlocks, rows('timeBlocks').map(blockFrom), mode: InsertMode.insertOrReplace);
      b.insertAll(db.sessions, rows('sessions').map(sessionFrom), mode: InsertMode.insertOrReplace);
      b.insertAll(db.distractions, rows('distractions').map(distractionFrom), mode: InsertMode.insertOrReplace);
      b.insertAll(db.distractionReasons, rows('distractionReasons').map(reasonFrom), mode: InsertMode.insertOrReplace);
      b.insertAll(db.reviews, rows('reviews').map(reviewFrom), mode: InsertMode.insertOrReplace);
    });
    if ((await db.select(db.distractionReasons).get()).isEmpty) {
      for (var i = 0; i < defaultReasons.length; i++) {
        await db.into(db.distractionReasons).insert(DistractionReasonsCompanion.insert(id: newId(), label: defaultReasons[i], sort: Value(i)));
      }
    }
  });
  final incoming = Map<String, dynamic>.from((file.data['settings'] as Map?) ?? {});
  incoming['lock'] = current.json['lock'];
  incoming['backup'] = current.json['backup'];
  incoming['demoLoaded'] = rows('sessions').any((s) => _b(s['is_demo']));
  final next = AppSettings.fromJson(incoming);
  await db.setValue('settings', next.encode());
  return next;
}

// ------------------------------------------------------------------ CSV
String _cell(Object? v) {
  if (v == null) return '';
  final s = '$v';
  return RegExp(r'[",\n\r]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
}

String _csv(List<String> headers, List<List<Object?>> rows) => [headers.join(','), ...rows.map((r) => r.map(_cell).join(','))].join('\r\n');
String _iso(int? ms) => ms == null ? '' : DateTime.fromMillisecondsSinceEpoch(ms).toUtc().toIso8601String();

Future<Map<String, String>> buildCsvs(AppDatabase db) async {
  final sessions = await (db.select(db.sessions)..orderBy([(t) => OrderingTerm.asc(t.startedAt)])).get();
  final tasks = await db.select(db.tasks).get();
  final distractions = await (db.select(db.distractions)..orderBy([(t) => OrderingTerm.asc(t.timestamp)])).get();
  final projects = await db.select(db.projects).get();
  final title = {for (final t in tasks) t.id: t.title};
  final pname = {for (final p in projects) p.id: p.name};
  return {
    'sessions': _csv(
      ['id', 'task_id', 'task_title', 'planned_minutes', 'actual_minutes', 'started_at', 'ended_at', 'result', 'note'],
      [
        for (final s in sessions)
          [s.id, s.taskId, s.taskId == null ? '' : title[s.taskId], (s.plannedDuration / 6).round() / 10, (s.actualDuration / 6).round() / 10, _iso(s.startedAt), _iso(s.endedAt), s.result, s.note],
      ],
    ),
    'tasks': _csv(
      ['id', 'title', 'project', 'estimate_sessions', 'due_date', 'status', 'flagged', 'is_priority', 'priority_date', 'created_at', 'completed_at'],
      [
        for (final t in tasks)
          [t.id, t.title, t.projectId == null ? '' : pname[t.projectId], t.estimateSessions, t.dueDate, t.status, t.flagged, t.isPriority, t.priorityDate, _iso(t.createdAt), _iso(t.completedAt)],
      ],
    ),
    'distractions': _csv(['id', 'session_id', 'timestamp', 'reason', 'note'], [
      for (final d in distractions) [d.id, d.sessionId, _iso(d.timestamp), d.reason, d.note],
    ]),
  };
}

Future<void> deleteAllData(AppDatabase db) async {
  await db.transaction(() async {
    for (final TableInfo t in [db.projects, db.tasks, db.subtasks, db.timeBlocks, db.sessions, db.distractions, db.distractionReasons, db.reviews, db.keyValues]) {
      await db.delete(t).go();
    }
  });
  await Repository(db).seedDefaults();
}

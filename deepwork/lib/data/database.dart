import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// All timestamps are milliseconds since epoch; dates are 'yyyy-MM-dd'; times are 'HH:mm'.
// The fields mirror Deepwork's JSON backup format so backups move freely between versions.

@DataClassName('Project')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()(); // '#RRGGBB'
  IntColumn get sort => integer().withDefault(const Constant(0))();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskItem')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get projectId => text().nullable()();
  IntColumn get estimateSessions => integer().nullable()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('todo'))(); // todo | in_progress | done
  BoolColumn get flagged => boolean().withDefault(const Constant(false))();
  BoolColumn get isPriority => boolean().withDefault(const Constant(false))();
  TextColumn get priorityDate => text().nullable()();
  IntColumn get priorityOrder => integer().withDefault(const Constant(0))();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Subtask')
class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimeBlock')
class TimeBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get taskId => text().nullable()();
  TextColumn get label => text().withDefault(const Constant(''))();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FocusSession')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().nullable()();
  IntColumn get plannedDuration => integer()(); // seconds
  IntColumn get actualDuration => integer()(); // seconds
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer()();
  TextColumn get result => text()(); // done | partly | stuck | interrupted
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Distraction')
class Distractions extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  IntColumn get timestamp => integer()();
  TextColumn get reason => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DistractionReason')
class DistractionReasons extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Review')
class Reviews extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // daily | weekly
  TextColumn get date => text()();
  TextColumn get answers => text().withDefault(const Constant('[]'))(); // JSON [{question, answer}]
  TextColumn get nextPriorities => text().withDefault(const Constant('[]'))(); // JSON [{task_id, title}]
  TextColumn get stats => text().withDefault(const Constant('{}'))(); // JSON
  IntColumn get createdAt => integer()();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key/value store: settings JSON, the in-progress focus session, reminder bookkeeping.
@DataClassName('KeyValue')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Projects, Tasks, Subtasks, TimeBlocks, Sessions, Distractions, DistractionReasons, Reviews, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'deepwork'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX IF NOT EXISTS sessions_started ON sessions (started_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS distractions_time ON distractions (timestamp)');
          await customStatement('CREATE INDEX IF NOT EXISTS blocks_date ON time_blocks (date)');
        },
      );

  Future<String?> getValue(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setValue(String key, String value) =>
      into(keyValues).insertOnConflictUpdate(KeyValue(key: key, value: value));

  Future<void> removeValue(String key) => (delete(keyValues)..where((t) => t.key.equals(key))).go();
}

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../core/util/format.dart';
import 'database.dart';
import 'repository.dart';

/// Overridden in main() with the opened database.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('databaseProvider must be overridden'));
final repositoryProvider = Provider<Repository>((ref) => Repository(ref.watch(databaseProvider)));

/// Overridden in main() with settings loaded before the first frame.
final initialSettingsProvider = Provider<AppSettings>((ref) => AppSettings.defaults());

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  Future<void> replace(AppSettings next) async {
    state = next;
    await ref.read(databaseProvider).setValue('settings', next.encode());
  }

  AppSettings get current => state;

  Future<void> set(String path, dynamic value) => replace(state.set(path, value));
  Future<void> edit(void Function(Map<String, dynamic> m) fn) => replace(state.edit(fn));

  /// Re-read from the database (after a restore or "delete all data").
  Future<void> reload() async => state = await loadSettings(ref.read(databaseProvider));
}

Future<AppSettings> loadSettings(AppDatabase db) async => AppSettings.fromJson(_decode(await db.getValue('settings')));



Object? _decode(String? s) {
  if (s == null) return null;
  try {
    return jsonDecode(s);
  } catch (_) {
    return null;
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

// ------------------------------------------------------------------ live data
final tasksProvider = StreamProvider<List<TaskItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.tasks)..orderBy([(t) => OrderingTerm.asc(t.sort)])).watch();
});

final projectsProvider = StreamProvider<List<Project>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.projects)..orderBy([(t) => OrderingTerm.asc(t.sort)])).watch();
});

final subtasksProvider = StreamProvider<List<Subtask>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.subtasks)..orderBy([(t) => OrderingTerm.asc(t.sort)])).watch();
});

final sessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.sessions)..orderBy([(t) => OrderingTerm.asc(t.startedAt)])).watch();
});

final distractionsProvider = StreamProvider<List<Distraction>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.distractions)..orderBy([(t) => OrderingTerm.asc(t.timestamp)])).watch();
});

final reasonsProvider = StreamProvider<List<DistractionReason>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.distractionReasons)..orderBy([(t) => OrderingTerm.asc(t.sort)])).watch();
});

final reviewsProvider = StreamProvider<List<Review>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.reviews)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});

final blocksForDateProvider = StreamProvider.family<List<TimeBlock>, String>((ref, date) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.timeBlocks)..where((t) => t.date.equals(date))).watch();
});

final distractionCountProvider = StreamProvider.family<int, String>((ref, sessionId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.distractions)..where((d) => d.sessionId.equals(sessionId))).watch().map((l) => l.length);
});

/// Today's date key; changes at local midnight so daily views reset.
final todayProvider = StreamProvider<String>((ref) {
  final controller = StreamController<String>();
  var current = todayKey();
  controller.add(current);
  final timer = Timer.periodic(const Duration(seconds: 20), (_) {
    final k = todayKey();
    if (k != current) {
      current = k;
      controller.add(k);
    }
  });
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

String watchToday(WidgetRef ref) => ref.watch(todayProvider).value ?? todayKey();

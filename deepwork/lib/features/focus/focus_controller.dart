import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/util/format.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../services/audio.dart';
import '../../services/native.dart';
import '../../services/notifications.dart';

enum FocusPhase { idle, running, paused, finished, closed, ended, breakTime, breakOver }

/// The in-progress focus session. Timing is based on wall-clock timestamps (never on counting
/// ticks), so it stays accurate when the app is backgrounded or the screen locks. The state is
/// saved so an in-progress session is restored when the app is reopened.
@immutable
class FocusState {
  const FocusState({
    this.phase = FocusPhase.idle,
    this.sessionId,
    this.taskId,
    this.plannedSec = 25 * 60,
    this.countUp = false,
    this.startedAt = 0,
    this.pausedAt,
    this.pausedMs = 0,
    this.endedAt,
    this.actualSec = 0,
    this.endReason,
    this.result,
    this.breakLong = false,
    this.breakStartedAt,
    this.breakSec = 0,
    this.sound,
  });

  final FocusPhase phase;
  final String? sessionId, taskId, endReason, result, sound;
  final int plannedSec, startedAt, pausedMs, actualSec, breakSec;
  final int? pausedAt, endedAt, breakStartedAt;
  final bool countUp, breakLong;

  bool get inSession => phase == FocusPhase.running || phase == FocusPhase.paused;

  double elapsedSec([int? nowMs]) {
    if (!inSession) return actualSec.toDouble();
    if (startedAt == 0) return 0;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final extra = pausedAt != null ? now - pausedAt! : 0;
    return ((now - startedAt - pausedMs - extra) / 1000).clamp(0, double.infinity).toDouble();
  }

  double breakElapsedSec([int? nowMs]) =>
      breakStartedAt == null ? 0 : (((nowMs ?? DateTime.now().millisecondsSinceEpoch) - breakStartedAt!) / 1000).clamp(0, double.infinity).toDouble();

  int get endsAt => startedAt + pausedMs + plannedSec * 1000;

  FocusState copyWith({
    FocusPhase? phase,
    Object? sessionId = _keep,
    Object? taskId = _keep,
    int? plannedSec,
    bool? countUp,
    int? startedAt,
    Object? pausedAt = _keep,
    int? pausedMs,
    Object? endedAt = _keep,
    int? actualSec,
    Object? endReason = _keep,
    Object? result = _keep,
    bool? breakLong,
    Object? breakStartedAt = _keep,
    int? breakSec,
    Object? sound = _keep,
  }) =>
      FocusState(
        phase: phase ?? this.phase,
        sessionId: sessionId == _keep ? this.sessionId : sessionId as String?,
        taskId: taskId == _keep ? this.taskId : taskId as String?,
        plannedSec: plannedSec ?? this.plannedSec,
        countUp: countUp ?? this.countUp,
        startedAt: startedAt ?? this.startedAt,
        pausedAt: pausedAt == _keep ? this.pausedAt : pausedAt as int?,
        pausedMs: pausedMs ?? this.pausedMs,
        endedAt: endedAt == _keep ? this.endedAt : endedAt as int?,
        actualSec: actualSec ?? this.actualSec,
        endReason: endReason == _keep ? this.endReason : endReason as String?,
        result: result == _keep ? this.result : result as String?,
        breakLong: breakLong ?? this.breakLong,
        breakStartedAt: breakStartedAt == _keep ? this.breakStartedAt : breakStartedAt as int?,
        breakSec: breakSec ?? this.breakSec,
        sound: sound == _keep ? this.sound : sound as String?,
      );

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'sessionId': sessionId,
        'taskId': taskId,
        'plannedSec': plannedSec,
        'countUp': countUp,
        'startedAt': startedAt,
        'pausedAt': pausedAt,
        'pausedMs': pausedMs,
        'endedAt': endedAt,
        'actualSec': actualSec,
        'endReason': endReason,
        'result': result,
        'breakLong': breakLong,
        'breakStartedAt': breakStartedAt,
        'breakSec': breakSec,
        'sound': sound,
      };

  static FocusState fromJson(Map<String, dynamic> j) => FocusState(
        phase: FocusPhase.values.firstWhere((p) => p.name == j['phase'], orElse: () => FocusPhase.idle),
        sessionId: j['sessionId'] as String?,
        taskId: j['taskId'] as String?,
        plannedSec: (j['plannedSec'] as num?)?.toInt() ?? 1500,
        countUp: j['countUp'] == true,
        startedAt: (j['startedAt'] as num?)?.toInt() ?? 0,
        pausedAt: (j['pausedAt'] as num?)?.toInt(),
        pausedMs: (j['pausedMs'] as num?)?.toInt() ?? 0,
        endedAt: (j['endedAt'] as num?)?.toInt(),
        actualSec: (j['actualSec'] as num?)?.toInt() ?? 0,
        endReason: j['endReason'] as String?,
        result: j['result'] as String?,
        breakLong: j['breakLong'] == true,
        breakStartedAt: (j['breakStartedAt'] as num?)?.toInt(),
        breakSec: (j['breakSec'] as num?)?.toInt() ?? 0,
        sound: j['sound'] as String?,
      );
}

const _keep = Object();
const _stateKey = 'focus_state';

/// Overridden in main() with the session restored from the database.
final initialFocusProvider = Provider<FocusState>((ref) => const FocusState());

final focusProvider = NotifierProvider<FocusController, FocusState>(FocusController.new);

Future<FocusState> loadFocusState(AppDatabase db) async {
  final raw = await db.getValue(_stateKey);
  if (raw == null) return const FocusState();
  try {
    return FocusState.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  } catch (_) {
    return const FocusState();
  }
}

class FocusController extends Notifier<FocusState> {
  Timer? _poll;
  Timer? _exact;
  AppLifecycleListener? _lifecycle;

  AppSettings get _s => ref.read(settingsProvider);
  Repository get _repo => ref.read(repositoryProvider);
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  FocusState build() {
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _check());
    _lifecycle = AppLifecycleListener(onResume: () {
      _check();
      _collectBlockedAttempts();
      _applySideEffects();
    });
    ref.onDispose(() {
      _poll?.cancel();
      _exact?.cancel();
      _lifecycle?.dispose();
    });
    // Re-apply blocking/alerts when relevant settings change.
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.json['blocking'] != next.json['blocking'] || prev?.on('appBlocking') != next.on('appBlocking') || prev?.json['notifications'] != next.json['notifications']) {
        _applySideEffects();
      }
      if (prev?.d('ambient.volume') != next.d('ambient.volume')) AmbientPlayer.instance.setVolume(next.d('ambient.volume'));
    });
    final initial = ref.read(initialFocusProvider);
    Future.microtask(() {
      _check();
      _applySideEffects();
      _collectBlockedAttempts();
    });
    return initial;
  }

  void _commit(FocusState next) {
    state = next;
    if (next.phase == FocusPhase.idle) {
      _db.removeValue(_stateKey);
    } else {
      _db.setValue(_stateKey, jsonEncode(next.toJson()));
    }
    _scheduleExact();
    _applySideEffects();
  }

  void _scheduleExact() {
    _exact?.cancel();
    final s = state;
    final now = DateTime.now().millisecondsSinceEpoch;
    int? at;
    if (s.phase == FocusPhase.running) at = s.endsAt;
    if (s.phase == FocusPhase.breakTime && s.breakStartedAt != null) at = s.breakStartedAt! + s.breakSec * 1000;
    if (at != null) _exact = Timer(Duration(milliseconds: (at - now + 30).clamp(0, 1 << 31)), _check);
  }

  void _check() {
    final s = state;
    if (s.phase == FocusPhase.running && s.elapsedSec() >= s.plannedSec) _finish();
    if (s.phase == FocusPhase.breakTime && s.breakElapsedSec() >= s.breakSec) _breakDone();
  }

  // ------------------------------------------------------------ side effects
  void _applySideEffects() {
    final s = state;
    final st = _s;
    // Keep the screen on during sessions and breaks.
    NativeBridge.setKeepAwake(st.b('focus.wakeLock') && (s.inSession || s.phase == FocusPhase.breakTime));
    // Timer alert scheduled with Android so it fires even if the app is closed.
    if (s.phase == FocusPhase.running) {
      Notifications.scheduleTimerAlert(st, DateTime.fromMillisecondsSinceEpoch(s.endsAt), NotifyKind.sessionComplete);
    } else if (s.phase == FocusPhase.breakTime && s.breakStartedAt != null) {
      Notifications.scheduleTimerAlert(st, DateTime.fromMillisecondsSinceEpoch(s.breakStartedAt! + s.breakSec * 1000), NotifyKind.breakOver);
    } else {
      Notifications.scheduleTimerAlert(st, null, NotifyKind.sessionComplete);
    }
    // App blocking while a session runs.
    final mode = st.s('blocking.mode');
    final pkgs = st.strings('blocking.packages');
    if (st.on('appBlocking') && s.phase == FocusPhase.running && (mode == 'allow' || pkgs.isNotEmpty)) {
      () async {
        final task = s.taskId == null ? null : await (_db.select(_db.tasks)..where((t) => t.id.equals(s.taskId!))).getSingleOrNull();
        await NativeBridge.startBlocking(until: s.endsAt, mode: mode, packages: pkgs, taskTitle: task?.title ?? '');
      }();
    } else {
      NativeBridge.stopBlocking();
    }
    // Ambient sound follows the phase.
    final allowed = st.on('ambient') && s.sound != null && st.strings('ambient.available').contains(s.sound);
    if (s.phase == FocusPhase.running && allowed) {
      AmbientPlayer.instance.play(s.sound!, st.d('ambient.volume'));
    } else if (AmbientPlayer.instance.playing) {
      AmbientPlayer.instance.stop();
    }
  }

  /// Attempts to open a paused app are logged as distractions when you come back.
  Future<void> _collectBlockedAttempts() async {
    final attempts = await NativeBridge.takeBlockedAttempts();
    final s = state;
    if (attempts.isEmpty || s.sessionId == null || !_s.b('blocking.logAttempts') || !_s.on('distractions')) return;
    for (final a in attempts.where((a) => a.timestamp >= s.startedAt)) {
      await _repo.logDistraction(s.sessionId!, 'Blocked app', 'Tried to open ${a.label}', a.timestamp);
    }
  }

  Future<void> _save(FocusState s, String result, String note) async {
    if (s.sessionId == null) return;
    await _repo.saveSession(FocusSession(
      id: s.sessionId!,
      taskId: s.taskId,
      plannedDuration: s.plannedSec,
      actualDuration: s.actualSec,
      startedAt: s.startedAt,
      endedAt: s.endedAt ?? DateTime.now().millisecondsSinceEpoch,
      result: result,
      note: note,
      isDemo: false,
    ));
  }

  Future<void> _finish() async {
    final s = state;
    if (s.phase != FocusPhase.running) return;
    final next = s.copyWith(phase: FocusPhase.finished, endedAt: s.endsAt, actualSec: s.plannedSec, pausedAt: null);
    unawaited(playChime());
    if (!_s.on('sessionClose')) {
      _commit(next.copyWith(phase: FocusPhase.closed, result: 'done'));
      await _save(next, 'done', '');
    } else {
      _commit(next);
    }
  }

  void _breakDone() {
    if (state.phase != FocusPhase.breakTime) return;
    _commit(state.copyWith(phase: FocusPhase.breakOver));
    unawaited(playChime(breakOver: true));
    if (_s.b('breaks.autoStartNext')) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (state.phase == FocusPhase.breakOver) startNext();
      });
    }
  }

  // ------------------------------------------------------------ actions
  Future<void> start({String? taskId, required int minutes, String? sound}) async {
    final st = _s;
    _commit(FocusState(
      phase: FocusPhase.running,
      sessionId: newId(),
      taskId: taskId,
      plannedSec: minutes * 60,
      countUp: st.s('focus.mode') == 'countup',
      startedAt: DateTime.now().millisecondsSinceEpoch,
      sound: st.on('ambient') ? sound : null,
    ));
    if (taskId != null) {
      final t = await (_db.select(_db.tasks)..where((x) => x.id.equals(taskId))).getSingleOrNull();
      if (t != null && t.status == 'todo') await _repo.setTaskStatus(taskId, 'in_progress');
    }
  }

  void pause() {
    if (state.phase != FocusPhase.running) return;
    _commit(state.copyWith(phase: FocusPhase.paused, pausedAt: DateTime.now().millisecondsSinceEpoch));
  }

  void resume() {
    final s = state;
    if (s.phase != FocusPhase.paused || s.pausedAt == null) return;
    _commit(s.copyWith(phase: FocusPhase.running, pausedMs: s.pausedMs + (DateTime.now().millisecondsSinceEpoch - s.pausedAt!), pausedAt: null));
  }

  /// End before the timer completes. finishedEarly → session close; otherwise logged as interrupted.
  Future<void> endEarly({required String reason, required bool finishedEarly}) async {
    final s = state;
    if (!s.inSession) return;
    final ended = s.copyWith(endedAt: DateTime.now().millisecondsSinceEpoch, actualSec: s.elapsedSec().round(), pausedAt: null, endReason: reason);
    if (finishedEarly) {
      if (_s.on('sessionClose')) {
        _commit(ended.copyWith(phase: FocusPhase.finished));
      } else {
        _commit(ended.copyWith(phase: FocusPhase.closed, result: 'done'));
        await _save(ended, 'done', '');
      }
    } else {
      _commit(ended.copyWith(phase: FocusPhase.ended, result: 'interrupted'));
      await _save(ended, 'interrupted', reason);
    }
  }

  Future<void> discard() async {
    final s = state;
    if (s.sessionId != null) await _repo.deleteDistractionsFor(s.sessionId!);
    _commit(FocusState(sound: s.sound));
  }

  Future<void> close({required String result, required String note, required bool markTaskDone, required List<String> nextSteps}) async {
    final s = state;
    if (s.phase != FocusPhase.finished) return;
    await _save(s, result, note);
    if (s.taskId != null && markTaskDone) await _repo.setTaskDone(s.taskId!, true);
    final steps = nextSteps.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (steps.isNotEmpty) {
      final parent = s.taskId == null ? null : await (_db.select(_db.tasks)..where((t) => t.id.equals(s.taskId!))).getSingleOrNull();
      final today = todayKey();
      final prioCount = (await _repo.prioritiesFor(today)).length;
      final usePrio = _s.on('priorities');
      for (var i = 0; i < steps.length; i++) {
        final t = await _repo.createTask(title: steps[i], projectId: parent?.projectId, estimate: 1);
        if (usePrio && i == 0 && prioCount < _s.priorityCount) {
          await _repo.updateTask(t.id, TasksCompanion(isPriority: const Value(true), priorityDate: Value(today), priorityOrder: Value(prioCount)));
        }
      }
    }
    _commit(s.copyWith(phase: FocusPhase.closed, result: result));
  }

  /// Long break after every N completed sessions today.
  Future<bool> suggestLongBreak() async {
    final since = startOfDay(DateTime.now()).millisecondsSinceEpoch;
    final n = (await (_db.select(_db.sessions)..where((x) => x.startedAt.isBiggerOrEqualValue(since))).get()).where((x) => x.result != 'interrupted').length;
    final every = _s.i('breaks.longAfter').clamp(1, 100);
    return n > 0 && n % every == 0;
  }

  void startBreak({required bool long}) {
    final st = _s;
    _commit(state.copyWith(
      phase: FocusPhase.breakTime,
      breakLong: long,
      breakStartedAt: DateTime.now().millisecondsSinceEpoch,
      breakSec: (long ? st.i('breaks.long') : st.i('breaks.short')) * 60,
    ));
  }

  void skipBreak() => _commit(state.copyWith(phase: FocusPhase.breakOver));

  Future<void> startNext() async {
    final s = state;
    var taskId = s.taskId;
    if (taskId != null) {
      final t = await (_db.select(_db.tasks)..where((x) => x.id.equals(taskId!))).getSingleOrNull();
      if (t == null || t.status == 'done') taskId = null;
    }
    if (taskId == null && _s.b('focus.requireTask') && (_s.on('tasks') || _s.on('priorities'))) {
      _commit(FocusState(sound: s.sound));
      return;
    }
    await start(taskId: taskId, minutes: (s.plannedSec / 60).round(), sound: s.sound);
  }

  void reset() => _commit(FocusState(sound: state.sound));

  Future<void> logDistraction(String reason, String note) async {
    final id = state.sessionId;
    if (id != null) await _repo.logDistraction(id, reason, note);
  }

  void setSound(String? sound) => _commit(state.copyWith(sound: sound));
}

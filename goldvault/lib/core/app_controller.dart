import 'dart:async';

import 'package:flutter/material.dart';

import '../services/alarm_scheduler.dart';
import '../services/background.dart';
import 'app_services.dart';
import 'security.dart';

/// App-wide preferences + opportunistic foreground auto-sync.
class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController(this.svc);
  final AppServices svc;

  Locale _locale = const Locale('en', 'IN');
  Locale get locale => _locale;

  final ValueNotifier<String?> syncStatus = ValueNotifier(null);
  Timer? _debounce;
  Timer? _alarmDebounce;
  bool _syncing = false;

  Future<void> load() async {
    final lang = await svc.repo.getSetting('lang');
    _locale = Locale(lang == 'kn' ? 'kn' : 'en', 'IN');
    await ScreenGuard.setAlways((await svc.repo.getSetting('screenshot_all')) != '0');
    WidgetsBinding.instance.addObserver(this);
    svc.repo.revision.addListener(_onDataChanged);
    // Google is optional and must never block offline start-up.
    unawaited(svc.google.load().then((_) => _autoSync()));
    unawaited(Background.schedule(svc));
    unawaited(AlarmScheduler.reschedule(svc.repo));
  }

  Future<void> setLanguage(String code) async {
    await svc.repo.setSetting('lang', code);
    _locale = Locale(code, 'IN');
    notifyListeners();
  }

  void _onDataChanged() {
    // Reminders, holidays or settings may have changed: refresh alarms.
    _alarmDebounce?.cancel();
    _alarmDebounce = Timer(const Duration(seconds: 2), () => AlarmScheduler.reschedule(svc.repo));
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 20), _autoSync);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoSync();
  }

  /// Silent sync when signed in, data changed and auto-sync is on. Any
  /// failure (offline, no account) is ignored; the background job retries.
  Future<void> _autoSync() async {
    if (_syncing) return;
    if ((await svc.repo.getSetting('auto_sync')) == '0') return;
    if (svc.google.email.value == null) return;
    if (!await svc.sheets.isDirty()) return;
    _syncing = true;
    try {
      final r = await svc.sheets.syncNow();
      syncStatus.value = r.ok ? 'ok' : r.message;
    } catch (_) {
      syncStatus.value = 'offline';
    } finally {
      _syncing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    svc.repo.revision.removeListener(_onDataChanged);
    _debounce?.cancel();
    _alarmDebounce?.cancel();
    super.dispose();
  }
}

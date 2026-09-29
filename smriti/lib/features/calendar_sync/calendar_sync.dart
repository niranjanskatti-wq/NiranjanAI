import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../reminders/notification_service.dart';

/// A calendar on the phone that Smriti can write to.
class PhoneCalendar {
  const PhoneCalendar(this.id, this.name, this.account, this.primary);

  final int id;
  final String name, account;
  final bool primary;

  String get label => account.isEmpty || account == name ? name : '$name · $account';
}

/// What one Smriti date looks like in the phone calendar.
class CalendarItem {
  const CalendarItem(this.title, this.year, this.month, this.day, this.rrule);

  final String title;
  final int year, month, day;
  final String? rrule;

  static CalendarItem of(EventEntry e, {required int thisYear}) {
    final ev = e.event;
    final title = switch (e.kind) {
      EventKind.person || EventKind.couple => '${e.title} · ${e.typeLabel}',
      _ => e.title,
    };
    return CalendarItem(
      title,
      ev.year ?? thisYear,
      ev.month,
      ev.day,
      switch (e.repeat) {
        Repeat.yearly => 'FREQ=YEARLY',
        Repeat.monthly => 'FREQ=MONTHLY',
        Repeat.once => null,
      },
    );
  }

  String hash(int calendarId) => '$calendarId|$title|$year|$month|$day|$rrule';
}

/// Optional one-way copy of Smriti's dates into a phone calendar
/// (e.g. Google Calendar), kept up to date as dates change.
class CalendarSync {
  static const _ch = MethodChannel('smriti/calendar');
  static Timer? _timer;
  static bool _running = false;

  static Future<bool> hasPermission() async => (await Permission.calendarFullAccess.status).isGranted;
  static Future<bool> askPermission() async => (await Permission.calendarFullAccess.request()).isGranted;

  static Future<List<PhoneCalendar>> calendars() async {
    final list = await _ch.invokeListMethod<Map<Object?, Object?>>('calendars') ?? const [];
    return [
      for (final m in list)
        PhoneCalendar((m['id'] as num).toInt(), m['name'] as String? ?? '', m['account'] as String? ?? '', m['primary'] == true),
    ];
  }

  static void syncSoon(AppDatabase db) {
    if (!NotificationService.supported) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () => syncNow(db));
  }

  static Future<Map<String, List<Object?>>> _map(AppDatabase db) async {
    try {
      final raw = jsonDecode(await db.getSetting('calendarMap') ?? '{}') as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (v as List).cast<Object?>()));
    } catch (_) {
      return {};
    }
  }

  /// Brings the phone calendar in step. Returns how many dates were written.
  static Future<int> syncNow(AppDatabase db) async {
    if (!NotificationService.supported || _running) return 0;
    if (await db.getSetting('calendarSync') != 'true') return 0;
    final calendarId = int.tryParse(await db.getSetting('calendarId') ?? '');
    if (calendarId == null || !await hasPermission()) return 0;
    _running = true;
    var written = 0;
    try {
      final map = await _map(db);
      final entries = (await Repository(db).watchEntries().first).where((e) => !e.isArchived);
      final seen = <String>{};
      final thisYear = DateTime.now().year;
      for (final e in entries) {
        final key = '${e.event.id}';
        seen.add(key);
        final item = CalendarItem.of(e, thisYear: thisYear);
        final h = item.hash(calendarId);
        final old = map[key];
        if (old != null && old[1] == h) continue;
        final id = await _ch.invokeMethod<int>('upsert', {
          'calendarId': calendarId,
          'eventId': old?[0],
          'title': item.title,
          'description': 'From Smriti',
          'year': item.year,
          'month': item.month,
          'day': item.day,
          'rrule': item.rrule,
        });
        map[key] = [id, h];
        written++;
      }
      final gone = map.keys.where((k) => !seen.contains(k)).toList();
      if (gone.isNotEmpty) {
        await _ch.invokeMethod('delete', [for (final k in gone) map[k]![0]]);
        for (final k in gone) {
          map.remove(k);
        }
      }
      await db.setSetting('calendarMap', jsonEncode(map));
    } catch (e) {
      debugPrint('Calendar sync failed: $e');
    } finally {
      _running = false;
    }
    return written;
  }

  /// Takes Smriti's dates back out of the phone calendar.
  static Future<void> removeAll(AppDatabase db) async {
    final map = await _map(db);
    if (map.isNotEmpty && await hasPermission()) {
      try {
        await _ch.invokeMethod('delete', [for (final v in map.values) v[0]]);
      } catch (e) {
        debugPrint('Calendar remove failed: $e');
      }
    }
    await db.setSetting('calendarMap', '{}');
  }
}

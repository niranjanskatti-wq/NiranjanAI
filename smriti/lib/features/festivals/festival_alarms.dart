import 'package:timezone/timezone.dart' as tz;

import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../data/database.dart';
import '../reminders/alarm_planner.dart';
import '../reminders/reminder_model.dart';
import 'festival_model.dart';

/// Festival reminders: on the morning of each switched-on festival, and
/// optionally the evening before.
Future<List<PlannedAlarm>> festivalAlarms(AppDatabase db, tz.TZDateTime now) async {
  if (await db.getSetting('festivalReminders') == 'false') return const [];
  final dayBefore = await db.getSetting('festivalDayBefore') == 'true';
  final morning = int.tryParse(await db.getSetting('morningMinute') ?? '') ?? 480;
  final festivals = await FestivalRepo.loadAll(db);
  final today = Day(now.year, now.month, now.day);
  final out = <PlannedAlarm>[];
  for (final f in festivals.where((f) => f.enabled)) {
    for (final d in f.between(today, today.addDays(366))) {
      final on = tz.TZDateTime(now.location, d.year, d.month, d.day, morning ~/ 60, morning % 60);
      out.add(PlannedAlarm(
        id: stableId('fest|${f.key}|$d'),
        when: on,
        kind: 'fest',
        title: 'Today: ${f.name} 🪔',
        body: 'Tap to start Wish Mode and wish everyone in one go',
        sound: AlarmSound.chime,
        date: d,
        festivalKey: f.key,
      ));
      if (dayBefore) {
        final eve = tz.TZDateTime(now.location, d.year, d.month, d.day, 19).subtract(const Duration(days: 1));
        out.add(PlannedAlarm(
          id: stableId('festeve|${f.key}|$d'),
          when: eve,
          kind: 'fest',
          title: 'Tomorrow: ${f.name}',
          body: '${fmtWeekday(d)} · prepare your wishes',
          sound: AlarmSound.softBell,
          date: d,
          festivalKey: f.key,
        ));
      }
    }
  }
  return out;
}

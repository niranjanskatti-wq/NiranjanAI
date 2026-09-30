import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/autocall/auto_call.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(tzdata.initializeTimeZones);

  test('auto calls are planned only when switched on, at the chosen time, with speaker and number', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final appa = await r.insertPerson(PeopleCompanion.insert(
        name: 'Ramesh Katti', nickname: const Value('Appa'), callNumber: const Value('+919845012345')));
    final noNumber = await r.insertPerson(PeopleCompanion.insert(name: 'No Number'));
    final bday = await r.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 3, month: 10), personIds: [appa]);
    await db.into(db.autoCalls).insert(AutoCallsCompanion.insert(personId: appa, eventId: Value(bday), minuteOfDay: 0));
    await db.into(db.autoCalls).insert(AutoCallsCompanion.insert(
        personId: appa, date: const Value('2026-10-10'), minuteOfDay: 18 * 60 + 30, speaker: const Value(false)));
    await db.into(db.autoCalls).insert(AutoCallsCompanion.insert(personId: noNumber, date: const Value('2026-10-10'), minuteOfDay: 600));
    await db.into(db.autoCalls).insert(
        AutoCallsCompanion.insert(personId: appa, date: const Value('2026-09-01'), minuteOfDay: 600)); // past
    final loc = tz.getLocation('Asia/Kolkata');
    final now = tz.TZDateTime(loc, 2026, 9, 30, 10);

    expect(await autoCallAlarms(db, now), isEmpty, reason: 'off until switched on in Settings');
    await db.setSetting('autoCall', 'true');
    final plan = await autoCallAlarms(db, now);

    // Birthday this year and next, plus the one-time call; nothing for the person without a number or the past date.
    expect(plan.map((a) => a.when.toString().substring(0, 16)).toList(),
        ['2026-10-03 00:00', '2027-10-03 00:00', '2026-10-10 18:30']);
    expect(plan.every((a) => a.kind == 'call' && a.fullScreen), isTrue);
    final p = jsonDecode(plan.first.payload) as Map<String, dynamic>;
    expect((p['n'], p['sp'], p['nm'], p['k']), ('+919845012345', true, 'Appa', 'call'));
    expect(jsonDecode(plan.last.payload)['sp'], false);
    expect(plan.first.title, contains('Appa'));

    // Turning one off removes it.
    await (db.update(db.autoCalls)..where((a) => a.eventId.equals(bday))).write(const AutoCallsCompanion(enabled: Value(false)));
    expect((await autoCallAlarms(db, now)).length, 1);
    await db.close();
  });
}

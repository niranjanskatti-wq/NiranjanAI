import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/app.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/providers.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/export/export_service.dart';
import 'package:smriti/features/reminders/alarm_planner.dart';
import 'package:smriti/features/reminders/alarm_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _relations = ['friend', 'cousin', 'uncle', 'aunt', 'colleague', 'brother', 'sister', 'neighbour'];

/// 600 people, 600 birthdays, 300 anniversaries.
Future<void> seedMany(AppDatabase db) async {
  await db.batch((b) {
    b.insert(db.people, PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
    for (var i = 0; i < 600; i++) {
      b.insert(
          db.people,
          PeopleCompanion.insert(
            name: 'Person $i Kumar',
            nickname: Value(i.isEven ? 'P$i' : null),
            relationship: Value(_relations[i % _relations.length]),
            stars: Value(1 + i % 5),
            birthYear: Value(1950 + i % 60),
            callNumber: Value('+9198450${i.toString().padLeft(5, '0')}'),
          ));
    }
  });
  final r = Repository(db);
  final people = (await r.allPeople()).where((p) => !p.isMe).toList();
  for (var i = 0; i < people.length; i++) {
    await r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 1 + i % 28, month: 1 + i % 12, year: Value(1950 + i % 60)),
        personIds: [people[i].id]);
    if (i.isEven && i + 1 < people.length) {
      await r.saveEvent(
          data: EventsCompanion.insert(kind: 'couple', type: 'weddingAnniversary', day: 1 + (i * 7) % 28, month: 1 + (i * 5) % 12),
          personIds: [people[i].id, people[i + 1].id]);
    }
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(tzdata.initializeTimeZones);

  test('data work with 600 people stays quick', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await seedMany(db);
    final r = Repository(db);

    var sw = Stopwatch()..start();
    final entries = await r.watchEntries().first;
    final load = sw.elapsedMilliseconds;
    expect(entries.length, 900);

    sw = Stopwatch()..start();
    final up = computeUpcoming(entries, const Day(2026, 9, 29));
    final upcoming = sw.elapsedMilliseconds;
    expect(up.length, 900);

    sw = Stopwatch()..start();
    final now = tz.TZDateTime(tz.UTC, 2026, 9, 29, 10);
    final plan = planAlarms(await AlarmScheduler.gather(db, now), now: now, local: tz.UTC);
    final planning = sw.elapsedMilliseconds;
    expect(plan.length, 450, reason: 'capped below the phone limit, soonest first');

    sw = Stopwatch()..start();
    final xlsx = await ExportService(db).build(const ExportOptions());
    final export = sw.elapsedMilliseconds;
    expect(xlsx.length, greaterThan(10000));

    // ignore: avoid_print
    print('600 people · load ${load}ms · upcoming ${upcoming}ms · alarms ${planning}ms (${plan.length}) · Excel ${export}ms');
    expect(load, lessThan(1500));
    expect(upcoming, lessThan(300));
    expect(planning, lessThan(1500));
    await db.close();
  });

  testWidgets('home, people and calendar open with 600 people', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() async {
      await seedMany(db);
      await db.setSetting('onboarded', 'true');
    });
    await tester.pumpWidget(ProviderScope(overrides: [databaseProvider.overrideWithValue(db)], child: const SmritiApp()));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    final sw = Stopwatch()..start();
    for (final tab in ['People', 'Calendar', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
    }
    // ignore: avoid_print
    print('tab switches: ${sw.elapsedMilliseconds}ms');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}

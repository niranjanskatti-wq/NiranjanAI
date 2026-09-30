import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/app.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/enums.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/providers.dart';
import 'package:smriti/data/repository.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(tzdata.initializeTimeZones);

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const SmritiApp(),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('first launch shows the welcome screen and creates your profile', (tester) async {
    await pumpApp(tester);
    expect(find.text('Get started'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Niranjan');
    await tester.tap(find.text('Get started'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final me = await Repository(db).getMe();
    expect(me?.name, 'Niranjan');
    expect(await db.getSetting('onboarded'), 'true');
    expect(find.text('No one here yet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('home shows the next event in the hero card with a countdown', (tester) async {
    final repo = Repository(db);
    await db.setSetting('onboarded', 'true');
    await repo.insertPerson(PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
    final appa = await repo.insertPerson(PeopleCompanion.insert(
      name: 'Ramesh Katti',
      nickname: const Value('Appa'),
      relationship: const Value('father'),
      stars: const Value(5),
      birthYear: Value(DateTime.now().year - 60),
    ));
    final soon = Day.today().addDays(4);
    await repo.saveEvent(
      data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: soon.day, month: soon.month),
      personIds: [appa],
    );
    final later = Day.today().addDays(20);
    await repo.saveEvent(
      data: EventsCompanion.insert(
          kind: 'other', type: 'insurance', title: const Value('Car insurance'), day: later.day, month: later.month),
      personIds: [],
    );

    await pumpApp(tester);
    expect(find.text('Appa'), findsWidgets);
    expect(find.textContaining('Turning 60'), findsWidgets);
    expect(find.text('DAYS'), findsOneWidget); // countdown cells
    expect(find.text('Car insurance'), findsOneWidget);

    // "Important dates" filter hides people
    await tester.tap(find.text('Important dates'));
    await tester.pump();
    expect(find.text('Car insurance'), findsOneWidget);
    await unmount(tester);
  });

  for (final size in [AppTextSize.xs, AppTextSize.xl]) {
    testWidgets('home works with ${size.label.toLowerCase()} text', (tester) async {
      final repo = Repository(db);
      await db.setSetting('onboarded', 'true');
      await db.setSetting('appTextSize', size.name);
      await repo.insertPerson(PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
      final p = await repo.insertPerson(PeopleCompanion.insert(name: 'Bharti Katti', birthYear: const Value(1975)));
      final soon = Day.today().addDays(3);
      await repo.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: soon.day, month: soon.month),
        personIds: [p],
      );
      await pumpApp(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Bharti Katti'), findsWidgets);
      final scaler = MediaQuery.textScalerOf(tester.element(find.text('Bharti Katti').first));
      expect(scaler.scale(10), closeTo(10 * size.scale, 0.01));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('home top card can be made small, hidden and big again', (tester) async {
    final repo = Repository(db);
    await db.setSetting('onboarded', 'true');
    await repo.insertPerson(PeopleCompanion.insert(name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
    final p = await repo.insertPerson(PeopleCompanion.insert(name: 'Shanta Katti', birthYear: const Value(1966)));
    final soon = Day.today().addDays(3);
    await repo.saveEvent(
      data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: soon.day, month: soon.month),
      personIds: [p],
    );
    await db.setSetting('rowSize', 'compact');
    await pumpApp(tester);
    expect(find.text('DAYS'), findsOneWidget, reason: 'big card with countdown');
    await tester.tap(find.byTooltip('Make smaller'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(await db.getSetting('homeHero'), 'small');
    expect(find.text('NEXT UP'), findsOneWidget);
    expect(find.text('DAYS'), findsNothing);
    await db.setSetting('homeHero', 'hidden');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('NEXT UP'), findsNothing);
    expect(find.text('Shanta Katti'), findsOneWidget, reason: 'still in the list');
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  test('couple events show both names and years married', () async {
    final repo = Repository(db);
    final a = await repo.insertPerson(PeopleCompanion.insert(name: 'Ravi', relationship: const Value('uncle')));
    final b = await repo.insertPerson(PeopleCompanion.insert(name: 'Priya', relationship: const Value('aunt')));
    await repo.saveEvent(
      data: EventsCompanion.insert(
          kind: 'couple', type: 'weddingAnniversary', day: 21, month: 5, year: const Value(1991)),
      personIds: [a, b],
    );
    final entries = await repo.watchEntries().first;
    final e = entries.single;
    expect(e.kind, EventKind.couple);
    expect(e.title, 'Ravi & Priya');
    expect(e.relationLine, 'Uncle & Aunt');
    final u = computeUpcoming(entries, const Day(2026, 5, 1)).single;
    expect(u.years, 35);
    expect(u.yearsPhrase, '35th anniversary');
  });

  test('deleting a person removes their own events but keeps couple partner events', () async {
    final repo = Repository(db);
    final a = await repo.insertPerson(PeopleCompanion.insert(name: 'A'));
    final b = await repo.insertPerson(PeopleCompanion.insert(name: 'B'));
    await repo.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 1, month: 1), personIds: [a]);
    await repo.saveEvent(
        data: EventsCompanion.insert(kind: 'couple', type: 'weddingAnniversary', day: 2, month: 2), personIds: [a, b]);
    await repo.deletePerson(a);
    final entries = await repo.watchEntries().first;
    expect(entries.length, 1);
    expect(entries.single.people.single.name, 'B');
  });

  test('archived people drop off the upcoming list', () async {
    final repo = Repository(db);
    final a = await repo.insertPerson(PeopleCompanion.insert(name: 'A'));
    await repo.saveEvent(data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 1, month: 1), personIds: [a]);
    await repo.setArchived(a, true);
    final entries = await repo.watchEntries().first;
    expect(computeUpcoming(entries, Day.today()), isEmpty);
    expect(computeUpcoming(entries, Day.today(), includeArchived: true).length, 1);
  });
}

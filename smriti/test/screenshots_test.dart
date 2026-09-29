// Renders key screens with the real fonts into PNGs for design review.
// Run: flutter test test/screenshots_test.dart --update-goldens --tags screenshots
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smriti/app.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/providers.dart';
import 'package:smriti/data/repository.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    tzdata.initializeTimeZones();
    const f = 'assets/fonts';
    await _loadFont('Manrope', ['$f/Manrope-400.ttf', '$f/Manrope-500.ttf', '$f/Manrope-600.ttf', '$f/Manrope-700.ttf']);
    await _loadFont('Cormorant', [
      '$f/CormorantGaramond-500.ttf',
      '$f/CormorantGaramond-600.ttf',
      '$f/CormorantGaramond-700.ttf',
    ]);
    await _loadFont('NotoDevanagari', ['$f/NotoSansDevanagari-400.ttf']);
    await _loadFont('NotoKannada', ['$f/NotoSansKannada-400.ttf']);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
    await _loadFont('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  Future<AppDatabase> seed({String theme = 'dark'}) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repository(db);
    await db.setSetting('onboarded', 'true');
    await db.setSetting('themeMode', theme);
    await repo.insertPerson(PeopleCompanion.insert(
        name: 'Niranjan', isMe: const Value(true), relationship: const Value('self')));
    final t = Day.today();
    Future<int> person(String name, String nick, String rel, int stars, {int? born}) => repo.insertPerson(
        PeopleCompanion.insert(
            name: name,
            nickname: Value(nick),
            relationship: Value(rel),
            stars: Value(stars),
            birthYear: Value(born),
            callNumber: const Value('+919845012345')));
    Future<void> bday(int id, int inDays) async {
      final d = t.addDays(inDays);
      await repo.saveEvent(
          data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: d.day, month: d.month), personIds: [id]);
    }

    final appa = await person('Ramesh Katti', 'Appa', 'father', 5, born: t.addDays(4).year - 60);
    await bday(appa, 4);
    final chinnu = await person('Chinmayi', 'Chinnu', 'niece', 4, born: t.addDays(13).year - 13);
    await bday(chinnu, 13);
    final ravi = await person('Ravi Kumar', 'Ravi', 'uncle', 4);
    final priya = await person('Priya Kumar', 'Priya', 'aunt', 4);
    final a = t.addDays(17);
    await repo.saveEvent(
        data: EventsCompanion.insert(
            kind: 'couple', type: 'weddingAnniversary', day: a.day, month: a.month, year: Value(a.year - 25)),
        personIds: [ravi, priya]);
    final ins = t.addDays(29);
    await repo.saveEvent(
        data: EventsCompanion.insert(
            kind: 'other', type: 'insurance', title: const Value('Car insurance'), day: ins.day, month: ins.month),
        personIds: []);
    final amma = await person('Shanta Katti', 'Amma', 'mother', 5);
    await bday(amma, 58);
    await repo.addGift(appa, 'Reading glasses stand');
    await repo.addGift(appa, 'Mysore Pak from Guru Sweets');
    return db;
  }

  Future<void> shoot(WidgetTester tester, AppDatabase db, String name, {String? route, String? tap}) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const SmritiApp(),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (route != null) {
      tester.element(find.byType(Scaffold).first).push(route);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    if (tap != null) {
      await tester.tap(find.text(tap).first);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screenshots/$name.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  }

  testWidgets('home dark', (t) async => shoot(t, await seed(), 'home_dark'));
  testWidgets('home light', (t) async => shoot(t, await seed(theme: 'light'), 'home_light'));
  testWidgets('people', (t) async => shoot(t, await seed(theme: 'light'), 'people_light', route: '/people'));
  testWidgets('profile', (t) async => shoot(t, await seed(theme: 'light'), 'profile_light', route: '/person/2'));
  testWidgets('event', (t) async => shoot(t, await seed(), 'event_dark', route: '/event/3'));
  testWidgets('share sheet', (t) async => shoot(t, await seed(), 'share_dark', tap: 'Share'));
  testWidgets('messages', (t) async => shoot(t, await seed(theme: 'light'), 'messages_light', route: '/messages'));
  testWidgets('calendar', (t) async => shoot(t, await seed(), 'calendar_dark', route: '/calendar'));
}

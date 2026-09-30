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
import 'package:smriti/features/cards/card_screen.dart';
import 'package:smriti/features/family/family.dart';
import 'package:smriti/features/cards/card_templates.dart';
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
    await repo.addGift(appa, 'Reading glasses stand', budget: 1800);
    await repo.addGift(appa, 'Mysore Pak from Guru Sweets', budget: 600);
    await repo.addGift(chinnu, 'Watercolour set', budget: 900);
    final family = await repo.addGroup('Family');
    await repo.setGroupMembers(family, {appa, amma, chinnu, ravi, priya});
    await repo.addGroup('Office', color: 1);
    return db;
  }

  Future<void> shoot(WidgetTester tester, AppDatabase db, String name,
      {String? route, Object? extra, String? tap, double scroll = 0}) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const SmritiApp(),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (route != null) {
      tester.element(find.byType(Scaffold).first).push(route, extra: extra);
      for (var i = 0; i < 25; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
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
    if (scroll > 0) {
      await tester.drag(find.byType(Scrollable).last, Offset(0, -scroll));
      for (var i = 0; i < 5; i++) {
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
  testWidgets('festivals', (t) async => shoot(t, await seed(), 'festivals_dark', route: '/festivals'));
  testWidgets('wish mode', (t) async {
    final db = await seed(theme: 'light');
    await db.into(db.wishSessions).insert(WishSessionsCompanion.insert(
        title: 'Diwali wishes', festivalId: const Value('b:diwali_lakshmi_puja'), occasionDate: '2026-11-08'));
    for (var i = 2; i <= 6; i++) {
      await db.into(db.wishSessionItems).insert(WishSessionItemsCompanion.insert(
          sessionId: 1, personId: i, position: i, status: Value(i == 2 ? 'wished' : 'pending')));
    }
    await shoot(t, db, 'wishmode_light', route: '/wish-mode/1');
  });
  testWidgets('calendar', (t) async => shoot(t, await seed(), 'calendar_dark', route: '/calendar'));
  testWidgets('home lower', (t) async => shoot(t, await seed(theme: 'light'), 'home_lower_light', scroll: 600));
  testWidgets('home people only', (t) async {
    final db = await seed();
    await db.setSetting('showFestivals', 'false');
    await db.setSetting('showImportant', 'false');
    await shoot(t, db, 'home_people_only_dark', scroll: 500);
  });
  testWidgets('family tree', (t) async {
    final db = await seed();
    final r = Repository(db);
    Future<Person> p(int id) async => (await r.allPeople()).firstWhere((x) => x.id == id);
    final fam = FamilyRepo(db);
    final me = await p(1);
    await fam.link(me, await p(2), FamilyRel.father);
    await fam.link(me, await p(6), FamilyRel.mother);
    await fam.link(me, await p(3), FamilyRel.niece);
    final wife = await r.insertPerson(PeopleCompanion.insert(name: 'Deepa'));
    await fam.link(me, await p(wife), FamilyRel.wife);
    final son = await r.insertPerson(PeopleCompanion.insert(name: 'Aarav'));
    await fam.link(me, await p(son), FamilyRel.son);
    final gm = await r.insertPerson(PeopleCompanion.insert(name: 'Kamala Katti', nickname: const Value('Ajji')));
    await fam.link(me, await p(gm), FamilyRel.grandmother);
    final sis = await r.insertPerson(PeopleCompanion.insert(name: 'Ria Katti'));
    await fam.link(await p(2), await p(sis), FamilyRel.daughter);
    await shoot(t, db, 'family_tree_dark', route: '/person/1/family');
  });
  testWidgets('settings', (t) async => shoot(t, await seed(), 'settings_dark', route: '/settings', scroll: 900));
  testWidgets('profile lower', (t) async => shoot(t, await seed(), 'profile_lower_dark', route: '/person/2', scroll: 700));
  testWidgets('gift planner', (t) async => shoot(t, await seed(theme: 'light'), 'gifts_light', route: '/gifts'));
  testWidgets('group', (t) async => shoot(t, await seed(), 'group_dark', route: '/group/1'));
  testWidgets('export', (t) async => shoot(t, await seed(theme: 'light'), 'export_light', route: '/export'));
  testWidgets('card studio', (t) async => shoot(t, await seed(), 'card_dark',
      route: '/card',
      extra: const CardRequest(CardData(
        kind: CardKind.milestone,
        headline: 'Happy 60th Birthday',
        name: 'Appa',
        message: 'Sixty years of love, patience and the best advice. Wishing you health and happiness always.',
        footer: '— Niranjan',
        years: 60,
      ))));
}

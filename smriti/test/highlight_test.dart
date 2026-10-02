import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/theme/app_theme.dart';
import 'package:smriti/core/util/occurrence.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/models.dart';
import 'package:smriti/data/providers.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/highlight/highlight.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('lights up dates within the chosen window until wished', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final r = Repository(db);
    final p = await r.insertPerson(PeopleCompanion.insert(name: 'Shanta'));
    final id = await r.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 9, month: 10), personIds: [p]);
    final e = (await r.watchEntry(id).first)!;
    Upcoming at(int days) => Upcoming(e, const Day(2026, 10, 9), days);
    const prefs = HighlightPrefs();
    expect(prefs.lights(at(0), {}), isTrue);
    expect(prefs.lights(at(1), {}), isTrue, reason: 'within 24 hours');
    expect(prefs.lights(at(2), {}), isFalse);
    expect(prefs.copyWith(window: FrameWindow.week).lights(at(7), {}), isTrue);
    expect(prefs.copyWith(window: FrameWindow.today).lights(at(1), {}), isFalse);
    expect(prefs.lights(at(0), {'$id|2026-10-09'}), isFalse, reason: 'already wished');
    expect(prefs.copyWith(stopWhenWished: false).lights(at(0), {'$id|2026-10-09'}), isTrue);
    expect(prefs.copyWith(on: false).lights(at(0), {}), isFalse);
    final back = HighlightPrefs.parse(prefs.copyWith(style: FrameStyle.comet, palette: FramePalette.fire).toJson());
    expect((back.style, back.palette, back.window), (FrameStyle.comet, FramePalette.fire, FrameWindow.day));
    await db.close();
  });

  testWidgets('every style and colour draws', (tester) async {
    for (final s in FrameStyle.values) {
      for (final c in [FramePalette.neon, FramePalette.rainbow]) {
        await tester.pumpWidget(MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 90,
              child: GlowFrame(prefs: HighlightPrefs(style: s, palette: c), child: const SizedBox.expand()),
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull, reason: '${s.name} ${c.name}');
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings screen saves a chosen style', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: buildTheme(Brightness.dark), home: const HighlightScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.text('Comet'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Comet'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(HighlightPrefs.parse(await db.getSetting('highlight')).style, FrameStyle.comet);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}

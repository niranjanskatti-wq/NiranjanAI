import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/theme/app_theme.dart';
import 'package:smriti/data/database.dart';
import 'package:smriti/data/providers.dart';
import 'package:smriti/data/repository.dart';
import 'package:smriti/features/widget/home_widget_service.dart';
import 'package:smriti/features/widget/widget_glow.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('flash settings survive saving and fall back to the gold pulse', () {
    for (final (_, _, p) in WidgetGlow.presets) {
      expect(WidgetGlow.parse(p.toJson()).same(p), isTrue);
    }
    final custom = const WidgetGlow()
        .copyWith(color: WidgetGlow.colors['Purple'], style: GlowStyle.blink, speed: GlowSpeed.slow, width: GlowWidth.thin);
    expect(custom.toJson(), '{"c":"#B07CFF","s":"blink","v":1800,"w":"thin"}');
    expect(WidgetGlow.parse(custom.toJson()).summary, 'Purple · blink · slow');
    expect(WidgetGlow.parse(null).summary, 'Normal · pulse · medium');
    expect(WidgetGlow.parse('not json').same(const WidgetGlow()), isTrue);
    expect(WidgetGlow.presets.first.$3.summary, 'Very urgent · blink · fast');
  });

  test('widget taps: Done marks as wished, a name opens its page', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repository(db);
    final p = await repo.insertPerson(PeopleCompanion.insert(name: 'Shanta'));
    final e = await repo.saveEvent(
        data: EventsCompanion.insert(kind: 'person', type: 'birthday', day: 30, month: 9), personIds: [p]);

    expect(await HomeWidgetService.handleTap(Uri.parse('smriti://open/?k=$e'), repo), '/event/$e');
    expect(await HomeWidgetService.handleTap(Uri.parse('smriti://open?k=diwali'), repo), '/festival?key=diwali');
    expect(await HomeWidgetService.handleTap(Uri.parse('smriti://done?k=$e&d=2026-09-30'), repo), 'done');
    final log = (await db.select(db.wishLogs).get()).single;
    expect((log.eventId, log.personId, log.occasionDate, log.confirmed), (e, p, '2026-09-30', true));
    expect(await HomeWidgetService.handleTap(Uri.parse('https://example.com'), repo), isNull);
    await db.close();
  });

  testWidgets('flash screen: picking a ready-made choice saves it', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(theme: buildTheme(Brightness.dark), home: const WidgetGlowScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 to wish'), findsOneWidget);
    await tester.tap(find.text('Very urgent'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(WidgetGlow.parse(await db.getSetting('widgetGlow')).style, GlowStyle.blink);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  });
}

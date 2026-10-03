@Tags(['screenshots'])
library;

import 'package:deepwork/core/settings.dart';
import 'package:deepwork/features/focus/focus_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Renders the main screens to test/screens/*.png for visual review.
/// Run: flutter test --tags screenshots --update-goldens
void main() {
  setUpAll(loadAppFonts);

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester, 6);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/$name.png'));
  }

  for (final theme in ['dark', 'light']) {
    testWidgets('screens ($theme)', (tester) async {
      final s = AppSettings.defaults().set('appearance.theme', theme);
      final h = await pumpApp(tester, settings: s, demo: true);
      await shot(tester, '$theme-01-today');
      await go(tester, h, '/tasks');
      await shot(tester, '$theme-02-tasks');
      await go(tester, h, '/insights');
      await shot(tester, '$theme-03-insights');
      await go(tester, h, '/focus');
      await shot(tester, '$theme-04-focus-setup');
      await go(tester, h, '/settings');
      await shot(tester, '$theme-05-settings');
      await go(tester, h, '/settings/customize');
      await shot(tester, '$theme-06-customize');
      await go(tester, h, '/review/evening');
      await shot(tester, '$theme-07-evening-review');
      await go(tester, h, '/review/weekly');
      await shot(tester, '$theme-08-weekly-review');
      await unmount(tester, h);
    });
  }

  testWidgets('focus states', (tester) async {
    final started = DateTime.now().subtract(const Duration(minutes: 9)).millisecondsSinceEpoch;
    final h = await pumpApp(tester, demo: true, focus: FocusState(phase: FocusPhase.running, sessionId: 'x', plannedSec: 1500, startedAt: started));
    await go(tester, h, '/focus');
    await shot(tester, 'dark-09-focus-running');
    await unmount(tester, h);

    final done = DateTime.now().subtract(const Duration(minutes: 26)).millisecondsSinceEpoch;
    final h2 = await pumpApp(tester, focus: FocusState(phase: FocusPhase.running, sessionId: 'y', plannedSec: 1500, startedAt: done));
    await go(tester, h2, '/focus');
    await shot(tester, 'dark-10-session-close');
    await unmount(tester, h2);

    final h3 = await pumpApp(tester, focus: FocusState(phase: FocusPhase.ended, sessionId: 'z', plannedSec: 1500, startedAt: done, actualSec: 600, endReason: 'Out of energy', result: 'interrupted'));
    await go(tester, h3, '/focus');
    await shot(tester, 'dark-11-interrupted');
    await unmount(tester, h3);
  });

  testWidgets('tablet layout', (tester) async {
    final h = await pumpApp(tester, demo: true, size: const Size(1100, 800));
    await shot(tester, 'tablet-01-today');
    await go(tester, h, '/insights');
    await shot(tester, 'tablet-02-insights');
    await unmount(tester, h);
  });

  testWidgets('lock screen', (tester) async {
    final s = AppSettings.defaults().edit((m) {
      m['lock']['enabled'] = true;
      m['lock']['pinHash'] = 'x';
      m['lock']['pinSalt'] = 'y';
    });
    final h = await pumpApp(tester, settings: s);
    await shot(tester, 'dark-12-lock');
    await unmount(tester, h);
  });
}

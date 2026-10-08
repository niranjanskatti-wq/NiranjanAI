import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldvault/app.dart';
import 'package:goldvault/core/app_controller.dart';
import 'package:goldvault/core/security.dart';
import 'package:goldvault/data/repository.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers.dart';

/// Lets real database futures complete and the UI rebuild (spinners never
/// "settle", so pumpAndSettle can't be used while data loads).
Future<void> settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Drives the real UI with the real database (no network, no Google).
void main() {
  testWidgets('first run: set PIN, quick-add an ornament, browse tabs, switch to Kannada, auto-lock', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await initializeDateFormatting();

    late AppLock lock;
    late AppController ctrl;
    late VaultRepo repo;
    await tester.runAsync(() async {
      final svc = await testServices();
      repo = svc.repo;
      lock = AppLock(svc.secure);
      await lock.init();
      ctrl = AppController(svc);
      await ctrl.load();
    });

    await tester.pumpWidget(GoldVaultApp(controller: ctrl, lock: lock));
    await tester.pump(const Duration(milliseconds: 500));

    // PIN setup (4 digits, twice). PBKDF2 runs for real, so give it time.
    expect(find.text('Create a 4-digit PIN'), findsOneWidget);
    for (final d in ['1', '9', '7', '3']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    expect(find.text('Enter the PIN again'), findsOneWidget);
    for (final d in ['1', '9', '7', '3']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await tester.pump(const Duration(seconds: 1));
    expect(lock.locked, isFalse);
    expect(find.text('Where is my ornament?'), findsOneWidget);

    // Quick add from the home screen.
    await tester.tap(find.text('Add Ornament').first);
    await settle(tester);
    await tester.tap(find.text('Quick add'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Kasu mala');
    await tester.enterText(find.widgetWithText(TextFormField, 'Weight'), '42.5');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);
    final items = await tester.runAsync(() => repo.items(const ItemQuery()));
    expect(items!.single.name, 'Kasu mala');
    expect(items.single.serial, 'GV-0001');
    expect(items.single.grossWt, 42.5);
    expect(items.single.needsDetails, isTrue);
    expect(find.text('GV-0001'), findsWidgets); // item detail page

    // Back to the shell and open each tab.
    await tester.pageBack();
    await settle(tester);
    for (final tab in ['Ornaments', 'Lockers', 'Visits', 'More']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
    }
    expect(find.text('Language'), findsOneWidget);

    // Switch language to Kannada.
    await tester.tap(find.text('ಕನ್ನಡ'));
    await settle(tester);
    expect(find.text('ಭಾಷೆ'), findsOneWidget);
    expect(find.text('ಆಭರಣಗಳು'), findsWidgets);

    // Lock now → lock screen overlays, navigation state kept underneath.
    lock.lock();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ನಿಮ್ಮ PIN ನಮೂದಿಸಿ'), findsOneWidget);

    // Tear down: cancel the auto-sync debounce and any reveal timers.
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
    await tester.pump(const Duration(seconds: 30));
  });
}

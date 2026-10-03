import 'package:deepwork/core/settings.dart';
import 'package:deepwork/data/providers.dart';
import 'package:deepwork/features/focus/focus_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void main() {
  testWidgets('Today shows greeting, start focus and every default section', (tester) async {
    final h = await pumpApp(tester);
    expect(find.text('Start focus'), findsOneWidget);
    expect(find.text('Top priorities'), findsOneWidget);
    expect(find.text('Time blocks'), findsOneWidget);
    expect(find.textContaining('streak'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    await unmount(tester, h);
  });

  testWidgets('turning modules off hides them from navigation and Today', (tester) async {
    var s = AppSettings.defaults();
    for (final m in modules) {
      if (!m.locked) s = s.set('modules.${m.key}', false);
    }
    final h = await pumpApp(tester, settings: s);
    expect(find.text('Start focus'), findsOneWidget);
    expect(find.text('Top priorities'), findsNothing);
    expect(find.text('Time blocks'), findsNothing);
    expect(find.text('Tasks'), findsNothing);
    expect(find.text('Insights'), findsNothing);
    expect(tester.takeException(), isNull);
    await unmount(tester, h);
  });

  testWidgets('quick add a task on the Tasks screen', (tester) async {
    final h = await pumpApp(tester);
    await go(tester, h, '/tasks');
    await tester.enterText(find.byType(TextField).first, 'Write the intro');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text('Write the intro'), findsOneWidget);
    await unmount(tester, h);
  });

  testWidgets('start a focus session on a new task, pause and resume', (tester) async {
    final h = await pumpApp(tester);
    await go(tester, h, '/focus');
    await tester.enterText(find.byType(TextField).first, 'Outline chapter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    await tapText(tester, 'Start 25-minute session', contains: true);
    await settle(tester);
    expect(h.container.read(focusProvider).phase, FocusPhase.running);
    expect(find.text('Distracted'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Pause'));
    await settle(tester, 3);
    expect(h.container.read(focusProvider).phase, FocusPhase.paused);
    expect(find.text('paused'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Resume'));
    await settle(tester, 3);
    expect(h.container.read(focusProvider).phase, FocusPhase.running);
    await unmount(tester, h);
  });

  testWidgets('a session that ran out while the app was closed opens the close form; stuck adds next steps', (tester) async {
    final started = DateTime.now().subtract(const Duration(minutes: 26)).millisecondsSinceEpoch;
    final h = await pumpApp(tester, focus: FocusState(phase: FocusPhase.running, sessionId: 's1', plannedSec: 1500, startedAt: started));
    await go(tester, h, '/focus');
    expect(h.container.read(focusProvider).phase, FocusPhase.finished);
    expect(find.text('How did it go?'), findsOneWidget);
    await tapText(tester, 'Stuck');
    await settle(tester, 4);
    await tester.enterText(find.widgetWithText(TextField, 'e.g. Write the first heading'), 'List three headings');
    await tapText(tester, 'Save session');
    await settle(tester);
    expect(h.container.read(focusProvider).phase, FocusPhase.closed);
    final sessions = await tester.runAsync(() => h.db.select(h.db.sessions).get());
    expect(sessions!.single.result, 'stuck');
    final tasks = await tester.runAsync(() => h.db.select(h.db.tasks).get());
    expect(tasks!.map((t) => t.title), contains('List three headings'));
    expect(find.textContaining('break'), findsWidgets);
    await tapText(tester, '-minute short break', contains: true);
    await settle(tester, 4);
    expect(h.container.read(focusProvider).phase, FocusPhase.breakTime);
    await unmount(tester, h);
  });

  testWidgets('ending early logs an interrupted session', (tester) async {
    final started = DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
    final h = await pumpApp(tester, focus: FocusState(phase: FocusPhase.running, sessionId: 's2', plannedSec: 1500, startedAt: started));
    await go(tester, h, '/focus');
    await tapText(tester, 'End');
    await settle(tester, 6);
    await tapText(tester, 'Out of energy');
    await settle(tester);
    expect(find.text('Session ended early'), findsOneWidget);
    final sessions = await tester.runAsync(() => h.db.select(h.db.sessions).get());
    expect(sessions!.single.result, 'interrupted');
    expect(sessions.single.actualDuration, closeTo(300, 5));
    await unmount(tester, h);
  });

  testWidgets('insights and reviews render with demo data', (tester) async {
    final h = await pumpApp(tester, demo: true);
    await go(tester, h, '/insights');
    expect(find.text('Focus hours'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await go(tester, h, '/review/weekly');
    expect(find.textContaining('Best focus time'), findsOneWidget);
    await go(tester, h, '/review/evening');
    expect(find.text('Planned vs. done'), findsOneWidget);
    await go(tester, h, '/reviews');
    expect(find.text('Reviews'), findsWidgets);
    expect(tester.takeException(), isNull);
    await unmount(tester, h);
  });

  testWidgets('every settings page opens', (tester) async {
    final h = await pumpApp(tester);
    for (final id in ['features', 'customize', 'appearance', 'notifications', 'privacy', 'backup', 'data', 'about']) {
      await go(tester, h, '/settings/$id');
      expect(tester.takeException(), isNull, reason: id);
    }
    await unmount(tester, h);
  });

  testWidgets('app lock shows the PIN pad', (tester) async {
    final s = AppSettings.defaults().edit((m) {
      m['lock']['enabled'] = true;
      m['lock']['pinHash'] = 'x';
      m['lock']['pinSalt'] = 'y';
    });
    final h = await pumpApp(tester, settings: s);
    expect(find.text('Enter your PIN'), findsOneWidget);
    await unmount(tester, h);
  });

  testWidgets('settings changes persist to the database', (tester) async {
    final h = await pumpApp(tester);
    await h.container.read(settingsProvider.notifier).set('priorities.count', 2);
    final stored = await tester.runAsync(() => loadSettings(h.db));
    expect(stored!.priorityCount, 2);
    await unmount(tester, h);
  });
}

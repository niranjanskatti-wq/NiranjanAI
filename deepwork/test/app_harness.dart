import 'dart:io';

import 'package:deepwork/app.dart';
import 'package:deepwork/core/settings.dart';
import 'package:deepwork/data/database.dart';
import 'package:deepwork/data/demo.dart';
import 'package:deepwork/data/providers.dart';
import 'package:deepwork/data/repository.dart';
import 'package:deepwork/features/focus/focus_controller.dart';
import 'package:deepwork/services/audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Loads the bundled fonts (and Material icons) so screenshots look like the real app.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Inter', ['assets/fonts/Inter-Regular.ttf', 'assets/fonts/Inter-Medium.ttf', 'assets/fonts/Inter-SemiBold.ttf', 'assets/fonts/Inter-Bold.ttf']);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await load('MaterialIcons', [icons.path]);
}

class Harness {
  Harness(this.db, this.container);
  final AppDatabase db;
  final ProviderContainer container;
}

/// Pumps the whole app on an in-memory database.
Future<Harness> pumpApp(
  WidgetTester tester, {
  AppSettings? settings,
  FocusState focus = const FocusState(),
  bool demo = false,
  Size size = const Size(400, 860),
  Future<void> Function(AppDatabase db)? seed,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  soundEnabled = false;
  // The audio plugin has no host implementation in tests.
  for (final ch in ['com.ryanheise.just_audio.methods', 'com.ryanheise.audio_session']) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(MethodChannel(ch), (call) async => null);
  }
  final db = memoryDb();
  await tester.runAsync(() async {
    await Repository(db).seedDefaults();
    if (demo) await loadDemoData(db);
    if (seed != null) await seed(db);
  });
  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    initialSettingsProvider.overrideWithValue(settings ?? AppSettings.defaults()),
    initialFocusProvider.overrideWithValue(focus),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeepworkApp()));
  await settle(tester);
  return Harness(db, container);
}

/// Lets database streams deliver and animations finish (the app has periodic timers, so
/// pumpAndSettle would never settle).
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> unmount(WidgetTester tester, [Harness? h]) async {
  await tester.pumpWidget(const SizedBox());
  h?.container.dispose();
  // Let drift's stream cleanup and any delayed callbacks run out.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 5));
  }
}

Future<void> tapText(WidgetTester tester, String text, {bool contains = false}) async {
  final f = (contains ? find.textContaining(text) : find.text(text)).first;
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(f);
}

Future<void> go(WidgetTester tester, Harness h, String location) async {
  h.container.read(routerProvider).go(location);
  await settle(tester);
}

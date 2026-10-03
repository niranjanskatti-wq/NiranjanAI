import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/providers.dart';
import 'data/repository.dart';
import 'features/focus/focus_controller.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final db = AppDatabase();
  await Repository(db).seedDefaults();
  final settings = await loadSettings(db);
  final focus = await loadFocusState(db);
  await Notifications.init();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(settings),
      initialFocusProvider.overrideWithValue(focus),
    ],
    child: const DeepworkApp(),
  ));
}

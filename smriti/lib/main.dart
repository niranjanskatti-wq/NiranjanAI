import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/festivals/festival_alarms.dart';
import 'features/reminders/alarm_scheduler.dart';
import 'features/reminders/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initTimeZones();
  AlarmScheduler.extraSources.add(festivalAlarms);
  runApp(const ProviderScope(child: SmritiApp()));
  // Notifications and the background refresh start after the first frame so
  // the app opens quickly.
  await NotificationService.init();
  await AlarmScheduler.registerBackground();
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/app_controller.dart';
import 'core/app_services.dart';
import 'core/security.dart';
import 'core/theme.dart';
import 'services/background.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: GV.surface,
    statusBarIconBrightness: Brightness.light,
  ));
  await initializeDateFormatting();
  try {
    final svc = await AppServices.init();
    final lock = AppLock(svc.secure, timeout: Duration(seconds: (await svc.repo.prefs()).autoLockSeconds));
    await lock.init();
    final ctrl = AppController(svc);
    await ctrl.load();
    await Notifier.init();
    await Background.init();
    runApp(GoldVaultApp(controller: ctrl, lock: lock));
  } catch (e, st) {
    debugPrint('$e\n$st');
    runApp(MaterialApp(
      theme: GV.theme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('GoldVault could not open its secure database.\n\n$e',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    ));
  }
}

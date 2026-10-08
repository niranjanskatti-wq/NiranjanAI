import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_controller.dart';
import 'core/security.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/lock_screen.dart';

class GoldVaultApp extends StatelessWidget {
  const GoldVaultApp({super.key, required this.controller, required this.lock});
  final AppController controller;
  final AppLock lock;

  static late AppController ctrl;
  static late AppLock appLock;

  @override
  Widget build(BuildContext context) {
    ctrl = controller;
    appLock = lock;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        title: 'GoldVault',
        debugShowCheckedModeBanner: false,
        theme: GV.theme(),
        darkTheme: GV.theme(),
        themeMode: ThemeMode.dark,
        locale: controller.locale,
        supportedLocales: S.supported,
        localizationsDelegates: const [
          SDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // The lock is an overlay so navigation state survives auto-lock.
        builder: (context, child) => ListenableBuilder(
          listenable: lock,
          builder: (context, _) => Stack(children: [
            ?child,
            if (lock.locked)
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: LockScreen(key: ValueKey(lock.hasPin), lock: lock),
                ),
              ),
          ]),
        ),
        home: const HomeShell(),
      ),
    );
  }
}

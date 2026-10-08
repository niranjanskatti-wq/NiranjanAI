import 'package:flutter/material.dart';

import '../../core/security.dart';
import '../../core/strings.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'locations_screen.dart';
import 'settings_screen.dart';
import 'visits_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  static final GlobalKey<HomeShellState> shellKey = GlobalKey();
  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _guarded = false;

  // Dashboard and Locations show values and locker details.
  static const _sensitiveTabs = {0, 2};

  @override
  void initState() {
    super.initState();
    _guard();
  }

  void _guard() {
    final want = _sensitiveTabs.contains(_index);
    if (want && !_guarded) ScreenGuard.push();
    if (!want && _guarded) ScreenGuard.pop();
    _guarded = want;
  }

  void go(int i) {
    setState(() => _index = i);
    _guard();
  }

  @override
  void dispose() {
    if (_guarded) ScreenGuard.pop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onOpenTab: go),
      const InventoryScreen(),
      const LocationsScreen(),
      const VisitsScreen(),
      const SettingsScreen(),
    ];
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) go(0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: go,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.space_dashboard_outlined), selectedIcon: const Icon(Icons.space_dashboard), label: context.t('nav.home')),
            NavigationDestination(icon: const Icon(Icons.diamond_outlined), selectedIcon: const Icon(Icons.diamond), label: context.t('nav.items')),
            NavigationDestination(icon: const Icon(Icons.account_balance_outlined), selectedIcon: const Icon(Icons.account_balance), label: context.t('nav.places')),
            NavigationDestination(icon: const Icon(Icons.event_note_outlined), selectedIcon: const Icon(Icons.event_note), label: context.t('nav.visits')),
            NavigationDestination(icon: const Icon(Icons.tune_outlined), selectedIcon: const Icon(Icons.tune), label: context.t('nav.more')),
          ],
        ),
      ),
    );
  }
}

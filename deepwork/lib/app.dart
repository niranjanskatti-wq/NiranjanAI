import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'core/util/format.dart';
import 'data/providers.dart';
import 'features/backup/backup_service.dart';
import 'features/focus/focus_controller.dart';
import 'features/focus/focus_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/lock/lock_gate.dart';
import 'features/review/review_screens.dart';
import 'features/settings/settings_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/today/today_screen.dart';
import 'services/notifications.dart';
import 'ui/brand.dart';

class NavItem {
  const NavItem(this.path, this.label, this.icon, this.activeIcon, {this.module});
  final String path, label;
  final IconData icon, activeIcon;
  final String? module;
}

const navItems = [
  NavItem('/', 'Today', Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
  NavItem('/focus', 'Focus', Icons.timer_outlined, Icons.timer_rounded),
  NavItem('/tasks', 'Tasks', Icons.checklist_rounded, Icons.checklist_rounded, module: 'tasks'),
  NavItem('/insights', 'Insights', Icons.insights_outlined, Icons.insights_rounded, module: 'insights'),
  NavItem('/settings', 'Settings', Icons.tune_outlined, Icons.tune_rounded),
];

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  String? guard(String? module) {
    if (module == null) return null;
    return ref.read(settingsProvider).on(module) ? null : '/';
  }

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (c, s) => const NoTransitionPage(child: TodayScreen())),
          GoRoute(
            path: '/focus',
            pageBuilder: (c, s) => NoTransitionPage(
              child: FocusScreen(initialTaskId: s.uri.queryParameters['task'], initialMinutes: int.tryParse(s.uri.queryParameters['minutes'] ?? '')),
            ),
          ),
          GoRoute(path: '/tasks', redirect: (c, s) => guard('tasks'), pageBuilder: (c, s) => const NoTransitionPage(child: TasksScreen())),
          GoRoute(path: '/insights', redirect: (c, s) => guard('insights'), pageBuilder: (c, s) => const NoTransitionPage(child: InsightsScreen())),
          GoRoute(path: '/settings', pageBuilder: (c, s) => const NoTransitionPage(child: SettingsScreen())),
        ],
      ),
      GoRoute(parentNavigatorKey: rootKey, path: '/settings/:section', builder: (c, s) => SettingsScreen(section: s.pathParameters['section'])),
      GoRoute(parentNavigatorKey: rootKey, path: '/reviews', redirect: (c, s) => ref.read(settingsProvider).on('eveningReview') || ref.read(settingsProvider).on('weeklyReview') ? null : '/', builder: (c, s) => const ReviewsScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/review/evening', redirect: (c, s) => guard('eveningReview'), builder: (c, s) => const EveningReviewScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/review/weekly', redirect: (c, s) => guard('weeklyReview'), builder: (c, s) => const WeeklyReviewScreen()),
    ],
  );
});

class DeepworkApp extends ConsumerStatefulWidget {
  const DeepworkApp({super.key});
  @override
  ConsumerState<DeepworkApp> createState() => _DeepworkAppState();
}

class _DeepworkAppState extends ConsumerState<DeepworkApp> with WidgetsBindingObserver {
  Timer? _startupBackup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _background();
      _startupBackup = Timer(const Duration(seconds: 3), _maybeBackup);
    });
  }

  @override
  void dispose() {
    _startupBackup?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _background();
      _maybeBackup();
    }
  }

  /// Re-plans reminders (they're scheduled with Android a week ahead).
  Future<void> _background() async {
    if (!mounted) return;
    final reviews = await ref.read(databaseProvider).select(ref.read(databaseProvider).reviews).get();
    final st = await reviewStateFor(reviews);
    if (!mounted) return;
    await Notifications.rescheduleReminders(ref.read(settingsProvider), eveningDoneToday: st.eveningDoneToday, weeklyDoneAt: st.weeklyDoneAt);
  }

  /// The weekly backup runs when the app is opened and a backup is due.
  Future<void> _maybeBackup() async {
    if (!mounted) return;
    final s = ref.read(settingsProvider);
    if (!isBackupDue(s)) return;
    final last = s['backup.lastAttemptAt'] as num?;
    if (last != null && s.b('backup.needsReconnect') && DateTime.now().millisecondsSinceEpoch - last < 10 * 60000) return;
    await runBackup(ref.read(settingsProvider.notifier), ref.read(databaseProvider), interactive: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    // Keep reminders in sync with settings and reviews.
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.json['notifications'] != next.json['notifications'] ||
          prev?.json['modules'] != next.json['modules'] ||
          prev?.s('eveningReview.time') != next.s('eveningReview.time') ||
          prev?.json['weeklyReview'] != next.json['weeklyReview']) {
        _background();
      }
    });
    ref.listen(reviewsProvider, (_, _) => _background());
    final mode = switch (s.s('appearance.theme')) { 'light' => ThemeMode.light, 'system' => ThemeMode.system, _ => ThemeMode.dark };
    final systemReduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    return MaterialApp.router(
      title: 'Deepwork',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: buildTheme(s, Brightness.light, systemReduceMotion: systemReduce),
      darkTheme: buildTheme(s, Brightness.dark, systemReduceMotion: systemReduce),
      themeAnimationDuration: s.s('appearance.animations') == 'off' ? Duration.zero : const Duration(milliseconds: 250),
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final off = s.s('appearance.animations') == 'off';
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1) * textScaleFor(s)), disableAnimations: off || mq.disableAnimations),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light.copyWith(systemNavigationBarColor: Colors.transparent) : SystemUiOverlayStyle.dark.copyWith(systemNavigationBarColor: Colors.transparent),
            child: LockGate(child: child ?? const SizedBox()),
          ),
        );
      },
    );
  }
}

/// Bottom tabs on phones, a collapsible sidebar on tablets. Turned-off modules disappear.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool collapsed = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final p = context.pal;
    final focus = ref.watch(focusProvider);
    final items = navItems.where((i) => i.module == null || s.on(i.module!)).toList();
    final loc = widget.location;
    final index = items.indexWhere((i) => i.path == '/' ? loc == '/' : loc.startsWith(i.path));
    final inFocus = loc.startsWith('/focus');
    final hideNav = inFocus && focus.phase != FocusPhase.idle;
    final wide = MediaQuery.sizeOf(context).width >= 840;

    final body = Stack(children: [
      widget.child,
      if (focus.phase != FocusPhase.idle && !inFocus) Positioned(left: 16, right: 16, bottom: 12, child: Center(child: _FocusPill(state: focus))),
    ]);

    if (wide) {
      return Scaffold(
        body: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: collapsed ? 72 : 232,
            decoration: BoxDecoration(color: p.bg, border: Border(right: BorderSide(color: p.border))),
            child: SafeArea(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(collapsed ? 0 : 18, 18, 0, 18),
                  child: Row(mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                    const DeepworkMark(size: 30),
                    if (!collapsed) ...[const SizedBox(width: 10), const Text('Deepwork', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))],
                  ]),
                ),
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: Material(
                      color: i == index ? p.card : Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: i == index ? p.border : Colors.transparent)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go(items[i].path),
                        child: SizedBox(
                          height: 44,
                          child: Row(mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                            if (!collapsed) const SizedBox(width: 12),
                            Icon(i == index ? items[i].activeIcon : items[i].icon, size: 20, color: i == index ? p.accent : p.muted),
                            if (!collapsed) ...[const SizedBox(width: 12), Text(items[i].label, style: TextStyle(fontWeight: FontWeight.w500, color: i == index ? p.fg : p.muted))],
                          ]),
                        ),
                      ),
                    ),
                  ),
                if (s.on('eveningReview') || s.on('weeklyReview'))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/reviews'),
                      child: SizedBox(
                        height: 44,
                        child: Row(mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                          if (!collapsed) const SizedBox(width: 12),
                          Icon(Icons.edit_note_rounded, size: 21, color: p.muted),
                          if (!collapsed) ...[const SizedBox(width: 12), Text('Reviews', style: TextStyle(fontWeight: FontWeight.w500, color: p.muted))],
                        ]),
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: () => setState(() => collapsed = !collapsed),
                  icon: Icon(collapsed ? Icons.keyboard_double_arrow_right_rounded : Icons.keyboard_double_arrow_left_rounded, color: p.muted),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          Expanded(child: body),
        ]),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: hideNav
          ? null
          : Container(
              decoration: BoxDecoration(color: p.bg.withValues(alpha: 0.96), border: Border(top: BorderSide(color: p.border))),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Row(children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: InkResponse(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go(items[i].path);
                          },
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            AnimatedScale(
                              scale: i == index ? 1.08 : 1,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(i == index ? items[i].activeIcon : items[i].icon, size: 23, color: i == index ? p.accent : p.muted),
                            ),
                            const SizedBox(height: 3),
                            Text(items[i].label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: i == index ? p.accent : p.muted)),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _FocusPill extends ConsumerStatefulWidget {
  const _FocusPill({required this.state});
  final FocusState state;
  @override
  ConsumerState<_FocusPill> createState() => _FocusPillState();
}

class _FocusPillState extends ConsumerState<_FocusPill> {
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final st = widget.state;
    final hide = ref.watch(settingsProvider).b('focus.hideSeconds');
    var label = 'Session';
    var time = '';
    switch (st.phase) {
      case FocusPhase.running || FocusPhase.paused:
        final el = st.elapsedSec();
        time = formatTimer(st.countUp ? el : st.plannedSec - el, hideSeconds: hide);
        label = st.phase == FocusPhase.paused ? 'Paused' : 'Focusing';
      case FocusPhase.breakTime:
        time = formatTimer(st.breakSec - st.breakElapsedSec(), hideSeconds: hide);
        label = 'Break';
      case FocusPhase.finished:
        label = 'Session complete — close it out';
      case FocusPhase.breakOver:
        label = 'Break over';
      default:
        label = 'Session ended';
    }
    return GestureDetector(
      onTap: () => context.go('/focus'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: p.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 26, height: 26, decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle), child: Icon(Icons.timer_rounded, size: 15, color: p.accent)),
          const SizedBox(width: 10),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
          if (time.isNotEmpty) ...[const SizedBox(width: 8), Text(time, style: TextStyle(color: p.muted, fontFeatures: tabular))],
        ]),
      ),
    );
  }
}

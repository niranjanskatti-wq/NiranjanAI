import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'core/util/occurrence.dart';
import 'data/providers.dart';
import 'features/autocall/auto_call.dart';
import 'features/backup/backup_screen.dart';
import 'features/backup/backup_service.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/calendar_sync/calendar_sync.dart';
import 'features/calendar_sync/calendar_import_screen.dart';
import 'features/calendar_sync/calendar_sync_screen.dart';
import 'features/cards/card_screen.dart';
import 'features/export/export_screen.dart';
import 'features/export/import_screen.dart';
import 'features/contacts/bulk_add_screen.dart';
import 'features/contacts/contact_sync.dart';
import 'features/contacts/duplicates.dart';
import 'features/contacts/duplicates_screen.dart';
import 'features/contacts/import_birthdays_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/events/event_form_screen.dart';
import 'features/festivals/festival_model.dart';
import 'features/festivals/festivals_screen.dart';
import 'features/family/family.dart';
import 'features/gifts/gifts.dart';
import 'features/groups/groups_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lock/app_lock.dart';
import 'features/widget/home_widget_service.dart';
import 'features/widget/widget_glow.dart';
import 'features/memories/memories.dart';
import 'features/wishmode/wish_mode_runner.dart';
import 'features/wishmode/wish_mode_setup.dart';
import 'features/messages/event_message_screen.dart';
import 'features/messages/library_screen.dart';
import 'features/messages/thank_you_screen.dart';
import 'features/reminders/alarm_scheduler.dart';
import 'features/reminders/alarm_screen.dart';
import 'features/reminders/notification_service.dart';
import 'features/reminders/reliability_screen.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/wish/not_wished_screen.dart';
import 'features/wish/wish_buttons.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/people/archived_screen.dart';
import 'features/people/people_screen.dart';
import 'features/people/person_form_screen.dart';
import 'features/people/person_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(bool onboarded) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: onboarded ? '/home' : '/welcome',
      // Links from the Today widget are handled in _onWidgetTap, never as pages.
      redirect: (_, state) => state.uri.scheme == 'smriti' ? (onboarded ? '/home' : '/welcome') : null,
      routes: [
        GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _Shell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
            StatefulShellBranch(
                routes: [GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/people', builder: (_, _) => const PeopleScreen())]),
            StatefulShellBranch(
                routes: [GoRoute(path: '/messages', builder: (_, _) => const LibraryScreen())]),
            StatefulShellBranch(
                routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())]),
          ],
        ),
        GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
        GoRoute(path: '/me/new', builder: (_, _) => const PersonFormScreen(isMe: true)),
        GoRoute(path: '/archived', builder: (_, _) => const ArchivedScreen()),
        GoRoute(path: '/not-wished', builder: (_, _) => const NotWishedScreen()),
        GoRoute(path: '/import/contacts', builder: (_, _) => const BulkAddScreen()),
        GoRoute(path: '/auto-calls', builder: (_, _) => const AutoCallsScreen()),
        GoRoute(
          path: '/autocall',
          builder: (_, state) => AutoCallPromptScreen(
            data: (state.extra as Map<String, dynamic>?) ?? const {},
            callNow: state.uri.queryParameters['now'] == '1',
          ),
        ),
        GoRoute(path: '/duplicates', builder: (_, _) => const DuplicatesScreen()),
        GoRoute(path: '/widget-glow', builder: (_, _) => const WidgetGlowScreen()),
        GoRoute(path: '/import/calendar', builder: (_, _) => const CalendarImportScreen()),
        GoRoute(path: '/import/birthdays', builder: (_, _) => const ImportBirthdaysScreen()),
        GoRoute(
          path: '/person/new',
          builder: (_, state) => PersonFormScreen(fromContacts: state.uri.queryParameters['contacts'] == '1'),
        ),
        GoRoute(
          path: '/person/:id',
          builder: (_, state) => PersonScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/person/:id/family',
          builder: (_, state) => FamilyTreeScreen(personId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/person/:id/memories',
          builder: (_, state) => MemoriesScreen(personId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/person/:id/edit',
          builder: (_, state) => PersonFormScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/event/new',
          builder: (_, state) {
            final q = state.uri.queryParameters;
            return EventFormScreen(
              initialKind: q['kind'],
              personId: int.tryParse(q['person'] ?? ''),
              initialType: q['type'],
              initialDay: int.tryParse(q['day'] ?? ''),
              initialMonth: int.tryParse(q['month'] ?? ''),
            );
          },
        ),
        GoRoute(
          path: '/event/:id',
          builder: (_, state) => EventDetailScreen(
            id: int.parse(state.pathParameters['id']!),
            action: state.uri.queryParameters['action'],
            date: state.uri.queryParameters['date'],
          ),
        ),
        GoRoute(
          path: '/event/:id/reminders',
          builder: (_, state) => RemindersScreen(eventId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/alarm',
          builder: (_, state) => AlarmScreen(
            eventId: int.tryParse(state.uri.queryParameters['event'] ?? ''),
            date: state.uri.queryParameters['date'],
            payload: state.extra as Map<String, dynamic>?,
          ),
        ),
        GoRoute(path: '/reliability', builder: (_, _) => const ReliabilityScreen()),
        GoRoute(path: '/thank-you', builder: (_, _) => const ThankYouScreen()),
        GoRoute(path: '/festivals', builder: (_, _) => const FestivalsScreen()),
        GoRoute(path: '/card', builder: (_, state) => CardStudioScreen(request: state.extra! as CardRequest)),
        GoRoute(path: '/calendar-sync', builder: (_, _) => const CalendarSyncScreen()),
        GoRoute(path: '/gifts', builder: (_, _) => const GiftPlannerScreen()),
        GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen()),
        GoRoute(path: '/group/:id', builder: (_, state) => GroupScreen(id: int.parse(state.pathParameters['id']!))),
        GoRoute(path: '/export', builder: (_, _) => const ExportScreen()),
        GoRoute(path: '/import', builder: (_, _) => const ImportScreen()),
        GoRoute(path: '/backup', builder: (_, _) => const BackupScreen()),
        GoRoute(
          path: '/festival',
          builder: (_, state) => FestivalScreen(festivalKey: state.uri.queryParameters['key'] ?? ''),
        ),
        GoRoute(
          path: '/wish-mode/new',
          builder: (_, state) => WishModeSetupScreen(festivalKey: state.uri.queryParameters['festival']),
        ),
        GoRoute(
          path: '/wish-mode/:id',
          builder: (_, state) => WishModeRunner(sessionId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/event/:id/message',
          builder: (_, state) => EventMessageScreen(eventId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/event/:id/edit',
          builder: (_, state) => EventFormScreen(id: int.parse(state.pathParameters['id']!)),
        ),
      ],
    );

class SmritiApp extends ConsumerStatefulWidget {
  const SmritiApp({super.key});

  @override
  ConsumerState<SmritiApp> createState() => _SmritiAppState();
}

class _SmritiAppState extends ConsumerState<SmritiApp> with WidgetsBindingObserver {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    NotificationService.taps.addListener(_onTap);
    if (NotificationService.supported) {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_onWidgetTap);
      _widgetTaps = HomeWidget.widgetClicked.listen(_onWidgetTap);
    }
  }

  StreamSubscription<Uri?>? _widgetTaps;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  /// "✓ Done" or a name tapped on the Today widget.
  Future<void> _onWidgetTap(Uri? uri) async {
    final to = await HomeWidgetService.handleTap(uri, ref.read(repoProvider));
    if (to == null || !mounted) return;
    if (to == 'done') {
      _messenger.currentState?.showSnackBar(const SnackBar(content: Text('Marked as wished ✓')));
      _publishWidget();
      return;
    }
    // The router may not exist yet if the app was just started by this tap.
    for (var i = 0; i < 20 && _router == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _router?.push(to);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.taps.removeListener(_onTap);
    _widgetTaps?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  /// Keeps contacts and scheduled alarms in step with the data.
  void _sync() {
    ContactSync(ref.read(repoProvider)).run();
    if (NotificationService.supported) Duplicates.cleanSafely(ref.read(databaseProvider));
    AlarmScheduler.syncSoon(ref.read(databaseProvider));
    if (NotificationService.supported) BackupService(ref.read(databaseProvider)).autoIfDue();
    _publishWidget();
    CalendarSync.syncSoon(ref.read(databaseProvider));
  }

  /// Refreshes the home-screen widget once the data has loaded.
  void _publishWidget() {
    if (!ref.read(entriesProvider).hasValue) return;
    HomeWidgetService.publish(ref.read(visibleEntriesProvider), ref.read(todayProvider).value ?? Day.today(),
        done: ref.read(wishedKeysProvider), glow: ref.read(widgetGlowProvider).value?.toJson(),
        look: ref.read(widgetLookProvider).value?.toJson());
  }

  /// Opens the right screen for a tapped notification or its button.
  void _onTap() {
    final t = NotificationService.taps.value;
    final router = _router;
    if (t == null || router == null) return;
    NotificationService.taps.value = null;
    final id = t.eventId;
    final date = t.date == null ? '' : '&date=${t.date}';
    if (t.kind == 'call') {
      // Auto call: "Yes" on the notification calls at once; otherwise show the prompt.
      router.push(t.action == 'callyes' ? '/autocall?now=1' : '/autocall', extra: t.data);
    } else if (t.action == 'call' && id != null) {
      router.push('/event/$id?action=call$date');
    } else if (t.action == 'wish' && id != null) {
      router.push('/event/$id?action=${t.kind == 'bel' ? 'belated' : 'wish'}$date');
    } else if (t.kind == 'mid') {
      router.push('/alarm?${id == null ? '' : 'event=$id'}$date', extra: t.data);
    } else if (t.kind == 'bel' && id != null) {
      router.push('/event/$id?action=belated$date');
    } else if (t.kind == 'month') {
      router.go('/calendar');
    } else if (t.kind == 'fest') {
      final key = t.festivalKey;
      router.push(key == null ? '/festivals' : '/festival?key=${Uri.encodeQueryComponent(key)}');
    } else if (id != null) {
      router.push('/event/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final onboarded = ref.watch(onboardedProvider);
    if (!onboarded.hasValue) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        home: const Scaffold(body: SizedBox.shrink()),
      );
    }
    if (_router == null) {
      _router = buildRouter(onboarded.requireValue);
      WidgetsBinding.instance.addPostFrameCallback((_) => _onTap());
    }
    // Any change to events, reminders or wishes reschedules the alarms.
    ref.listen(entriesProvider, (_, _) => AlarmScheduler.syncSoon(ref.read(databaseProvider)));
    ref.listen(allRemindersProvider, (_, _) => AlarmScheduler.syncSoon(ref.read(databaseProvider)));
    ref.listen(wishedKeysProvider, (_, _) => AlarmScheduler.syncSoon(ref.read(databaseProvider)));
    ref.listen(festivalsProvider, (_, _) => AlarmScheduler.syncSoon(ref.read(databaseProvider)));
    ref.listen(autoCallsProvider, (_, _) => AlarmScheduler.syncSoon(ref.read(databaseProvider)));
    ref.listen(visibleEntriesProvider, (_, _) => _publishWidget());
    ref.listen(wishedKeysProvider, (_, _) => _publishWidget());
    ref.listen(widgetGlowProvider, (_, _) => _publishWidget());
    ref.listen(widgetLookProvider, (_, _) => _publishWidget());
    ref.listen(entriesProvider, (_, _) => CalendarSync.syncSoon(ref.read(databaseProvider)));
    return MaterialApp.router(
      title: 'Smriti',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: _router,
      scaffoldMessengerKey: _messenger,
      builder: (context, child) => MediaQuery(
        // Settings › Text size scales every screen, on top of the phone's font size.
        data: MediaQuery.of(context).copyWith(
            textScaler: _scaled(MediaQuery.textScalerOf(context), ref.watch(appTextSizeProvider).value?.scale ?? 1)),
        child: LockGate(
          routeChanges: _router!.routerDelegate,
          isAlarm: () {
            final path = _router!.routerDelegate.currentConfiguration.uri.path;
            return path.startsWith('/alarm') || path.startsWith('/autocall');
          },
          child: Stack(children: [
            ?child,
            const Align(alignment: Alignment.bottomCenter, child: WishedChip()),
          ]),
        ),
      ),
    );
  }
}

TextScaler _scaled(TextScaler phone, double factor) =>
    factor == 1 ? phone : TextScaler.linear((phone.scale(14) / 14) * factor);

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.c.line))),
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Calendar'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people_rounded), label: 'People'),
              NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Messages'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
          ),
        ),
      );
}

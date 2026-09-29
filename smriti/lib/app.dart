import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'data/providers.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/contacts/bulk_add_screen.dart';
import 'features/contacts/contact_sync.dart';
import 'features/contacts/import_birthdays_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/events/event_form_screen.dart';
import 'features/home/home_screen.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.taps.removeListener(_onTap);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  /// Keeps contacts and scheduled alarms in step with the data.
  void _sync() {
    ContactSync(ref.read(repoProvider)).run();
    AlarmScheduler.syncSoon(ref.read(databaseProvider));
  }

  /// Opens the right screen for a tapped notification or its button.
  void _onTap() {
    final t = NotificationService.taps.value;
    final router = _router;
    if (t == null || router == null) return;
    NotificationService.taps.value = null;
    final id = t.eventId;
    final date = t.date == null ? '' : '&date=${t.date}';
    if (t.action == 'call' && id != null) {
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
      router.push('/festivals');
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
    return MaterialApp.router(
      title: 'Smriti',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: _router,
      builder: (context, child) => Stack(children: [
        ?child,
        const Align(alignment: Alignment.bottomCenter, child: WishedChip()),
      ]),
    );
  }
}

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

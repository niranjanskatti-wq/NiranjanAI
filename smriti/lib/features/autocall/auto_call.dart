import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../reminders/alarm_planner.dart';
import '../reminders/alarm_scheduler.dart';
import '../reminders/notification_service.dart';
import '../reminders/reminder_model.dart';
import '../reminders/reminders_screen.dart' show pickMinute;

// ---------------------------------------------------------------------------
// Settings and data

final autoCallOnProvider =
    StreamProvider<bool>((ref) => ref.watch(databaseProvider).watchSetting('autoCall').map((v) => v == 'true'));

final autoCallsProvider = StreamProvider<List<AutoCall>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.autoCalls)..orderBy([(a) => OrderingTerm(expression: a.id)])).watch();
});

/// Places a call now, on speaker if asked. Falls back to the dialer when the
/// phone permission is missing.
Future<bool> placeCall(String number, {required bool speaker}) async {
  if (!NotificationService.supported) return false;
  if (!await Permission.phone.request().isGranted) return false;
  try {
    return await const MethodChannel('smriti/window')
            .invokeMethod<bool>('placeCall', {'number': number, 'speaker': speaker}) ??
        false;
  } catch (_) {
    return false;
  }
}

/// The prompts to schedule for every switched-on auto call.
Future<List<PlannedAlarm>> autoCallAlarms(AppDatabase db, tz.TZDateTime now) async {
  if (await db.getSetting('autoCall') != 'true') return const [];
  final countdown = await db.getSetting('autoCallCountdown') == 'true';
  final repo = Repository(db);
  final people = {for (final p in await repo.allPeople()) p.id: p};
  final entries = {for (final e in await repo.watchEntries().first) e.event.id: e};
  final today = Day(now.year, now.month, now.day);
  final out = <PlannedAlarm>[];
  for (final a in await db.select(db.autoCalls).get()) {
    if (!a.enabled) continue;
    final p = people[a.personId];
    final number = (a.number?.isNotEmpty ?? false) ? a.number : (p?.callNumber ?? p?.whatsappNumber);
    if (p == null || number == null) continue;
    final entry = a.eventId == null ? null : entries[a.eventId];
    final days = <Day>[];
    if (entry != null) {
      // This year's and next year's, so a missed app open never loses one.
      var d = entry.nextFrom(today);
      for (var i = 0; i < 2 && d != null; i++) {
        days.add(d);
        d = entry.nextFrom(d.addDays(1));
      }
    } else if (a.date != null) {
      final parts = a.date!.split('-').map(int.parse).toList();
      days.add(Day(parts[0], parts[1], parts[2]));
    }
    for (final d in days) {
      final when = tz.TZDateTime(now.location, d.year, d.month, d.day, a.minuteOfDay ~/ 60, a.minuteOfDay % 60);
      if (!when.isAfter(now)) continue;
      final what = entry == null ? 'Scheduled call' : '${entry.typeLabel} · ${entry.title}';
      out.add(PlannedAlarm(
        id: stableId('call|${a.id}|$d'),
        when: when,
        kind: 'call',
        title: '📞 Call ${p.shortName} now?',
        body: '$what · ${formatPhone(number)}${a.speaker ? ' · on speaker' : ''}',
        sound: AlarmSound.chime,
        eventId: entry?.event.id,
        date: d,
        fullScreen: true,
        extra: {'p': p.id, 'n': number, 'sp': a.speaker, 'cd': countdown, 'nm': p.shortName},
      ));
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Settings section

class AutoCallSettings extends ConsumerWidget {
  const AutoCallSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final on = ref.watch(autoCallOnProvider).value ?? false;
    final countdown = ref.watch(_countdownProvider).value ?? false;
    final calls = ref.watch(autoCallsProvider).value ?? const <AutoCall>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Auto call')),
      SwitchListTile(
        secondary: const Icon(Icons.phone_forwarded_rounded),
        title: const Text('Auto call'),
        subtitle: const Text('At the time you set, the phone rings and asks "Call now?" Yes calls them, on speaker if chosen'),
        value: on,
        onChanged: (v) async {
          if (v) {
            final phone = await Permission.phone.request().isGranted;
            if (!phone) {
              if (context.mounted) showToast(context, 'Smriti needs the Phone permission to place calls');
              return;
            }
            await NotificationService.requestNotifications();
            await NotificationService.requestFullScreen();
          }
          await db.setSetting('autoCall', '$v');
          AlarmScheduler.syncSoon(db);
        },
      ),
      if (on) ...[
        SwitchListTile(
          secondary: const Icon(Icons.timer_outlined),
          title: const Text('Call by itself after 10 seconds'),
          subtitle: const Text('If you don’t answer the prompt, Smriti calls anyway (while the prompt is open)'),
          value: countdown,
          onChanged: (v) async {
            await db.setSetting('autoCallCountdown', '$v');
            AlarmScheduler.syncSoon(db);
          },
        ),
        ListTile(
          leading: const Icon(Icons.schedule_rounded),
          title: const Text('Scheduled calls'),
          subtitle: Text(calls.isEmpty ? 'None yet. Add one here or from any event' : '${calls.length} set'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/auto-calls'),
        ),
      ],
    ]);
  }
}

final _countdownProvider = StreamProvider<bool>(
    (ref) => ref.watch(databaseProvider).watchSetting('autoCallCountdown').map((v) => v == 'true'));

// ---------------------------------------------------------------------------
// Scheduling a call

/// Sheet to set an auto call for [person], either for [event] every year or once on a date.
Future<void> scheduleAutoCall(BuildContext context, WidgetRef ref,
    {Person? person, EventEntry? event, AutoCall? existing}) async {
  final db = ref.read(databaseProvider);
  final people = [...?ref.read(peopleProvider).value];
  if (!(ref.read(autoCallOnProvider).value ?? false)) {
    showToast(context, 'Switch on Auto call in Settings first');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _ScheduleSheet(db: db, people: people, person: person, event: event, existing: existing),
  );
  AlarmScheduler.syncSoon(db);
}

class _ScheduleSheet extends ConsumerStatefulWidget {
  const _ScheduleSheet({required this.db, required this.people, this.person, this.event, this.existing});

  final AppDatabase db;
  final List<Person> people;
  final Person? person;
  final EventEntry? event;
  final AutoCall? existing;

  @override
  ConsumerState<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<_ScheduleSheet> {
  Person? _person;
  EventEntry? _event;
  Day? _date;
  int _minute = 0;
  bool _speaker = true;
  List<EventEntry> _events = const [];

  @override
  void initState() {
    super.initState();
    final x = widget.existing;
    _event = widget.event;
    _person = widget.person ?? (widget.event?.people.firstOrNull);
    if (x != null) {
      _person = widget.people.where((p) => p.id == x.personId).firstOrNull ?? _person;
      _minute = x.minuteOfDay;
      _speaker = x.speaker;
      if (x.date != null) {
        final p = x.date!.split('-').map(int.parse).toList();
        _date = Day(p[0], p[1], p[2]);
      }
    }
    _loadEvents(eventId: x?.eventId);
  }

  Future<void> _loadEvents({int? eventId}) async {
    final p = _person;
    if (p == null) return;
    final list = await Repository(widget.db).watchEntriesForPerson(p.id).first;
    if (!mounted) return;
    setState(() {
      _events = list;
      if (eventId != null) _event = list.where((e) => e.event.id == eventId).firstOrNull;
      if (_event == null && _date == null) _event = list.firstOrNull;
      if (_event == null && _date == null) _date = Day.today();
    });
  }

  Future<void> _save() async {
    final p = _person;
    if (p == null) return showToast(context, 'Choose who to call');
    if ((p.callNumber ?? p.whatsappNumber) == null) return showToast(context, '${p.shortName} has no phone number saved');
    if (_event == null && _date == null) return showToast(context, 'Choose when');
    final data = AutoCallsCompanion(
      personId: Value(p.id),
      eventId: Value(_event?.event.id),
      date: Value(_event == null ? _date.toString() : null),
      minuteOfDay: Value(_minute),
      speaker: Value(_speaker),
      enabled: const Value(true),
    );
    final x = widget.existing;
    if (x == null) {
      await widget.db.into(widget.db.autoCalls).insert(data);
    } else {
      await (widget.db.update(widget.db.autoCalls)..where((a) => a.id.equals(x.id))).write(data);
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;
    Navigator.pop(context);
    showToast(context, 'Auto call set for ${fmtMinute(_minute)}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = _person;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Auto call', style: context.text.titleLarge),
          Text('At this time the phone rings and asks “Call now?”. Tap Yes to call.', style: context.text.bodySmall),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: p == null ? const CircleAvatar(child: Icon(Icons.person_outline)) : PersonAvatar(person: p, size: 40),
            title: Text(p?.name ?? 'Choose who to call'),
            subtitle: p == null
                ? null
                : Text((p.callNumber ?? p.whatsappNumber) == null ? 'No number saved' : formatPhone(p.callNumber ?? p.whatsappNumber)),
            trailing: widget.person == null && widget.event == null ? const Icon(Icons.arrow_drop_down) : null,
            onTap: widget.person != null || widget.event != null
                ? null
                : () async {
                    final chosen = await showModalBottomSheet<Person>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      builder: (ctx) => _PersonPicker(people: widget.people.where((x) => !x.isMe).toList()),
                    );
                    if (chosen != null) {
                      setState(() {
                        _person = chosen;
                        _event = null;
                        _date = null;
                      });
                      _loadEvents();
                    }
                  },
          ),
          const SectionLabel('When'),
          for (final e in _events)
            RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              value: e.event.id,
              // ignore: deprecated_member_use
              groupValue: _event?.event.id,
              // ignore: deprecated_member_use
              onChanged: (_) => setState(() {
                _event = e;
                _date = null;
              }),
              title: Text('On their ${e.typeLabel.toLowerCase()}, every year'),
              subtitle: Text(fmtEventDate(day: e.event.day, month: e.event.month)),
            ),
          RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            value: -1,
            // ignore: deprecated_member_use
            groupValue: _event == null ? -1 : null,
            // ignore: deprecated_member_use
            onChanged: (_) => setState(() {
              _event = null;
              _date ??= Day.today();
            }),
            title: const Text('Once, on a date'),
            subtitle: _event == null && _date != null ? Text(fmtFull(_date!)) : null,
            secondary: _event == null
                ? TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 3),
                        initialDate: _date?.asDateTime ?? now,
                      );
                      if (d != null) setState(() => _date = Day(d.year, d.month, d.day));
                    },
                    child: const Text('Change'),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_rounded),
            title: const Text('Time'),
            trailing: Text(fmtMinute(_minute), style: context.text.titleMedium?.copyWith(color: c.goldText)),
            onTap: () async {
              final m = await pickMinute(context, _minute);
              if (m != null) setState(() => _minute = m);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(_speaker ? Icons.volume_up_rounded : Icons.phone_in_talk_rounded),
            title: const Text('Speaker on'),
            subtitle: const Text('Most phones start the call on speaker'),
            value: _speaker,
            onChanged: (v) => setState(() => _speaker = v),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _save, child: const Text('Save auto call')),
        ]),
      ),
    );
  }
}

class _PersonPicker extends StatefulWidget {
  const _PersonPicker({required this.people});
  final List<Person> people;

  @override
  State<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<_PersonPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.people
        .where((p) => p.name.toLowerCase().contains(_q) || (p.nickname ?? '').toLowerCase().contains(_q))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Who to call'),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => ListTile(
              leading: PersonAvatar(person: list[i], size: 36),
              title: Text(list[i].name),
              subtitle: Text((list[i].callNumber ?? list[i].whatsappNumber) == null
                  ? 'No number'
                  : formatPhone(list[i].callNumber ?? list[i].whatsappNumber)),
              onTap: () => Navigator.pop(context, list[i]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// List of scheduled calls

class AutoCallsScreen extends ConsumerWidget {
  const AutoCallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final calls = ref.watch(autoCallsProvider).value ?? const <AutoCall>[];
    final people = {for (final p in [...?ref.watch(peopleProvider).value]) p.id: p};
    final entries = {for (final e in [...?ref.watch(entriesProvider).value]) e.event.id: e};
    final db = ref.read(databaseProvider);
    final on = ref.watch(autoCallOnProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled calls')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => scheduleAutoCall(context, ref),
        icon: const Icon(Icons.add_call),
        label: const Text('Schedule a call'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          if (!on)
            InfoCard(title: 'Auto call is off', children: [
              Text('Switch it on in Settings › Auto call. Nothing here will ring until then.',
                  style: context.text.bodyMedium),
            ]),
          if (calls.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('No calls scheduled.\nTap “Schedule a call”, or open any birthday and choose Auto call.',
                  textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: c.muted)),
            ),
          for (final a in calls)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: PersonAvatar(person: people[a.personId], size: 40),
                title: Text(people[a.personId]?.name ?? 'Unknown'),
                subtitle: Text([
                  if (a.eventId != null)
                    '${entries[a.eventId]?.typeLabel ?? 'Event'} every year'
                  else if (a.date != null)
                    'Once on ${a.date}',
                  fmtMinute(a.minuteOfDay),
                  if (a.speaker) 'speaker',
                ].join(' · ')),
                onTap: () => scheduleAutoCall(context, ref, existing: a, person: people[a.personId]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Switch(
                    value: a.enabled,
                    onChanged: (v) async {
                      await (db.update(db.autoCalls)..where((x) => x.id.equals(a.id)))
                          .write(AutoCallsCompanion(enabled: Value(v)));
                      AlarmScheduler.syncSoon(db);
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline, color: c.muted),
                    onPressed: () async {
                      await (db.delete(db.autoCalls)..where((x) => x.id.equals(a.id))).go();
                      AlarmScheduler.syncSoon(db);
                    },
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The full-screen prompt

/// Shown when an auto call is due: "Call Appa now?" with Yes / No.
class AutoCallPromptScreen extends StatefulWidget {
  const AutoCallPromptScreen({super.key, required this.data, this.callNow = false});

  final Map<String, dynamic> data;

  /// Tapped "Yes, call now" on the notification: call straight away.
  final bool callNow;

  @override
  State<AutoCallPromptScreen> createState() => _AutoCallPromptScreenState();
}

class _AutoCallPromptScreenState extends State<AutoCallPromptScreen> {
  late bool _speaker = widget.data['sp'] as bool? ?? true;
  Timer? _timer;
  int _left = 10;
  bool _done = false;

  String get _number => widget.data['n'] as String? ?? '';
  String get _name => widget.data['nm'] as String? ?? 'them';

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    if (widget.callNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _call());
    } else if (widget.data['cd'] == true) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_left <= 1) {
          t.cancel();
          _call();
        } else {
          setState(() => _left--);
          HapticFeedback.selectionClick();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    NotificationService.setLockScreen(false);
    super.dispose();
  }

  Future<void> _call() async {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    final ok = await placeCall(_number, speaker: _speaker);
    if (!mounted) return;
    if (!ok) showToast(context, 'Could not call. Allow the Phone permission for Smriti.');
    _close();
  }

  void _close() {
    _timer?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Icon(Icons.phone_in_talk_rounded, size: 64, color: c.call),
            const SizedBox(height: 16),
            Text('Call $_name now?', textAlign: TextAlign.center, style: context.text.displaySmall),
            const SizedBox(height: 8),
            Text(widget.data['b'] as String? ?? formatPhone(_number),
                textAlign: TextAlign.center, style: context.text.bodyMedium),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Speaker on'),
              secondary: Icon(_speaker ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              value: _speaker,
              onChanged: (v) => setState(() => _speaker = v),
            ),
            if (_timer != null && _timer!.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Calling by itself in $_left…', style: context.text.titleMedium?.copyWith(color: c.goldText)),
              ),
            const Spacer(),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                  onPressed: _close,
                  child: const Text('No', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                    backgroundColor: c.call,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _call,
                  icon: const Icon(Icons.call_rounded, size: 26),
                  label: const Text('Yes, call', style: TextStyle(fontSize: 20)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

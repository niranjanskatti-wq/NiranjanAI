import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/tokens.dart';
import '../../core/util/format.dart';
import '../../core/util/occurrence.dart';
import '../../core/util/phone.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../messages/message_engine.dart';
import '../messages/message_store.dart';
import '../reminders/alarm_planner.dart' show stableId;
import '../reminders/notification_service.dart';
import '../reminders/reminder_model.dart' show fmtMinute;
import '../reminders/reminders_screen.dart' show pickMinute;

// ---------------------------------------------------------------------------
// Settings and data

final autoSmsOnProvider =
    StreamProvider<bool>((ref) => ref.watch(databaseProvider).watchSetting('autoSms').map((v) => v == 'true'));

final smsSchedulesProvider = StreamProvider<List<SmsSchedule>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.scheduledSms)
        ..orderBy([(a) => OrderingTerm(expression: a.personId), (a) => OrderingTerm(expression: a.minuteOfDay)]))
      .watch();
});

/// One text message ready to go at [at].
class SmsJob {
  const SmsJob({
    required this.id,
    required this.at,
    required this.number,
    required this.text,
    required this.name,
    required this.personId,
    this.eventId,
    required this.date,
  });

  final int id;
  final DateTime at;
  final String number, text, name;
  final int personId;
  final int? eventId;
  final Day date;

  Map<String, Object?> toJson() => {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'number': number,
        'text': text,
        'name': name,
        'p': personId,
        'e': eventId,
        'd': '$date',
      };
}

/// Every message to send from [now] on: this year's and next year's for
/// yearly ones, so nothing is lost if Smriti isn't opened for a while.
/// Smriti-written messages differ for each time on the same day.
Future<List<SmsJob>> smsJobs(AppDatabase db, DateTime now, {MessageLibrary? lib}) async {
  if (await db.getSetting('autoSms') != 'true') return const [];
  final repo = Repository(db);
  final people = {for (final p in await repo.allPeople()) p.id: p};
  final entries = {for (final e in await repo.watchEntries().first) e.event.id: e};
  final me = await repo.getMe();
  final lang = Lang.parse(await db.getSetting('messageLang'));
  final ageWhere = AgeInWishes.parse(await db.getSetting('ageInWishes'));
  final own = await AgeLines.load(db);
  final prefs = lib == null ? null : await MessagePrefs.load(db);
  final today = Day(now.year, now.month, now.day);
  final rows = await db.select(db.scheduledSms).get();
  // Which slot of the day each row is, so two times that day get two different wishes.
  final slot = <int, int>{};
  final byKey = <String, List<SmsSchedule>>{};
  for (final r in rows) {
    (byKey['${r.personId}|${r.eventId}|${r.date}'] ??= []).add(r);
  }
  for (final list in byKey.values) {
    list.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    for (var i = 0; i < list.length; i++) {
      slot[list[i].id] = i;
    }
  }
  final out = <SmsJob>[];
  for (final r in rows) {
    if (!r.enabled) continue;
    final p = people[r.personId];
    final number = (r.number?.isNotEmpty ?? false) ? r.number : (p?.callNumber ?? p?.whatsappNumber);
    if (p == null || number == null) continue;
    final entry = r.eventId == null ? null : entries[r.eventId];
    final days = <Day>[];
    if (entry != null) {
      var d = entry.nextFrom(today);
      for (var i = 0; i < 2 && d != null; i++) {
        days.add(d);
        d = entry.nextFrom(d.addDays(1));
      }
    } else if (r.date != null) {
      final parts = r.date!.split('-').map(int.parse).toList();
      days.add(Day(parts[0], parts[1], parts[2]));
    }
    for (final d in days) {
      final at = DateTime(d.year, d.month, d.day, r.minuteOfDay ~/ 60, r.minuteOfDay % 60);
      if (!at.isAfter(now)) continue;
      final u = entry == null ? null : Upcoming(entry, d, today.daysUntil(d));
      final ctx = entry != null
          ? MessageContext.forEntry(entry, years: u!.years, me: me)
          : MessageContext(name: p.wishName, nickname: p.wishName, relation: p.relation, myName: me?.wishName);
      final mine = r.message?.trim();
      String text;
      if (mine != null && mine.isNotEmpty) {
        text = ctx.fill(mine);
      } else {
        final draft = entry?.event.draftMessage?.trim();
        final i = slot[r.id] ?? 0;
        if (draft != null && draft.isNotEmpty && i == 0) {
          text = draft;
        } else {
          final occasions = entry == null ? [Occasion.general] : occasionsFor(entry, milestone: u!.milestone);
          final list = lib?.suggest(
                occasions: occasions,
                lang: lang,
                ctx: ctx,
                extra: prefs!.extra,
                hidden: prefs.hidden,
                favourites: prefs.favourites,
              ) ??
              const <MessageTemplate>[];
          text = list.isEmpty ? fallbackMessage(ctx, occasions.first) : ctx.fill(list[i % list.length].text);
        }
        text = ctx.withAge(text, lang, ageWhere, own);
      }
      out.add(SmsJob(
        id: stableId('sms|${r.id}|$d'),
        at: at,
        number: number,
        text: text,
        name: p.wishName,
        personId: p.id,
        eventId: entry?.event.id,
        date: d,
      ));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

/// Keeps Android's list of messages in step with Smriti, and records the ones sent.
class AutoSms {
  static const _channel = MethodChannel('smriti/sms');
  static Timer? _debounce;

  static void syncSoon(AppDatabase db) {
    if (!NotificationService.supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => sync(db));
  }

  static Future<void> sync(AppDatabase db) async {
    if (!NotificationService.supported) return;
    try {
      await recordSent(db);
      final jobs = await smsJobs(db, DateTime.now(), lib: await MessageLibrary.load());
      await _channel.invokeMethod('schedule', jsonEncode([for (final j in jobs) j.toJson()]));
    } catch (e) {
      debugPrint('Auto SMS sync skipped: $e');
    }
  }

  /// Marks people as wished for every message Android sent.
  static Future<int> recordSent(AppDatabase db) async {
    final raw = await _channel.invokeMethod<String>('drainSent') ?? '[]';
    final repo = Repository(db);
    var n = 0;
    for (final j in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) {
      if (j['ok'] != true) continue;
      final date = j['d'] as String;
      final eventId = j['e'] as int?;
      final personId = j['p'] as int?;
      await repo.logWish(
        personId: personId,
        eventId: eventId,
        occasionDate: eventId == null ? null : date,
        method: 'sms',
        message: j['text'] as String?,
        confirmed: true,
      );
      n++;
    }
    return n;
  }

  static Future<bool> canSend() async {
    try {
      return await _channel.invokeMethod<bool>('canSend') ?? false;
    } catch (_) {
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Settings section

class AutoSmsSettings extends ConsumerWidget {
  const AutoSmsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final on = ref.watch(autoSmsOnProvider).value ?? false;
    final list = ref.watch(smsSchedulesProvider).value ?? const <SmsSchedule>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SectionLabel('Auto text message (SMS)')),
      SwitchListTile(
        secondary: const Icon(Icons.sms_outlined),
        title: const Text('Auto text message'),
        subtitle: const Text('Smriti sends the SMS by itself at the times you set, even with the phone locked'),
        value: on,
        onChanged: (v) async {
          if (v) {
            final ok = await Permission.sms.request().isGranted;
            if (!ok) {
              if (context.mounted) showToast(context, 'Smriti needs the SMS permission to send texts');
              return;
            }
            await NotificationService.requestNotifications();
            if (!await NotificationService.exactAllowed()) await NotificationService.requestExact();
          }
          await db.setSetting('autoSms', '$v');
          AutoSms.syncSoon(db);
        },
      ),
      if (on)
        ListTile(
          leading: const Icon(Icons.schedule_send_outlined),
          title: const Text('Scheduled messages'),
          subtitle: Text(list.isEmpty ? 'None yet. Add one here or from any birthday' : '${list.length} set'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/auto-sms'),
        ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Scheduling

/// Sheet to schedule texts for [person]: yearly on one of their dates or once,
/// at one or more times, with Smriti's wish or your own words.
Future<void> scheduleSms(BuildContext context, WidgetRef ref,
    {Person? person, EventEntry? event, SmsSchedule? existing}) async {
  final db = ref.read(databaseProvider);
  if (!(ref.read(autoSmsOnProvider).value ?? false)) {
    showToast(context, 'Switch on Auto text message in Settings first');
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _SmsSheet(
      db: db,
      people: [...?ref.read(peopleProvider).value],
      person: person,
      event: event,
      existing: existing,
    ),
  );
  AutoSms.syncSoon(db);
}

class _SmsSheet extends ConsumerStatefulWidget {
  const _SmsSheet({required this.db, required this.people, this.person, this.event, this.existing});

  final AppDatabase db;
  final List<Person> people;
  final Person? person;
  final EventEntry? event;
  final SmsSchedule? existing;

  @override
  ConsumerState<_SmsSheet> createState() => _SmsSheetState();
}

class _SmsSheetState extends ConsumerState<_SmsSheet> {
  Person? _person;
  EventEntry? _event;
  Day? _date;
  final _times = <int>[0];
  final _text = TextEditingController();
  List<EventEntry> _events = const [];

  @override
  void initState() {
    super.initState();
    final x = widget.existing;
    _event = widget.event;
    _person = widget.person ?? widget.event?.people.where((p) => !p.isMe).firstOrNull;
    if (x != null) {
      _person = widget.people.where((p) => p.id == x.personId).firstOrNull ?? _person;
      _times
        ..clear()
        ..add(x.minuteOfDay);
      _text.text = x.message ?? '';
      if (x.date != null) {
        final p = x.date!.split('-').map(int.parse).toList();
        _date = Day(p[0], p[1], p[2]);
      }
    }
    _loadEvents(eventId: x?.eventId);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
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
    if (p == null) return showToast(context, 'Choose who to text');
    if ((p.callNumber ?? p.whatsappNumber) == null) return showToast(context, '${p.shortName} has no phone number saved');
    if (_event == null && _date == null) return showToast(context, 'Choose when');
    if (_times.isEmpty) return showToast(context, 'Add a time');
    final message = _text.text.trim();
    final x = widget.existing;
    for (final (i, m) in _times.indexed) {
      final data = ScheduledSmsCompanion(
        personId: Value(p.id),
        eventId: Value(_event?.event.id),
        date: Value(_event == null ? _date.toString() : null),
        minuteOfDay: Value(m),
        message: Value(message.isEmpty ? null : message),
        enabled: const Value(true),
      );
      if (x != null && i == 0) {
        await (widget.db.update(widget.db.scheduledSms)..where((a) => a.id.equals(x.id))).write(data);
      } else {
        await widget.db.into(widget.db.scheduledSms).insert(data);
      }
    }
    HapticFeedback.lightImpact();
    if (!mounted) return;
    Navigator.pop(context);
    showToast(context, _times.length == 1 ? 'Text set for ${fmtMinute(_times.first)}' : '${_times.length} texts set');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = _person;
    final sorted = [..._times]..sort();
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Auto text message', style: context.text.titleLarge),
          Text('Smriti sends this SMS by itself at each time you add.', style: context.text.bodySmall),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: p == null ? const CircleAvatar(child: Icon(Icons.person_outline)) : PersonAvatar(person: p, size: 40),
            title: Text(p?.name ?? 'Choose who to text'),
            subtitle: p == null
                ? null
                : Text((p.callNumber ?? p.whatsappNumber) == null
                    ? 'No number saved'
                    : formatPhone(p.callNumber ?? p.whatsappNumber)),
            trailing: widget.person == null && widget.event == null ? const Icon(Icons.arrow_drop_down) : null,
            onTap: widget.person != null || widget.event != null
                ? null
                : () async {
                    final chosen = await showModalBottomSheet<Person>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      builder: (ctx) => SafeArea(
                        child: ListView(shrinkWrap: true, children: [
                          for (final x in widget.people.where((x) => !x.isMe))
                            ListTile(
                              leading: PersonAvatar(person: x, size: 34),
                              title: Text(x.name),
                              onTap: () => Navigator.pop(ctx, x),
                            ),
                        ]),
                      ),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_event?.event.id == e.event.id ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: c.goldText),
              title: Text('On their ${e.typeLabel.toLowerCase()}, every year'),
              subtitle: Text(fmtEventDate(day: e.event.day, month: e.event.month)),
              onTap: () => setState(() {
                _event = e;
                _date = null;
              }),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_event == null ? Icons.radio_button_checked : Icons.radio_button_off, color: c.goldText),
            title: const Text('Once, on a date'),
            subtitle: _event == null && _date != null ? Text(fmtFull(_date!)) : null,
            trailing: _event == null
                ? TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 3),
                        initialDate: _date?.asDateTime ?? now,
                      );
                      if (d != null) setState(() => _date = Day.of(d));
                    },
                    child: const Text('Pick date'),
                  )
                : null,
            onTap: () => setState(() {
              _event = null;
              _date ??= Day.today();
            }),
          ),
          SectionLabel(widget.existing == null ? 'Times (add as many as you like)' : 'Time'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in sorted)
              InputChip(
                label: Text(fmtMinute(m)),
                onPressed: () async {
                  final next = await pickMinute(context, m);
                  if (next != null && !_times.contains(next)) {
                    setState(() => _times[_times.indexOf(m)] = next);
                  }
                },
                onDeleted: _times.length > 1 ? () => setState(() => _times.remove(m)) : null,
              ),
            if (widget.existing == null) ...[
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add time'),
                onPressed: () async {
                  final m = await pickMinute(context, 540);
                  if (m != null && !_times.contains(m)) setState(() => _times.add(m));
                },
              ),
              for (final (m, label) in const [(0, '12 AM'), (360, '6 AM'), (540, '9 AM'), (1080, '6 PM')])
                if (!_times.contains(m))
                  ActionChip(label: Text('+ $label'), onPressed: () => setState(() => _times.add(m))),
            ],
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Message (optional)',
              hintText: 'Leave empty: Smriti writes a warm wish with their name and age, different at each time',
            ),
          ),
          const SizedBox(height: 4),
          Text('You can write {nickname} or {age_th} and Smriti fills them in.', style: context.text.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.schedule_send_rounded),
            label: const Text('Schedule'),
          ),
        ]),
      ),
    );
  }
}

/// All scheduled texts, with on/off, edit and remove.
class AutoSmsScreen extends ConsumerWidget {
  const AutoSmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final db = ref.read(databaseProvider);
    final list = ref.watch(smsSchedulesProvider).value ?? const <SmsSchedule>[];
    final people = {for (final p in ref.watch(peopleProvider).value ?? const <Person>[]) p.id: p};
    final entries = {for (final e in ref.watch(entriesProvider).value ?? const <EventEntry>[]) e.event.id: e};
    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled messages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => scheduleSms(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule a text'),
      ),
      body: list.isEmpty
          ? const Center(
              child: EmptyState(
                title: 'No texts scheduled',
                message: 'Add one here, or open any birthday or anniversary and tap Auto text message.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                for (final a in list)
                  Card(
                    child: ListTile(
                      leading: people[a.personId] == null
                          ? const Icon(Icons.sms_outlined)
                          : PersonAvatar(person: people[a.personId], size: 38),
                      title: Text('${people[a.personId]?.shortName ?? 'Someone'} · ${fmtMinute(a.minuteOfDay)}'),
                      subtitle: Text([
                        if (a.eventId != null && entries[a.eventId] != null)
                          'Every ${entries[a.eventId]!.typeLabel.toLowerCase()} '
                              '(${fmtEventDate(day: entries[a.eventId]!.event.day, month: entries[a.eventId]!.event.month)})'
                        else if (a.date != null)
                          'Once · ${a.date}',
                        (a.message?.trim().isNotEmpty ?? false) ? '“${a.message!.trim()}”' : 'Smriti writes the wish',
                      ].join('\n')),
                      isThreeLine: true,
                      onTap: () => scheduleSms(context, ref, existing: a, person: people[a.personId]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(
                          value: a.enabled,
                          onChanged: (v) async {
                            await (db.update(db.scheduledSms)..where((x) => x.id.equals(a.id)))
                                .write(ScheduledSmsCompanion(enabled: Value(v)));
                            AutoSms.syncSoon(db);
                          },
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: Icon(Icons.delete_outline_rounded, color: c.muted),
                          onPressed: () async {
                            await (db.delete(db.scheduledSms)..where((x) => x.id.equals(a.id))).go();
                            AutoSms.syncSoon(db);
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

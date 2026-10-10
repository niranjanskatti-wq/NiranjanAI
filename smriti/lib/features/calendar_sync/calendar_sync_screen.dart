import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'calendar_sync.dart';

/// Choose whether (and where) Smriti copies its dates into the phone calendar.
class CalendarSyncScreen extends ConsumerStatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  ConsumerState<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends ConsumerState<CalendarSyncScreen> {
  bool _on = false, _busy = false, _allowed = false;
  int? _calendarId;
  List<PhoneCalendar> _calendars = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    _on = await db.getSetting('calendarSync') == 'true';
    _calendarId = int.tryParse(await db.getSetting('calendarId') ?? '');
    _allowed = await CalendarSync.hasPermission();
    if (_allowed) _calendars = await CalendarSync.calendars();
    if (mounted) setState(() {});
  }

  Future<void> _toggle(bool v) async {
    final db = ref.read(databaseProvider);
    if (v) {
      if (!await CalendarSync.askPermission()) {
        if (mounted) showToast(context, 'Smriti needs calendar permission for this');
        return;
      }
      _allowed = true;
      _calendars = await CalendarSync.calendars();
      if (_calendars.isEmpty) {
        if (mounted) showToast(context, 'No calendar on this phone can be written to');
        return;
      }
      _calendarId ??= (_calendars.where((c) => c.primary).firstOrNull ?? _calendars.first).id;
      await db.setSetting('calendarId', '$_calendarId');
      await db.setSetting('calendarSync', 'true');
      setState(() => _on = true);
      await _syncNow();
    } else {
      final remove = await confirm(context,
          title: 'Stop copying dates?',
          message: 'Also remove the dates Smriti added to your calendar?',
          action: 'Remove them');
      await db.setSetting('calendarSync', 'false');
      if (remove) await CalendarSync.removeAll(db);
      setState(() => _on = false);
    }
  }

  Future<void> _choose(int id) async {
    if (id == _calendarId) return;
    final db = ref.read(databaseProvider);
    setState(() => _busy = true);
    await CalendarSync.removeAll(db);
    await db.setSetting('calendarId', '$id');
    _calendarId = id;
    await _syncNow();
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    final n = await CalendarSync.syncNow(ref.read(databaseProvider));
    if (!mounted) return;
    setState(() => _busy = false);
    showToast(context, n == 0 ? 'Calendar is up to date' : 'Updated $n dates in your calendar');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: const Text('Phone calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          Text(
            'Copies birthdays, anniversaries and important dates into a calendar on this phone, such as '
            'Google Calendar, so you see them there too. Changes in Smriti are copied over automatically. '
            'Smriti never reads your other calendar events.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Copy dates to my calendar'),
              value: _on,
              onChanged: _busy ? null : _toggle,
            ),
          ),
          if (_on && _allowed) ...[
            const SectionLabel('Calendar'),
            RadioGroup<int>(
              groupValue: _calendarId,
              onChanged: (v) => _busy || v == null ? null : _choose(v),
              child: Column(children: [
                for (final cal in _calendars)
                  RadioListTile<int>(
                    value: cal.id,
                    contentPadding: EdgeInsets.zero,
                    title: Text(cal.name),
                    subtitle: cal.account.isEmpty || cal.account == cal.name
                        ? null
                        : Text(cal.account, style: TextStyle(color: c.muted)),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _syncNow,
              icon: const Icon(Icons.sync_rounded),
              label: Text(_busy ? 'Working…' : 'Sync now'),
            ),
          ],
          const SizedBox(height: 16),
          Text('Festivals are not copied; your calendar app usually shows them already.', style: context.text.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../../services/holiday_calendar.dart';
import '../../services/notifications.dart';
import '../widgets/alarm_options.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import 'item_picker_screen.dart';

/// Create / edit an alarm-style reminder: keep jewellery in the locker,
/// take it out, plan a visit, or anything else.
class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key, this.existing, this.kind = 'keep', this.locationId, this.itemIds = const [], this.date, this.repeat = 'none'});
  final String repeat;
  final Reminder? existing;
  final String kind;
  final int? locationId;
  final List<int> itemIds;
  final DateTime? date;
  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  late String _kind;
  int? _locker;
  late String _date;
  String? _time;
  String _repeat = 'none';
  AlarmOptions _opts = AlarmOptions();
  bool _enabled = true;
  List<Item> _items = [];
  HolidayCalendar? _cal;

  bool get _edit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _kind = r?.kind ?? widget.kind;
    _locker = r?.locationId ?? widget.locationId;
    _date = r?.dueDate ?? Fmt.isoDate(widget.date ?? DateTime.now().add(const Duration(days: 1)));
    _time = r?.time;
    _repeat = r?.repeat ?? widget.repeat;
    if (r != null) _opts = AlarmOptions.fromReminder(r);
    _enabled = r?.enabled ?? true;
    _title.text = r?.title ?? '';
    _notes.text = r?.notes ?? '';
    _init(r?.itemIds ?? widget.itemIds);
  }

  Future<void> _init(List<int> ids) async {
    final repo = AppServices.I.repo;
    final prefs = await repo.prefs();
    _cal = await HolidayCalendar.load(repo);
    if (!_edit) {
      _opts = AlarmOptions.fromPrefs(prefs);
      _time ??= prefs.alertTime;
    }
    for (final id in ids) {
      final i = await repo.item(id);
      if (i != null) _items.add(i);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickItems() async {
    final locker = _locker;
    final ids = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemPickerScreen(
          title: context.t('rem.items'),
          initial: _items.map((e) => e.id!).toList(),
          filter: switch (_kind) {
            'keep' => (i) => i.status != Opt.inLocker,
            'take' => (i) => i.status == Opt.inLocker && (locker == null || i.locationId == locker),
            _ => null,
          },
        ),
      ),
    );
    if (ids == null) return;
    final repo = AppServices.I.repo;
    final items = <Item>[];
    for (final id in ids) {
      final i = await repo.item(id);
      if (i != null) items.add(i);
    }
    setState(() => _items = items);
  }

  Future<String> _defaultTitle() async {
    final tr = context.s;
    final l = _locker == null ? null : await AppServices.I.repo.location(_locker!);
    final where = l?.name ?? tr.t('rem.theLocker');
    return switch (_kind) {
      'keep' => tr.t('rem.keepTitle', {'where': where}),
      'take' => tr.t('rem.takeTitle', {'where': where}),
      'planned_visit' => where,
      _ => tr.t('rem.custom'),
    };
  }

  Future<void> _save() async {
    if (_kind == 'planned_visit' && _locker == null) {
      toast(context, context.t('visit.pickLockerFirst'));
      return;
    }
    final title = _title.text.trim().isEmpty ? await _defaultTitle() : _title.text.trim();
    final itemsText = _items.isEmpty ? null : _items.map((i) => '${i.name} (${i.serial})').join(', ');
    final r = Reminder(
      id: widget.existing?.id,
      kind: _kind,
      title: title,
      dueDate: _date,
      time: _time,
      repeat: _repeat,
      locationId: _locker,
      itemIds: _items.map((e) => e.id!).toList(),
      alarm: _opts.sound == 'alarm',
      alerts: _opts.sortedAlerts,
      sound: _opts.sound,
      vibrate: _opts.vibrate,
      snooze: _opts.snooze,
      enabled: _enabled,
      done: false,
      notes: _notes.text.trim().isEmpty ? itemsText : _notes.text.trim(),
    );
    await AppServices.I.repo.saveReminder(r);
    await Notifier.requestPermission();
    await Notifier.requestExactAlarms();
    if (mounted) {
      toast(context, context.t('rem.saved', {'when': Fmt.dateTime(r.at(_time ?? '09:00'))}));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = DateTime.parse(_date);
    final closed = _cal?.isClosed(day) ?? false;
    final closedWhy = _cal == null
        ? ''
        : [..._cal!.namedOn(day), if (_cal!.weekendOn(day) != null) context.t('hol.${_cal!.weekendOn(day)}')].join(', ');
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? context.t('rem.edit') : context.t('rem.add'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
        Text(context.t('rem.type'), style: const TextStyle(color: GV.muted, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in Reminder.kinds)
            ChoiceChip(
              avatar: Icon(switch (k) { 'keep' => Icons.login, 'take' => Icons.logout, 'planned_visit' => Icons.event_available, _ => Icons.alarm }, size: 20),
              label: Text(context.t('rem.kind.$k'), style: const TextStyle(fontSize: 16)),
              selected: _kind == k,
              onSelected: (_) => setState(() {
                _kind = k;
                if (k != 'keep' && k != 'take') _items = [];
              }),
            ),
        ]),
        gap,
        TextIn(_title, context.t('rem.what'), hint: context.t('rem.titleAuto')),
        gap,
        LocationPick(label: context.t('rem.locker'), value: _locker, lockersOnly: true, onChanged: (v) => setState(() => _locker = v)),
        gap,
        Row(children: [
          Expanded(child: DateIn(label: context.t('common.date'), value: _date, allowClear: false, onChanged: (v) => setState(() => _date = v!))),
          const SizedBox(width: 10),
          Expanded(child: TimeIn(label: context.t('common.time'), value: _time, onChanged: (v) => setState(() => _time = v))),
        ]),
        if (closed && _kind != 'custom') ...[
          const SizedBox(height: 10),
          GoldCard(
            accent: GV.danger,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: GV.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(context.t('hol.closedThatDay', {'why': closedWhy}))),
            ]),
          ),
        ],
        gap,
        Pick<String>(
          label: context.t('rem.repeat'),
          value: _repeat,
          items: [for (final r in Reminder.repeats) (r, context.t('rem.repeat.$r'))],
          onChanged: (v) => setState(() => _repeat = v ?? 'none'),
        ),
        if (_kind == 'keep' || _kind == 'take') ...[
          SectionTitle(context.t('rem.items')),
          GoldCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final i in _items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.diamond_outlined),
                  title: Text(i.name),
                  subtitle: Text(i.serial),
                  trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _items.remove(i))),
                ),
              OutlinedButton.icon(icon: const Icon(Icons.playlist_add), label: Text(context.t('rem.chooseItems')), onPressed: _pickItems),
              if (_kind == 'keep')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(context.t('rem.keepAutoDone'), style: const TextStyle(color: GV.muted, fontSize: 13.5)),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        SectionTitle(context.t('alert.options')),
        GoldCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: AlarmOptionsEditor(options: _opts, onChanged: () => setState(() {})),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_active_outlined, color: GV.gold, size: 28),
          title: Text(context.t('rem.enabled')),
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        gap,
        TextIn(_notes, context.t('item.notes'), lines: 2),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.alarm_add), label: Text(context.t('common.save'))),
        ),
      ),
    );
  }
}

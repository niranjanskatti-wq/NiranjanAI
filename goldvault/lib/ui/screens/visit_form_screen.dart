import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import '../../services/notifications.dart';
import 'item_picker_screen.dart';

/// Log a locker visit with items deposited and withdrawn.
class VisitFormScreen extends StatefulWidget {
  const VisitFormScreen({super.key, this.locationId, this.date, this.existing});
  final int? locationId;
  final DateTime? date;
  final Visit? existing;
  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _form = GlobalKey<FormState>();
  final _visitors = TextEditingController();
  final _purpose = TextEditingController();
  final _notes = TextEditingController();
  final _outNote = TextEditingController();
  int? _locker;
  late String _date;
  String? _in;
  String? _out;
  List<Item> _deposit = [];
  List<Item> _withdraw = [];
  String _withdrawStatus = Opt.atHome;
  int? _withdrawTo;
  bool _saving = false;
  bool _remindBack = false;
  String _backDate = Fmt.isoDate(DateTime.now().add(const Duration(days: 7)));
  String? _backTime;

  bool get _edit => widget.existing != null;

  static const _purposes = ['visit.p.deposit', 'visit.p.withdraw', 'visit.p.both', 'visit.p.check', 'visit.p.rent'];

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    if (v != null) {
      _locker = v.locationId;
      _date = v.visitDate;
      _in = v.timeIn;
      _out = v.timeOut;
      _visitors.text = v.visitors ?? '';
      _purpose.text = v.purpose ?? '';
      _notes.text = v.notes ?? '';
    } else {
      _locker = widget.locationId;
      final d = widget.date ?? DateTime.now();
      _date = Fmt.isoDate(d);
      if (Fmt.dateOnly(d) == Fmt.dateOnly(DateTime.now())) {
        final n = TimeOfDay.now();
        _in = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
      }
      _defaultHome();
    }
  }

  Future<void> _defaultHome() async {
    final locs = await AppServices.I.repo.locations();
    final firstPlace = locs.where((l) => !l.isLocker).toList();
    if (firstPlace.isNotEmpty && mounted) setState(() => _withdrawTo = firstPlace.first.id);
  }

  @override
  void dispose() {
    _visitors.dispose();
    _purpose.dispose();
    _notes.dispose();
    _outNote.dispose();
    super.dispose();
  }

  Future<void> _pick(bool deposit) async {
    if (_locker == null) {
      toast(context, context.t('visit.pickLockerFirst'));
      return;
    }
    final locker = _locker!;
    final ids = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemPickerScreen(
          title: deposit ? context.t('visit.deposited') : context.t('visit.withdrawn'),
          initial: (deposit ? _deposit : _withdraw).map((e) => e.id!).toList(),
          filter: deposit
              ? (i) => i.locationId != locker && !_withdraw.any((w) => w.id == i.id)
              : (i) => i.locationId == locker && !_deposit.any((w) => w.id == i.id),
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
    setState(() => deposit ? _deposit = items : _withdraw = items);
  }

  Future<void> _save() async {
    final tr = context.s;
    if (!_form.currentState!.validate()) return;
    if (_locker == null) {
      toast(context, context.t('visit.pickLockerFirst'));
      return;
    }
    if (_withdraw.isNotEmpty && Opt.placedStatuses.contains(_withdrawStatus) && _withdrawTo == null) {
      toast(context, context.t('item.needLocation'));
      return;
    }
    if (_in != null && _out != null && _out!.compareTo(_in!) < 0) {
      toast(context, context.t('visit.timeOrder'));
      return;
    }
    setState(() => _saving = true);
    final v = Visit(
      id: widget.existing?.id,
      locationId: _locker!,
      visitDate: _date,
      timeIn: _in,
      timeOut: _out,
      visitors: _visitors.text,
      purpose: _purpose.text,
      notes: _notes.text,
      createdAt: widget.existing?.createdAt,
    );
    final repo = AppServices.I.repo;
    if (_edit) {
      await repo.updateVisit(v);
    } else {
      await repo.logVisit(
        v,
        deposit: _deposit.map((e) => e.id!).toList(),
        withdraw: _withdraw.map((e) => e.id!).toList(),
        withdrawTo: _withdrawTo,
        withdrawStatus: _withdrawStatus,
        withdrawNote: _outNote.text,
      );
      if (_remindBack && _withdraw.isNotEmpty) {
        final l = await repo.location(_locker!);
        await repo.saveReminder(Reminder(
          kind: 'keep',
          title: tr.t('rem.keepTitle', {'where': l?.name ?? ''}),
          dueDate: _backDate,
          time: _backTime,
          locationId: _locker,
          itemIds: _withdraw.map((e) => e.id!).toList(),
          alarm: (await repo.prefs()).alarmByDefault,
          notes: _withdraw.map((i) => '${i.name} (${i.serial})').join(', '),
        ));
        await Notifier.requestPermission();
        await Notifier.requestExactAlarms();
      }
    }
    if (!mounted) return;
    toast(context, context.t('visit.saved', {'n': _deposit.length + _withdraw.length}));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? context.t('visit.edit') : context.t('visit.log'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
          if (_edit)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(context.t('visit.editNote'), style: const TextStyle(color: GV.muted)),
            )
          else
            LocationPick(
              label: context.t('visit.locker'),
              value: _locker,
              lockersOnly: true,
              required: true,
              onChanged: (v) => setState(() {
                _locker = v;
                _deposit = [];
                _withdraw = [];
              }),
            ),
          gap,
          DateIn(label: context.t('common.date'), value: _date, allowClear: false, onChanged: (v) => setState(() => _date = v!)),
          gap,
          Row(children: [
            Expanded(child: TimeIn(label: context.t('visit.timeIn'), value: _in, onChanged: (v) => setState(() => _in = v))),
            const SizedBox(width: 10),
            Expanded(child: TimeIn(label: context.t('visit.timeOut'), value: _out, onChanged: (v) => setState(() => _out = v))),
          ]),
          gap,
          TextIn(_visitors, context.t('visit.who'), hint: context.t('visit.whoHint')),
          gap,
          TextIn(_purpose, context.t('visit.purpose')),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in _purposes)
              ActionChip(label: Text(context.t(p)), onPressed: () => setState(() => _purpose.text = context.t(p))),
          ]),
          if (!_edit) ...[
            SectionTitle(context.t('visit.deposited')),
            _itemsBox(context, _deposit, true),
            SectionTitle(context.t('visit.withdrawn')),
            _itemsBox(context, _withdraw, false),
            if (_withdraw.isNotEmpty) ...[
              gap,
              Text(context.t('visit.withdrawWhere'), style: const TextStyle(color: GV.muted, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in const [Opt.atHome, Opt.worn, Opt.repair, Opt.lent, Opt.pledged, Opt.inLocker])
                  ChoiceChip(
                    label: Text(context.s.status(s)),
                    selected: _withdrawStatus == s,
                    onSelected: (_) => setState(() {
                      _withdrawStatus = s;
                      if (Opt.placedStatuses.contains(s)) _withdrawTo = null;
                    }),
                  ),
              ]),
              gap,
              if (Opt.placedStatuses.contains(_withdrawStatus))
                LocationPick(
                  label: context.t('item.location'),
                  value: _withdrawTo,
                  exclude: _locker,
                  placesOnly: _withdrawStatus == Opt.atHome,
                  lockersOnly: _withdrawStatus == Opt.inLocker,
                  onChanged: (v) => setState(() => _withdrawTo = v),
                )
              else
                TextIn(_outNote, context.t('item.statusNote'), hint: context.t('item.statusNoteHint')),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.alarm_add, color: GV.gold, size: 28),
                title: Text(context.t('visit.remindBack')),
                subtitle: Text(context.t('visit.remindBackSub')),
                value: _remindBack,
                onChanged: (v) => setState(() => _remindBack = v),
              ),
              if (_remindBack)
                Row(children: [
                  Expanded(child: DateIn(label: context.t('common.date'), value: _backDate, allowClear: false, onChanged: (v) => setState(() => _backDate = v!))),
                  const SizedBox(width: 10),
                  Expanded(child: TimeIn(label: context.t('common.time'), value: _backTime, onChanged: (v) => setState(() => _backTime = v))),
                ]),
            ],
          ],
          gap,
          TextIn(_notes, context.t('item.notes'), lines: 2),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(context.t('common.save')),
          ),
        ),
      ),
    );
  }

  Widget _itemsBox(BuildContext context, List<Item> items, bool deposit) {
    return GoldCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final i in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(deposit ? Icons.login : Icons.logout, color: deposit ? GV.gold : const Color(0xFF4FC3F7)),
            title: Text(i.name),
            subtitle: Text('${i.serial} · ${Fmt.grams(i.netWt ?? i.grossWt)}'),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => items.remove(i)),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.playlist_add),
          label: Text(deposit ? context.t('visit.addDeposit') : context.t('visit.addWithdraw')),
          onPressed: () => _pick(deposit),
        ),
      ]),
    );
  }
}

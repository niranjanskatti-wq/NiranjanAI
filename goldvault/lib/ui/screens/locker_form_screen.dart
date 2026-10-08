import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/security.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';

/// Add or edit a bank locker.
class LockerFormScreen extends StatefulWidget {
  const LockerFormScreen({super.key, this.location, this.info});
  final Location? location;
  final LockerInfo? info;
  @override
  State<LockerFormScreen> createState() => _LockerFormScreenState();
}

class _LockerFormScreenState extends State<LockerFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  String _bank = 'SBI';
  String? _size = 'Medium';
  String? _opened;
  String? _rentDue;
  int? _color;
  bool _saving = false;

  static const _keys = ['name', 'branch', 'address', 'lockerNo', 'keyNo', 'holders', 'joint', 'nominee', 'rent', 'contact', 'notes', 'otherBank'];

  @override
  void initState() {
    super.initState();
    c = {for (final k in _keys) k: TextEditingController()};
    final l = widget.location;
    final i = widget.info;
    if (l != null) {
      c['name']!.text = l.name;
      _color = l.color;
    }
    if (i != null) {
      if (Opt.banks.contains(i.bank)) {
        _bank = i.bank;
      } else {
        _bank = 'Other';
        c['otherBank']!.text = i.bank;
      }
      _size = i.size;
      _opened = i.openedDate;
      _rentDue = i.rentDueDate;
      c['branch']!.text = i.branch ?? '';
      c['address']!.text = i.branchAddress ?? '';
      c['lockerNo']!.text = i.lockerNo ?? '';
      c['keyNo']!.text = i.keyNo ?? '';
      c['holders']!.text = i.holders ?? '';
      c['joint']!.text = i.jointHolders ?? '';
      c['nominee']!.text = i.nominee ?? '';
      c['rent']!.text = i.annualRent == null ? '' : Fmt.decimal(i.annualRent);
      c['contact']!.text = i.bankContact ?? '';
      c['notes']!.text = i.notes ?? '';
    }
  }

  @override
  void dispose() {
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final bank = _bank == 'Other' && c['otherBank']!.text.trim().isNotEmpty ? c['otherBank']!.text.trim() : _bank;
    var name = c['name']!.text.trim();
    if (name.isEmpty) {
      final branch = c['branch']!.text.trim();
      name = '$bank Bank Locker${branch.isEmpty ? '' : ' – $branch'}';
    }
    await AppServices.I.repo.saveLocker(
      id: widget.location?.id,
      name: name,
      color: _color,
      info: LockerInfo(
        bank: bank,
        branch: c['branch']!.text,
        branchAddress: c['address']!.text,
        lockerNo: c['lockerNo']!.text,
        size: _size,
        keyNo: c['keyNo']!.text,
        openedDate: _opened,
        holders: c['holders']!.text,
        jointHolders: c['joint']!.text,
        nominee: c['nominee']!.text,
        annualRent: Fmt.parseNum(c['rent']!.text),
        rentDueDate: _rentDue,
        bankContact: c['contact']!.text,
        notes: c['notes']!.text,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.location == null ? context.t('loc.addLocker') : context.t('loc.editLocker'))),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
            Pick<String>(
              label: context.t('locker.bank'),
              value: _bank,
              required: true,
              items: [for (final b in Opt.banks) (b, context.s.opt(b))],
              onChanged: (v) => setState(() => _bank = v ?? _bank),
            ),
            if (_bank == 'Other') ...[gap, TextIn(c['otherBank']!, context.t('locker.otherBank'))],
            gap,
            TextIn(c['name']!, context.t('locker.name'), hint: context.t('locker.nameHint')),
            gap,
            TextIn(c['branch']!, context.t('locker.branch')),
            gap,
            TextIn(c['address']!, context.t('locker.address'), lines: 2),
            gap,
            Row(children: [
              Expanded(child: TextIn(c['lockerNo']!, context.t('locker.number'))),
              const SizedBox(width: 10),
              Expanded(child: TextIn(c['keyNo']!, context.t('locker.key'))),
            ]),
            gap,
            Pick<String>(
              label: context.t('locker.size'),
              value: _size,
              items: [for (final s in Opt.lockerSizes) (s, context.s.opt(s))],
              onChanged: (v) => setState(() => _size = v),
            ),
            gap,
            DateIn(label: context.t('locker.opened'), value: _opened, onChanged: (v) => setState(() => _opened = v)),
            SectionTitle(context.t('locker.people')),
            TextIn(c['holders']!, context.t('locker.holders')),
            gap,
            TextIn(c['joint']!, context.t('locker.joint')),
            gap,
            TextIn(c['nominee']!, context.t('locker.nominee')),
            SectionTitle(context.t('locker.rentSection')),
            TextIn(c['rent']!, context.t('locker.rent'), number: true, suffix: '₹'),
            gap,
            DateIn(label: context.t('locker.rentDue'), value: _rentDue, onChanged: (v) => setState(() => _rentDue = v)),
            gap,
            TextIn(c['contact']!, context.t('locker.contact'), phone: true),
            gap,
            TextIn(c['notes']!, context.t('item.notes'), lines: 3),
            SectionTitle(context.t('locker.colour')),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final col in Opt.palette)
                GestureDetector(
                  onTap: () => setState(() => _color = col),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(col),
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == col ? Colors.white : Colors.transparent, width: 3),
                    ),
                    child: _color == col ? const Icon(Icons.check, color: Colors.black) : null,
                  ),
                ),
            ]),
            if (_color == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(context.t('locker.autoColour'), style: const TextStyle(color: GV.muted)),
              ),
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
      ),
    );
  }
}

/// Close a locker: move everything inside to another place, then mark closed.
Future<void> closeLockerFlow(BuildContext context, Location l) async {
  final repo = AppServices.I.repo;
  final inside = await repo.itemsAt(l.id!);
  if (!context.mounted) return;
  int? target;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(context.t('loc.close'), style: Theme.of(c).textTheme.titleLarge),
          gap,
          Text(
            inside.isEmpty ? context.t('loc.closeEmpty') : context.t('loc.closeMove', {'n': inside.length}),
            style: const TextStyle(fontSize: 16),
          ),
          if (inside.isNotEmpty) ...[
            gap,
            LocationPick(label: context.t('loc.moveTo'), value: target, exclude: l.id, required: true, onChanged: (v) => set(() => target = v)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GV.danger),
            onPressed: () {
              if (inside.isNotEmpty && target == null) {
                toast(c, context.t('item.needLocation'));
                return;
              }
              Navigator.pop(c, true);
            },
            child: Text(context.t('loc.closeConfirm')),
          ),
        ]),
      ),
    ),
  );
  if (ok != true) return;
  await repo.closeLocker(l.id!, moveToId: target);
  if (context.mounted) toast(context, context.t('loc.closedToast'));
}

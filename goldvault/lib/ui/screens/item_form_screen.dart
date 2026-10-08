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
import 'item_detail_screen.dart';
import 'item_picker_screen.dart';

enum ItemFormMode { quick, purchase, full }

/// Entry point for the big "+ Add Ornament" button.
Future<void> showAddOrnamentSheet(BuildContext context, {int? locationId}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (c) {
      Widget opt(String key, IconData icon, String title, String sub) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            leading: CircleAvatar(radius: 26, backgroundColor: GV.gold.withValues(alpha: 0.15), child: Icon(icon, color: GV.gold, size: 28)),
            title: Text(title),
            subtitle: Text(sub),
            onTap: () => Navigator.pop(c, key),
          );
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.t('item.add'), style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 8),
            opt('quick', Icons.bolt, context.t('add.quick'), context.t('add.quickSub')),
            opt('purchase', Icons.receipt_long, context.t('add.purchase'), context.t('add.purchaseSub')),
            opt('full', Icons.list_alt, context.t('add.full'), context.t('add.fullSub')),
            opt('dup', Icons.copy_all, context.t('add.duplicate'), context.t('add.duplicateSub')),
            const SizedBox(height: 16),
          ]),
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'dup') {
    final picked = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(builder: (_) => ItemPickerScreen(title: context.t('add.pickToCopy'), single: true)),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    final src = await AppServices.I.repo.item(picked.first);
    if (src == null || !context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormScreen(duplicateOf: src)));
    return;
  }
  final mode = switch (choice) { 'quick' => ItemFormMode.quick, 'purchase' => ItemFormMode.purchase, _ => ItemFormMode.full };
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormScreen(mode: mode, locationId: locationId)));
}

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.mode = ItemFormMode.full, this.existing, this.duplicateOf, this.locationId});
  final ItemFormMode mode;
  final Item? existing;
  final Item? duplicateOf;
  final int? locationId;
  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  String _category = 'Gold';
  String? _purity = '22K';
  String? _type;
  String? _purchaseDate;
  String _status = Opt.inLocker;
  int? _locationId;
  List<String> _photos = [];
  String? _billPhoto;
  final List<String> _newFiles = []; // to clean up if the form is abandoned
  List<String> _initialFiles = [];
  bool _expanded = false;
  bool _saving = false;
  bool _saved = false;
  String _serial = '';
  Map<String, List<String>> _suggest = {};

  bool get _isEdit => widget.existing != null;
  bool get _quick => widget.mode == ItemFormMode.quick && !_expanded && !_isEdit;

  static const _fields = [
    'name', 'pieces', 'gross', 'net', 'stone', 'desc', 'stones', 'huid', 'shop', 'bill', 'rate', 'making', 'gst', 'total',
    'owner', 'occasion', 'giftedBy', 'tags', 'notes', 'statusNote', 'customPurity',
  ];

  @override
  void initState() {
    super.initState();
    c = {for (final f in _fields) f: TextEditingController()};
    c['pieces']!.text = '1';
    final src = widget.existing ?? widget.duplicateOf;
    if (src != null) {
      _fill(src);
    } else {
      _locationId = widget.locationId;
      if (widget.mode == ItemFormMode.purchase) {
        _status = Opt.atHome;
        _purchaseDate = Fmt.isoDate(DateTime.now());
      }
    }
    _expanded = widget.mode != ItemFormMode.quick;
    _init(src);
  }

  Future<void> _init(Item? src) async {
    final repo = AppServices.I.repo;
    _serial = _isEdit ? widget.existing!.serial : await repo.peekNextSerial();
    _suggest = {
      'owner': await repo.owners(),
      'shop': await repo.distinct('shop_name'),
      'occasion': await repo.distinct('occasion'),
      'giftedBy': await repo.distinct('gifted_by'),
      'name': {...Opt.itemTypes.where((e) => e != 'Other'), ...await repo.distinct('item_type')}.toList(),
    };
    if (_isEdit) {
      _photos = (await repo.photosFor(src!.id!)).map((p) => p.file).toList();
      _initialFiles = [..._photos, ?src.billPhoto];
    } else if (widget.duplicateOf != null) {
      // Copy photos as new encrypted files so each item owns its pictures.
      final photos = AppServices.I.photos;
      for (final p in await repo.photosFor(src!.id!)) {
        final bytes = await photos.load(p.file);
        if (bytes != null) {
          final f = await photos.save(bytes);
          _photos.add(f);
          _newFiles.add(f);
        }
      }
    }
    if (_locationId == null && !_isEdit) {
      final locs = await repo.locations();
      if (locs.isNotEmpty) {
        final pick = _status == Opt.inLocker ? locs.firstWhere((l) => l.isLocker, orElse: () => locs.first) : locs.firstWhere((l) => !l.isLocker, orElse: () => locs.first);
        _locationId = pick.id;
        _status = pick.isLocker ? Opt.inLocker : Opt.atHome;
      }
    }
    if (mounted) setState(() {});
  }

  void _fill(Item i) {
    String n(num? v) => v == null ? '' : Fmt.decimal(v);
    c['name']!.text = i.name;
    c['pieces']!.text = '${i.pieces}';
    c['gross']!.text = n(i.grossWt);
    c['net']!.text = n(i.netWt);
    c['stone']!.text = n(i.stoneWt);
    c['desc']!.text = i.description ?? '';
    c['stones']!.text = i.stones ?? '';
    c['huid']!.text = widget.duplicateOf != null ? '' : (i.huid ?? '');
    c['shop']!.text = i.shopName ?? '';
    c['bill']!.text = i.billNo ?? '';
    c['rate']!.text = n(i.ratePerGram);
    c['making']!.text = n(i.makingCharges);
    c['gst']!.text = n(i.gst);
    c['total']!.text = n(i.totalPrice);
    c['owner']!.text = i.owner ?? '';
    c['occasion']!.text = i.occasion ?? '';
    c['giftedBy']!.text = i.giftedBy ?? '';
    c['tags']!.text = i.tags ?? '';
    c['notes']!.text = i.notes ?? '';
    c['statusNote']!.text = i.statusNote ?? '';
    _category = i.category;
    final known = Opt.purities[_category] ?? const [];
    if (i.purity != null && !known.contains(i.purity)) {
      _purity = '__custom';
      c['customPurity']!.text = i.purity!;
    } else {
      _purity = i.purity;
    }
    _type = i.itemType;
    _purchaseDate = i.purchaseDate;
    _status = i.status;
    _locationId = i.locationId;
    if (_isEdit) _billPhoto = i.billPhoto;
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final f in _newFiles) {
        AppServices.I.photos.delete(f);
      }
    }
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }

  double? _n(String k) => Fmt.parseNum(c[k]!.text);
  String _t(String k) => c[k]!.text.trim();

  void _calcTotal() {
    final rate = _n('rate');
    final w = _n('net') ?? _n('gross');
    if (rate == null || w == null) {
      toast(context, context.t('item.calcNeed'));
      return;
    }
    final total = rate * w + (_n('making') ?? 0) + (_n('gst') ?? 0);
    setState(() => c['total']!.text = Fmt.decimal(total.roundToDouble()));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_t('name').isEmpty) {
      toast(context, '${context.t('item.name')}: ${context.t('common.required')}');
      return;
    }
    final placed = Opt.placedStatuses.contains(_status);
    if (placed && _locationId == null) {
      toast(context, context.t('item.needLocation'));
      return;
    }
    setState(() => _saving = true);
    final repo = AppServices.I.repo;
    final purity = _purity == '__custom' ? (_t('customPurity').isEmpty ? null : _t('customPurity')) : _purity;
    final item = Item(
      id: widget.existing?.id,
      serial: widget.existing?.serial ?? '',
      name: _t('name'),
      itemType: _type,
      category: _category,
      purity: purity,
      grossWt: _n('gross'),
      netWt: _n('net'),
      stoneWt: _n('stone'),
      pieces: (_n('pieces') ?? 1).round().clamp(1, 9999),
      description: _t('desc'),
      stones: _t('stones'),
      huid: _t('huid').toUpperCase(),
      purchaseDate: _purchaseDate,
      shopName: _t('shop'),
      billNo: _t('bill'),
      ratePerGram: _n('rate'),
      makingCharges: _n('making'),
      gst: _n('gst'),
      totalPrice: _n('total'),
      billPhoto: _billPhoto,
      owner: _t('owner'),
      occasion: _t('occasion'),
      giftedBy: _t('giftedBy'),
      locationId: placed ? _locationId : null,
      status: _status,
      statusNote: placed ? null : _t('statusNote'),
      tags: _t('tags'),
      notes: _t('notes'),
      needsDetails: _quick,
      createdAt: widget.existing?.createdAt,
    );
    try {
      int id;
      if (_isEdit) {
        await repo.updateItem(item, photos: _photos);
        id = item.id!;
        // Remove files that were dropped from the item.
        final keep = {..._photos, ?_billPhoto};
        for (final f in _initialFiles.where((f) => !keep.contains(f))) {
          await AppServices.I.photos.delete(f);
        }
      } else {
        id = (await repo.createItem(item, photos: _photos)).id!;
      }
      for (final f in _newFiles.where((f) => !{..._photos, ?_billPhoto}.contains(f))) {
        await AppServices.I.photos.delete(f);
      }
      _saved = true;
      if (!mounted) return;
      if (_isEdit) {
        Navigator.pop(context, true);
      } else {
        final serial = (await repo.item(id))?.serial ?? '';
        if (!mounted) return;
        toast(context, context.t('item.saved', {'serial': serial}));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: id)));
      }
    } catch (e) {
      if (mounted) toast(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit
        ? context.t('item.edit')
        : widget.duplicateOf != null
            ? context.t('add.duplicate')
            : switch (widget.mode) {
                ItemFormMode.quick => context.t('add.quick'),
                ItemFormMode.purchase => context.t('add.purchase'),
                ItemFormMode.full => context.t('add.full'),
              };
    final purchaseFirst = widget.mode == ItemFormMode.purchase && !_isEdit;
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 120), children: [
            if (_serial.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  const Icon(Icons.tag, color: GV.gold, size: 20),
                  const SizedBox(width: 6),
                  Text(context.t('item.serial'), style: const TextStyle(color: GV.muted)),
                  const SizedBox(width: 8),
                  Text(_serial, style: const TextStyle(color: GV.gold, fontWeight: FontWeight.w800, fontSize: 17)),
                ]),
              ),
            ..._basic(context),
            gap,
            PhotoGrid(
              label: context.t('item.photos'),
              files: _photos,
              onChanged: (v) => setState(() {
                _newFiles.addAll(v.where((f) => !_photos.contains(f)));
                _photos = v;
              }),
            ),
            if (purchaseFirst) ..._purchase(context),
            ..._placement(context),
            if (_quick) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                icon: const Icon(Icons.expand_more),
                label: Text(context.t('add.moreDetails')),
                onPressed: () => setState(() => _expanded = true),
              ),
              const SizedBox(height: 6),
              Text(context.t('add.quickNote'), textAlign: TextAlign.center, style: const TextStyle(color: GV.muted)),
            ] else ...[
              ..._details(context),
              if (!purchaseFirst) ..._purchase(context),
              ..._ownership(context),
            ],
          ]),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.check_circle_outline, size: 26),
              label: Text(context.t('common.save')),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _basic(BuildContext context) {
    final purities = Opt.purities[_category] ?? const ['—'];
    return [
      SuggestIn(c['name']!, '${context.t('item.name')} *', _suggest['name'] ?? Opt.itemTypes),
      gap,
      Text(context.t('item.category'), style: const TextStyle(color: GV.muted, fontSize: 15)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final cat in Opt.categories)
          ChoiceChip(
            label: Text(context.s.opt(cat), style: const TextStyle(fontSize: 16)),
            selected: _category == cat,
            onSelected: (_) => setState(() {
              _category = cat;
              final list = Opt.purities[cat] ?? const [];
              if (_purity != '__custom' && !list.contains(_purity)) _purity = list.isEmpty ? null : list[cat == 'Gold' && list.length > 1 ? 1 : 0];
            }),
          ),
      ]),
      gap,
      Row(children: [
        Expanded(
          child: Pick<String>(
            label: context.t('item.purity'),
            value: _purity,
            items: [for (final p in purities) (p, p), ('__custom', context.t('common.other'))],
            onChanged: (v) => setState(() => _purity = v),
          ),
        ),
        if (!_quick) ...[
          const SizedBox(width: 12),
          SizedBox(width: 110, child: TextIn(c['pieces']!, context.t('item.pieces'), number: true)),
        ],
      ]),
      if (_purity == '__custom') ...[gap, TextIn(c['customPurity']!, context.t('item.customPurity'))],
      gap,
      if (_quick)
        TextIn(c['gross']!, context.t('item.weight'), number: true, suffix: 'g')
      else
        Row(children: [
          Expanded(child: TextIn(c['gross']!, context.t('item.gross'), number: true, suffix: 'g')),
          const SizedBox(width: 10),
          Expanded(child: TextIn(c['net']!, context.t('item.net'), number: true, suffix: 'g')),
          const SizedBox(width: 10),
          Expanded(child: TextIn(c['stone']!, context.t('item.stone'), number: true, suffix: 'g')),
        ]),
    ];
  }

  List<Widget> _placement(BuildContext context) {
    final placed = Opt.placedStatuses.contains(_status);
    final statuses = _isEdit ? Opt.statuses : Opt.activeStatuses;
    return [
      SectionTitle(context.t('item.whereKept')),
      Pick<String>(
        label: context.t('item.status'),
        value: _status,
        items: [for (final s in statuses) (s, context.s.status(s))],
        onChanged: (v) => setState(() {
          if (v == null || v == _status) return;
          if (Opt.placedStatuses.contains(v)) _locationId = null; // locker vs home lists differ
          _status = v;
        }),
      ),
      gap,
      if (placed)
        LocationPick(
          label: context.t('item.location'),
          value: _locationId,
          required: true,
          lockersOnly: _status == Opt.inLocker,
          placesOnly: _status == Opt.atHome,
          onChanged: (v) => setState(() => _locationId = v),
        )
      else
        TextIn(c['statusNote']!, context.t('item.statusNote'), hint: context.t('item.statusNoteHint')),
    ];
  }

  List<Widget> _details(BuildContext context) => [
        SectionTitle(context.t('item.details')),
        Pick<String>(
          label: context.t('item.type'),
          value: _type,
          items: [for (final t in Opt.itemTypes) (t, context.s.opt(t))],
          onChanged: (v) => setState(() => _type = v),
        ),
        gap,
        TextIn(c['desc']!, context.t('item.description'), lines: 2),
        gap,
        TextIn(c['stones']!, context.t('item.stones')),
        gap,
        TextIn(c['huid']!, context.t('item.huid')),
      ];

  List<Widget> _purchase(BuildContext context) => [
        SectionTitle(context.t('item.purchase')),
        DateIn(label: context.t('item.purchaseDate'), value: _purchaseDate, onChanged: (v) => setState(() => _purchaseDate = v)),
        gap,
        SuggestIn(c['shop']!, context.t('item.shop'), _suggest['shop'] ?? const []),
        gap,
        Row(children: [
          Expanded(child: TextIn(c['bill']!, context.t('item.billNo'))),
          const SizedBox(width: 10),
          Expanded(child: TextIn(c['rate']!, context.t('item.rate'), number: true, suffix: '₹/g')),
        ]),
        gap,
        Row(children: [
          Expanded(child: TextIn(c['making']!, context.t('item.making'), number: true, suffix: '₹')),
          const SizedBox(width: 10),
          Expanded(child: TextIn(c['gst']!, context.t('item.gst'), number: true, suffix: '₹')),
        ]),
        gap,
        Row(children: [
          Expanded(child: TextIn(c['total']!, context.t('item.total'), number: true, suffix: '₹')),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: context.t('item.calc'),
            iconSize: 26,
            style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            onPressed: _calcTotal,
            icon: const Icon(Icons.calculate_outlined),
          ),
        ]),
        gap,
        PhotoGrid(
          label: context.t('item.billPhoto'),
          max: 1,
          files: [?_billPhoto],
          onChanged: (v) => setState(() {
            if (v.isNotEmpty && v.first != _billPhoto) _newFiles.add(v.first);
            _billPhoto = v.isEmpty ? null : v.first;
          }),
        ),
      ];

  List<Widget> _ownership(BuildContext context) => [
        SectionTitle(context.t('item.ownership')),
        SuggestIn(c['owner']!, context.t('item.owner'), _suggest['owner'] ?? const []),
        gap,
        SuggestIn(c['occasion']!, context.t('item.occasion'), _suggest['occasion'] ?? const []),
        gap,
        SuggestIn(c['giftedBy']!, context.t('item.giftedBy'), _suggest['giftedBy'] ?? const []),
        gap,
        TextIn(c['tags']!, context.t('item.tags'), hint: context.t('item.tagsHint')),
        gap,
        TextIn(c['notes']!, context.t('item.notes'), lines: 3),
      ];
}

import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/security.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'item_form_screen.dart';
import 'move_item_sheet.dart';

class _Detail {
  final Item item;
  final List<ItemPhoto> photos;
  final List<Movement> history;
  final Map<int, Location> locs;
  final Rates rates;
  _Detail(this.item, this.photos, this.history, this.locs, this.rates);
}

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final int itemId;

  Future<_Detail?> _load() async {
    final repo = AppServices.I.repo;
    final i = await repo.item(itemId);
    if (i == null) return null;
    return _Detail(i, await repo.photosFor(itemId), await repo.historyFor(itemId), await repo.locationMap(), await repo.rates());
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: DataBuilder<_Detail?>(
        load: _load,
        builder: (context, d) {
          if (d == null) return const Scaffold(body: SizedBox());
          final i = d.item;
          return Scaffold(
            appBar: AppBar(
              title: Text(i.serial),
              actions: [
                IconButton(
                  iconSize: 28,
                  tooltip: context.t('common.edit'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormScreen(existing: i))),
                ),
                PopupMenuButton<String>(
                  color: GV.surface2,
                  onSelected: (v) => _menu(context, v, i),
                  itemBuilder: (c) => [
                    PopupMenuItem(value: 'dup', child: ListTile(leading: const Icon(Icons.copy_all), title: Text(context.t('add.duplicate')))),
                    if (i.isActive)
                      PopupMenuItem(value: 'dispose', child: ListTile(leading: const Icon(Icons.sell_outlined), title: Text(context.t('item.dispose')))),
                    PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete_outline, color: GV.danger), title: Text(context.t('item.delete')))),
                  ],
                ),
              ],
            ),
            body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
              _gallery(context, d),
              const SizedBox(height: 16),
              Text(i.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                [context.s.opt(i.category), if (i.purity != null) i.purity!, if (i.itemType != null) context.s.opt(i.itemType)].join(' · '),
                style: const TextStyle(color: GV.muted, fontSize: 16),
              ),
              const SizedBox(height: 14),
              _whereCard(context, d),
              if (i.needsDetails) ...[
                const SizedBox(height: 12),
                GoldCard(
                  accent: GV.goldLight,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormScreen(existing: i))),
                  child: Row(children: [
                    const Icon(Icons.edit_note, color: GV.goldLight, size: 30),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.t('item.needsDetails'))),
                    const Icon(Icons.chevron_right, color: GV.gold),
                  ]),
                ),
              ],
              const SizedBox(height: 14),
              if (i.isActive)
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(context.t('item.move')),
                      onPressed: () => showMoveItemSheet(context, i),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sell_outlined),
                      label: Text(context.t('item.dispose')),
                      onPressed: () => showMoveItemSheet(context, i, dispose: true),
                    ),
                  ),
                ]),
              SectionTitle(context.t('item.weights')),
              _facts([
                (context.t('item.gross'), Fmt.grams(i.grossWt), false),
                (context.t('item.net'), Fmt.grams(i.netWt), false),
                (context.t('item.stone'), Fmt.grams(i.stoneWt), false),
                (context.t('item.pieces'), '${i.pieces}', false),
                if (d.rates.isSet) (context.t('dash.value'), Fmt.rupees(d.rates.valueOf(i)), true),
              ]),
              if (_any([i.description, i.stones, i.huid])) ...[
                SectionTitle(context.t('item.details')),
                _facts([
                  if (i.description != null) (context.t('item.description'), i.description!, false),
                  if (i.stones != null) (context.t('item.stones'), i.stones!, false),
                  if (i.huid != null) (context.t('item.huid'), i.huid!, true),
                ]),
              ],
              if (_any([i.purchaseDate, i.shopName, i.billNo, i.ratePerGram, i.totalPrice, i.billPhoto])) ...[
                SectionTitle(context.t('item.purchase')),
                _facts([
                  if (i.purchaseDate != null) (context.t('item.purchaseDate'), Fmt.date(Fmt.parse(i.purchaseDate)), false),
                  if (i.shopName != null) (context.t('item.shop'), i.shopName!, false),
                  if (i.billNo != null) (context.t('item.billNo'), i.billNo!, true),
                  if (i.ratePerGram != null) (context.t('item.rate'), '${Fmt.rupees(i.ratePerGram, paise: true)}/g', true),
                  if (i.makingCharges != null) (context.t('item.making'), Fmt.rupees(i.makingCharges, paise: true), true),
                  if (i.gst != null) (context.t('item.gst'), Fmt.rupees(i.gst, paise: true), true),
                  if (i.totalPrice != null) (context.t('item.total'), Fmt.rupees(i.totalPrice, paise: true), true),
                ]),
                if (i.billPhoto != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _fullscreen(context, [i.billPhoto!], 0),
                    child: ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 160, child: VaultImage(i.billPhoto, fit: BoxFit.cover))),
                  ),
                ],
              ],
              if (_any([i.owner, i.occasion, i.giftedBy, i.tags, i.notes])) ...[
                SectionTitle(context.t('item.ownership')),
                _facts([
                  if (i.owner != null) (context.t('item.owner'), i.owner!, false),
                  if (i.occasion != null) (context.t('item.occasion'), i.occasion!, false),
                  if (i.giftedBy != null) (context.t('item.giftedBy'), i.giftedBy!, false),
                  if (i.notes != null) (context.t('item.notes'), i.notes!, false),
                ]),
                if (i.tagList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final t in i.tagList) Chip(label: Text('#$t'))]),
                ],
              ],
              SectionTitle(context.t('item.history')),
              GoldCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [for (final m in d.history) MovementTile(m)]),
              ),
            ]),
          );
        },
      ),
    );
  }

  static bool _any(List<Object?> v) => v.any((e) => e != null && e != '');

  Widget _whereCard(BuildContext context, _Detail d) {
    final i = d.item;
    final loc = i.locationId == null ? null : d.locs[i.locationId];
    final parent = loc?.parentId == null ? null : d.locs[loc!.parentId];
    final last = d.history.isEmpty ? null : d.history.first;
    return GoldCard(
      accent: loc == null ? statusColor(i.status) : Color(loc.color),
      child: Row(children: [
        Icon(loc?.isLocker == true ? Icons.account_balance : (loc == null ? Icons.directions_walk : Icons.home_outlined),
            color: loc == null ? statusColor(i.status) : Color(loc.color), size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StatusChip(i.status),
            const SizedBox(height: 6),
            Text(
              loc == null ? (i.statusNote ?? context.s.status(i.status)) : (parent == null ? loc.name : '${parent.name} › ${loc.name}'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (last != null)
              Text(context.t('where.since', {'date': Fmt.dateTime(last.at)}), style: const TextStyle(color: GV.muted, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }

  Widget _facts(List<(String, String, bool)> rows) => GoldCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(children: [
          for (final (k, v, sensitive) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 130, child: Text(k, style: const TextStyle(color: GV.muted, fontSize: 15))),
                Expanded(
                  child: sensitive
                      ? Align(alignment: Alignment.centerLeft, child: RevealText(v, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)))
                      : Text(v, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
        ]),
      );

  Widget _gallery(BuildContext context, _Detail d) {
    final files = d.photos.map((p) => p.file).toList();
    if (files.isEmpty) {
      return Hero(
        tag: 'item-photo-${d.item.id}',
        child: ClipRRect(borderRadius: BorderRadius.circular(22), child: const SizedBox(height: 180, child: VaultImage(null))),
      );
    }
    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: PageController(viewportFraction: files.length > 1 ? 0.9 : 1),
        itemCount: files.length,
        itemBuilder: (c, idx) {
          final img = ClipRRect(borderRadius: BorderRadius.circular(22), child: VaultImage(files[idx]));
          return Padding(
            padding: EdgeInsets.only(right: files.length > 1 ? 10 : 0),
            child: GestureDetector(
              onTap: () => _fullscreen(context, files, idx),
              child: idx == 0 ? Hero(tag: 'item-photo-${d.item.id}', child: img) : img,
            ),
          );
        },
      ),
    );
  }

  void _fullscreen(BuildContext context, List<String> files, int start) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecureScreen(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black),
            body: PageView(
              controller: PageController(initialPage: start),
              children: [for (final f in files) InteractiveViewer(maxScale: 5, child: Center(child: VaultImage(f, fit: BoxFit.contain)))],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, String v, Item i) async {
    switch (v) {
      case 'dup':
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormScreen(duplicateOf: i)));
        break;
      case 'dispose':
        await showMoveItemSheet(context, i, dispose: true);
        break;
      case 'delete':
        final ok = await confirm(context, context.t('item.delete'), context.t('item.deleteWarn'), ok: context.t('item.delete'), danger: true);
        if (!ok) return;
        final files = await AppServices.I.repo.deleteItem(i.id!);
        for (final f in files) {
          await AppServices.I.photos.delete(f);
        }
        if (context.mounted) Navigator.pop(context);
        break;
    }
  }
}

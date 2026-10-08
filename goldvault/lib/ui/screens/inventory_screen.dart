import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import '../widgets/tiles.dart';
import 'item_form_screen.dart';

class _Inv {
  final List<Item> items;
  final Map<int, String> photos;
  final Map<int, Location> locs;
  _Inv(this.items, this.photos, this.locs);
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  ItemQuery _q = ItemQuery(statuses: Opt.activeStatuses.toSet());

  Future<_Inv> _load() async {
    final repo = AppServices.I.repo;
    return _Inv(await repo.items(_q), await repo.firstPhotos(), await repo.locationMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('inv.title')),
        actions: [
          PopupMenuButton<String>(
            tooltip: context.t('inv.sort'),
            icon: const Icon(Icons.sort, size: 28),
            color: GV.surface2,
            onSelected: (v) => setState(() {
              if (_q.sort == v) {
                _q = _q.copyWith(descending: !_q.descending);
              } else {
                _q = _q.copyWith(sort: v, descending: v == 'weight' || v == 'date' || v == 'purchase');
              }
            }),
            itemBuilder: (c) => [
              for (final s in const ['serial', 'name', 'weight', 'category', 'location', 'date', 'purchase'])
                CheckedPopupMenuItem(value: s, checked: _q.sort == s, child: Text(context.t('sort.$s'))),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: AddOrnamentFab(onPressed: () => showAddOrnamentSheet(context)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _search,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: GV.gold),
                  hintText: context.t('inv.search'),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _search.clear();
                            _q = _q.copyWith(text: '');
                          })),
                ),
                onChanged: (v) => setState(() => _q = _q.copyWith(text: v)),
              ),
            ),
            const SizedBox(width: 10),
            Badge(
              isLabelVisible: _filterCount > 0,
              label: Text('$_filterCount'),
              child: IconButton.filledTonal(
                iconSize: 28,
                style: IconButton.styleFrom(minimumSize: const Size(56, 56), backgroundColor: GV.surface2),
                icon: const Icon(Icons.filter_list, color: GV.gold),
                onPressed: _openFilters,
              ),
            ),
          ]),
        ),
        Expanded(
          child: DataBuilder<_Inv>(
            load: _load,
            watch: _q,
            builder: (context, d) {
              if (d.items.isEmpty) {
                return EmptyState(
                  icon: Icons.diamond_outlined,
                  text: _q.text.isNotEmpty || _q.hasFilters ? context.t('inv.noMatch') : context.t('inv.empty'),
                );
              }
              final weight = d.items.fold<double>(0, (s, i) => s + i.metalWeight);
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                itemCount: d.items.length + 1,
                itemBuilder: (c, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                      child: Text(context.t('inv.summary', {'n': d.items.length, 'w': Fmt.grams(weight)}),
                          style: const TextStyle(color: GV.muted)),
                    );
                  }
                  final it = d.items[i - 1];
                  return ItemCard(item: it, photo: d.photos[it.id], locations: d.locs, index: i - 1);
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  int get _filterCount {
    var n = _q.categories.length + _q.locationIds.length + _q.owners.length;
    if (_q.statuses.length != Opt.activeStatuses.length || !_q.statuses.containsAll(Opt.activeStatuses)) n++;
    return n;
  }

  Future<void> _openFilters() async {
    final repo = AppServices.I.repo;
    final locs = await repo.locations(includeClosed: true);
    final all = {for (final l in locs) l.id!: l};
    final owners = await repo.owners();
    if (!mounted) return;
    var q = _q;
    final r = await showModalBottomSheet<ItemQuery>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(builder: (c, set) {
        Widget chips<T>(String title, List<(T, String)> opts, Set<T> sel, void Function(Set<T>) update) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 8), child: Text(title, style: Theme.of(c).textTheme.titleMedium)),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final o in opts)
                    FilterChip(
                      label: Text(o.$2),
                      selected: sel.contains(o.$1),
                      onSelected: (v) => set(() => update(v ? ({...sel, o.$1}) : ({...sel}..remove(o.$1)))),
                    ),
                ]),
              ],
            );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (c, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            Text(context.t('inv.filters'), style: Theme.of(c).textTheme.titleLarge),
            chips<String>(context.t('item.status'), [for (final s in Opt.statuses) (s, context.s.status(s))], q.statuses,
                (v) => q = q.copyWith(statuses: v)),
            chips<String>(context.t('item.category'), [for (final s in Opt.categories) (s, context.s.opt(s))], q.categories,
                (v) => q = q.copyWith(categories: v)),
            chips<int>(context.t('item.location'), [
              for (final l in locs) (l.id!, locLabel(l, all) + (l.isClosed ? ' (${context.t('loc.closed')})' : '')),
              (-1, context.t('inv.outside')),
            ], q.locationIds, (v) => q = q.copyWith(locationIds: v)),
            if (owners.isNotEmpty)
              chips<String>(context.t('item.owner'), [for (final o in owners) (o, o)], q.owners, (v) => q = q.copyWith(owners: v)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                      c, ItemQuery(text: q.text, sort: q.sort, descending: q.descending, statuses: Opt.activeStatuses.toSet())),
                  child: Text(context.t('inv.clear')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(c, q), child: Text(context.t('inv.apply')))),
            ]),
          ]),
        );
      }),
    );
    if (r != null) setState(() => _q = r);
  }
}

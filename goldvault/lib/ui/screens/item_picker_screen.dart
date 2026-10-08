import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

/// Search + multi-select items. Returns the selected item ids.
class ItemPickerScreen extends StatefulWidget {
  const ItemPickerScreen({super.key, required this.title, this.filter, this.initial = const [], this.single = false});
  final String title;
  final bool Function(Item)? filter;
  final List<int> initial;
  final bool single;
  @override
  State<ItemPickerScreen> createState() => _ItemPickerScreenState();
}

class _ItemPickerScreenState extends State<ItemPickerScreen> {
  late final Set<int> _sel = {...widget.initial};
  String _text = '';

  Future<(List<Item>, Map<int, String>, Map<int, Location>)> _load() async {
    final repo = AppServices.I.repo;
    final all = await repo.items(ItemQuery(text: _text, statuses: Opt.activeStatuses.toSet(), sort: 'name'));
    return (all.where(widget.filter ?? (_) => true).toList(), await repo.firstPhotos(), await repo.locationMap());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            style: const TextStyle(fontSize: 17),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search, color: GV.gold), hintText: context.t('inv.search')),
            onChanged: (v) => setState(() => _text = v),
          ),
        ),
        Expanded(
          child: DataBuilder<(List<Item>, Map<int, String>, Map<int, Location>)>(
            load: _load,
            watch: _text,
            builder: (c, d) {
              final (items, photos, locs) = d;
              if (items.isEmpty) return EmptyState(icon: Icons.search_off, text: context.t('picker.none'));
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  for (final i in items)
                    ItemCard(
                      item: i,
                      photo: photos[i.id],
                      locations: locs,
                      selected: _sel.contains(i.id),
                      onTap: () {
                        if (widget.single) {
                          Navigator.pop(context, [i.id!]);
                          return;
                        }
                        setState(() => _sel.contains(i.id) ? _sel.remove(i.id) : _sel.add(i.id!));
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ]),
      bottomNavigationBar: widget.single
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _sel.toList()),
                  child: Text(context.t('picker.done', {'n': _sel.length})),
                ),
              ),
            ),
    );
  }
}

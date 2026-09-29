import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../contacts/contacts_helper.dart';

/// A person's photos, newest year first.
final memoriesProvider = StreamProvider.family<List<PhotoMemory>, int>((ref, personId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.photoMemories)
        ..where((m) => m.personId.equals(personId))
        ..orderBy([(m) => OrderingTerm.desc(m.year), (m) => OrderingTerm.desc(m.createdAt)]))
      .watch();
});

Map<int, List<PhotoMemory>> _byYear(List<PhotoMemory> list) {
  final out = <int, List<PhotoMemory>>{};
  for (final m in list) {
    (out[m.year] ??= []).add(m);
  }
  return out;
}

String _yearLabel(int year, Person p) {
  final age = p.birthYear == null ? null : year - p.birthYear!;
  return age != null && age > 0 && age < 120 ? '$year · turned $age' : '$year';
}

Future<int?> _pickYear(BuildContext context, {int? initial, int? from}) {
  final now = DateTime.now().year;
  final first = (from ?? now - 60).clamp(1900, now);
  var year = initial ?? now;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: const Text('Which year are these from?'),
        content: SizedBox(
          width: 280,
          height: 260,
          child: YearPicker(
            firstDate: DateTime(first),
            lastDate: DateTime(now),
            selectedDate: DateTime(year),
            onChanged: (d) => set(() => year = d.year),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, year), child: Text('Save to $year')),
        ],
      ),
    ),
  );
}

/// Picks photos, asks for the year and saves them.
Future<void> addMemories(BuildContext context, WidgetRef ref, Person p) async {
  final picked = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85);
  if (picked.isEmpty || !context.mounted) return;
  final year = await _pickYear(context, from: p.birthYear);
  if (year == null) return;
  final db = ref.read(databaseProvider);
  for (final x in picked) {
    final path = await savePhotoBytes(await x.readAsBytes());
    await db.into(db.photoMemories).insert(PhotoMemoriesCompanion.insert(personId: p.id, year: year, path: path));
  }
  HapticFeedback.lightImpact();
  if (context.mounted) showToast(context, picked.length == 1 ? 'Photo added to $year' : '${picked.length} photos added to $year');
}

Widget _thumb(PhotoMemory m, {double? size, BoxFit fit = BoxFit.cover}) => Image.file(
      File(m.path),
      width: size,
      height: size,
      fit: fit,
      cacheWidth: size == null ? null : (size * 3).round(),
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: Colors.black12,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );

/// Profile card: a small album that grows every year.
class MemoriesCard extends ConsumerWidget {
  const MemoriesCard({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final list = ref.watch(memoriesProvider(person.id)).value ?? const [];
    final years = _byYear(list);
    return InfoCard(
      title: 'Photo memories',
      trailing: TextButton.icon(
        onPressed: () => addMemories(context, ref, person),
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
        label: const Text('Add'),
      ),
      children: [
        if (list.isEmpty)
          Text('Add a photo from each birthday or visit. A little album that grows every year.',
              style: context.text.bodyMedium?.copyWith(color: c.muted))
        else ...[
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final e in years.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => context.push('/person/${person.id}/memories'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.chip),
                          child: Stack(children: [
                            _thumb(e.value.first, size: 68),
                            if (e.value.length > 1)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                  child: Text('${e.value.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        Text('${e.key}', style: context.text.labelMedium),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/person/${person.id}/memories'),
              child: Text('See all ${list.length} photos'),
            ),
          ),
        ],
      ],
    );
  }
}

/// All of a person's photos by year.
class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(personProvider(personId)).value;
    final list = ref.watch(memoriesProvider(personId)).value ?? const [];
    if (p == null) return const Scaffold();
    final years = _byYear(list);
    return Scaffold(
      appBar: AppBar(title: Text('${p.nickname?.trim().isNotEmpty == true ? p.nickname : p.name} · memories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addMemories(context, ref, p),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add photos'),
      ),
      body: list.isEmpty
          ? const EmptyState(
              title: 'No photos yet',
              message: 'Add photos from birthdays, weddings and visits. Each one is kept under its year.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                for (final e in years.entries) ...[
                  SectionLabel(_yearLabel(e.key, p)),
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final m in e.value)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => _Viewer(person: p, list: list, start: list.indexOf(m)),
                          )),
                          child: ClipRRect(borderRadius: BorderRadius.circular(Radii.chip), child: _thumb(m, size: 120)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _Viewer extends ConsumerStatefulWidget {
  const _Viewer({required this.person, required this.list, required this.start});

  final Person person;
  final List<PhotoMemory> list;
  final int start;

  @override
  ConsumerState<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends ConsumerState<_Viewer> {
  late final _page = PageController(initialPage: widget.start);
  late List<PhotoMemory> _list = widget.list;
  late int _i = widget.start;

  PhotoMemory get _m => _list[_i];

  Future<void> _update(PhotoMemoriesCompanion c) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.photoMemories)..where((t) => t.id.equals(_m.id))).write(c);
    final fresh = await (db.select(db.photoMemories)..where((t) => t.id.equals(_m.id))).getSingle();
    setState(() => _list = [..._list]..[_i] = fresh);
  }

  Future<void> _caption() async {
    final t = TextEditingController(text: _m.caption ?? '');
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Caption'),
        content: TextField(
          controller: t,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. 60th birthday at home'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, t.text), child: const Text('Save')),
        ],
      ),
    );
    if (v != null) await _update(PhotoMemoriesCompanion(caption: Value(v.trim().isEmpty ? null : v.trim())));
  }

  Future<void> _year() async {
    final y = await _pickYear(context, initial: _m.year, from: widget.person.birthYear);
    if (y != null) await _update(PhotoMemoriesCompanion(year: Value(y)));
  }

  Future<void> _delete() async {
    final ok = await confirm(context,
        title: 'Delete this photo?', message: 'It is removed from Smriti only, not from your Gallery.', action: 'Delete', danger: true);
    if (!ok) return;
    final m = _m;
    final db = ref.read(databaseProvider);
    await (db.delete(db.photoMemories)..where((t) => t.id.equals(m.id))).go();
    try {
      await File(m.path).delete();
    } catch (_) {}
    if (!mounted) return;
    if (_list.length == 1) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _list = [..._list]..removeAt(_i);
      _i = _i.clamp(0, _list.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_yearLabel(m.year, widget.person)),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(m.path)], text: m.caption)),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'caption':
                  await _caption();
                case 'year':
                  await _year();
                case 'gallery':
                  try {
                    if (!await Gal.hasAccess(toAlbum: true)) await Gal.requestAccess(toAlbum: true);
                    await Gal.putImage(m.path, album: 'Smriti');
                    if (context.mounted) showToast(context, 'Saved to Gallery');
                  } catch (e) {
                    if (context.mounted) showToast(context, 'Could not save: $e');
                  }
                case 'delete':
                  await _delete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'caption', child: Text('Edit caption')),
              PopupMenuItem(value: 'year', child: Text('Change year')),
              PopupMenuItem(value: 'gallery', child: Text('Save to Gallery')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: Stack(children: [
        PageView.builder(
          controller: _page,
          itemCount: _list.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) => InteractiveViewer(child: Center(child: _thumb(_list[i], fit: BoxFit.contain))),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _caption,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              color: Colors.black54,
              child: Text(
                m.caption ?? 'Tap to add a caption',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: serif,
                  fontSize: 20,
                  color: m.caption == null ? Colors.white54 : Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

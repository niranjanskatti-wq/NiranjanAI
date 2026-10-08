import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_services.dart';
import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import 'common.dart';

const gap = SizedBox(height: 14);

/// Photos allowed per ornament.
const maxPhotos = 5;

class TextIn extends StatelessWidget {
  const TextIn(this.controller, this.label,
      {super.key, this.number = false, this.phone = false, this.lines = 1, this.required = false, this.hint, this.suffix, this.onChanged, this.autofocus = false});
  final TextEditingController controller;
  final String label;
  final bool number;
  final bool phone;
  final int lines;
  final bool required;
  final String? hint;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 2,
      style: const TextStyle(fontSize: 17),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : phone
              ? TextInputType.phone
              : (lines > 1 ? TextInputType.multiline : TextInputType.text),
      inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
      textCapitalization: number || phone ? TextCapitalization.none : TextCapitalization.sentences,
      decoration: InputDecoration(labelText: required ? '$label *' : label, hintText: hint, suffixText: suffix),
      onChanged: onChanged,
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return context.t('common.required');
        if (number && v != null && v.trim().isNotEmpty && Fmt.parseNum(v) == null) return context.t('common.invalidNumber');
        return null;
      },
    );
  }
}

/// Text field with suggestions from previously used values.
class SuggestIn extends StatefulWidget {
  const SuggestIn(this.controller, this.label, this.options, {super.key});
  final TextEditingController controller;
  final String label;
  final List<String> options;
  @override
  State<SuggestIn> createState() => _SuggestInState();
}

class _SuggestInState extends State<SuggestIn> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (v) {
        final q = v.text.toLowerCase();
        return widget.options.where((o) => o.toLowerCase().contains(q) && o != v.text);
      },
      fieldViewBuilder: (c, ctrl, focus, submit) => TextFormField(
        controller: ctrl,
        focusNode: focus,
        style: const TextStyle(fontSize: 17),
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label),
      ),
      optionsViewBuilder: (c, onSelected, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: GV.surface2,
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [for (final o in opts) ListTile(title: Text(o), onTap: () => onSelected(o))],
            ),
          ),
        ),
      ),
    );
  }
}

class Pick<T> extends StatelessWidget {
  const Pick({super.key, required this.label, required this.value, required this.items, required this.onChanged, this.required = false});
  final String label;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final bool required;
  @override
  Widget build(BuildContext context) {
    final has = items.any((e) => e.$1 == value);
    return DropdownButtonFormField<T>(
      initialValue: has ? value : null,
      isExpanded: true,
      dropdownColor: GV.surface2,
      style: const TextStyle(fontSize: 17, color: GV.text, fontFamily: GV.body),
      decoration: InputDecoration(labelText: required ? '$label *' : label),
      items: [for (final e in items) DropdownMenuItem(value: e.$1, child: Text(e.$2, overflow: TextOverflow.ellipsis))],
      onChanged: onChanged,
      validator: required ? (v) => v == null ? context.t('common.required') : null : null,
    );
  }
}

class DateIn extends StatelessWidget {
  const DateIn({super.key, required this.label, required this.value, required this.onChanged, this.allowClear = true});
  final String label;
  final String? value; // yyyy-MM-dd
  final ValueChanged<String?> onChanged;
  final bool allowClear;
  @override
  Widget build(BuildContext context) {
    final d = Fmt.parse(value);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final r = await showDatePicker(
          context: context,
          initialDate: d ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (r != null) onChanged(Fmt.isoDate(r));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: (allowClear && d != null)
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () => onChanged(null))
              : const Icon(Icons.calendar_month_outlined, color: GV.gold),
        ),
        child: Text(d == null ? '' : Fmt.date(d), style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}

class TimeIn extends StatelessWidget {
  const TimeIn({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final String? value; // HH:mm
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        TimeOfDay init = TimeOfDay.now();
        if (value != null && value!.contains(':')) {
          final p = value!.split(':');
          init = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
        final r = await showTimePicker(context: context, initialTime: init);
        if (r != null) {
          onChanged('${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule, color: GV.gold),
        ),
        child: Text(value == null ? '' : Fmt.hhmm(value), style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}

/// Human readable label for a location ("Home › Almirah").
String locLabel(Location l, Map<int, Location> all) {
  final parent = l.parentId == null ? null : all[l.parentId];
  return parent == null ? l.name : '${parent.name} › ${l.name}';
}

/// Picks one of the active locations, ordered lockers first, then places.
class LocationPick extends StatelessWidget {
  const LocationPick({super.key, required this.label, required this.value, required this.onChanged, this.exclude, this.lockersOnly = false, this.placesOnly = false, this.required = false});
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final int? exclude;
  final bool lockersOnly;
  final bool placesOnly;
  final bool required;
  @override
  Widget build(BuildContext context) {
    return DataBuilder<List<Location>>(
      load: () => AppServices.I.repo.locations(),
      builder: (c, locs) {
        final all = {for (final l in locs) l.id!: l};
        final list = locs.where((l) {
          if (l.id == exclude) return false;
          if (lockersOnly && !l.isLocker) return false;
          if (placesOnly && l.isLocker) return false;
          return true;
        }).toList()
          ..sort((a, b) {
            int rank(Location l) => l.isLocker ? 0 : 1;
            final r = rank(a).compareTo(rank(b));
            if (r != 0) return r;
            return locLabel(a, all).compareTo(locLabel(b, all));
          });
        return Pick<int>(
          label: label,
          value: value,
          required: required,
          items: [for (final l in list) (l.id!, locLabel(l, all))],
          onChanged: onChanged,
        );
      },
    );
  }
}

/// Up to [max] encrypted photos, from camera or gallery.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.files, required this.onChanged, this.max = maxPhotos, this.label});
  final List<String> files;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final String? label;

  /// Camera (one photo) or gallery (several at once, up to [limit]).
  /// Returns the saved, encrypted photo file names.
  static Future<List<String>> capture(BuildContext context, {int limit = 1}) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: Text(context.t('photo.camera')), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(context.t('photo.gallery')), onTap: () => Navigator.pop(c, ImageSource.gallery)),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (src == null || limit < 1) return const [];
    final picker = ImagePicker();
    final List<XFile> picked;
    if (src == ImageSource.gallery && limit > 1) {
      picked = (await picker.pickMultiImage(maxWidth: 1800, maxHeight: 1800, imageQuality: 78, limit: limit)).take(limit).toList();
    } else {
      final x = await picker.pickImage(source: src, maxWidth: 1800, maxHeight: 1800, imageQuality: 78);
      picked = [?x];
    }
    final out = <String>[];
    for (final x in picked) {
      out.add(await AppServices.I.photos.save(await x.readAsBytes()));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text('$label (${files.length}/$max)', style: const TextStyle(color: GV.muted, fontSize: 15)),
        ),
      SizedBox(
        height: 96,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final f in files)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(children: [
                PhotoThumb(f, size: 96),
                Positioned(
                  right: 2,
                  top: 2,
                  child: InkWell(
                    onTap: () => onChanged([...files]..remove(f)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
          if (files.length < max)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final added = await capture(context, limit: max - files.length);
                if (added.isNotEmpty) onChanged([...files, ...added]);
              },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GV.goldDeep, width: 1.4),
                  color: GV.surface2,
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: GV.gold, size: 32),
              ),
            ),
        ]),
      ),
    ]);
  }
}

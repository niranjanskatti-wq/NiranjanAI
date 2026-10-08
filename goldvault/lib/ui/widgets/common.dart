import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/constants.dart';

/// Rebuilds whenever local data changes.
class DataBuilder<T> extends StatefulWidget {
  const DataBuilder({super.key, required this.load, required this.builder, this.watch});
  final Future<T> Function() load;

  /// Reload when this value changes (e.g. a search query).
  final Object? watch;
  final Widget Function(BuildContext, T) builder;

  @override
  State<DataBuilder<T>> createState() => _DataBuilderState<T>();
}

class _DataBuilderState<T> extends State<DataBuilder<T>> {
  T? _data;
  Object? _error;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    AppServices.I.repo.revision.addListener(_reload);
    _reload();
  }

  @override
  void didUpdateWidget(covariant DataBuilder<T> old) {
    super.didUpdateWidget(old);
    if (old.watch != widget.watch) _reload();
  }

  Future<void> _reload() async {
    final g = ++_gen;
    try {
      final d = await widget.load();
      if (mounted && g == _gen) setState(() => _data = d);
    } catch (e) {
      if (mounted && g == _gen) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    AppServices.I.repo.revision.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _data == null) {
      return Center(child: Text('$_error', style: const TextStyle(color: GV.danger)));
    }
    if (_data == null) {
      return const Center(child: CircularProgressIndicator(color: GV.gold));
    }
    return widget.builder(context, _data as T);
  }
}

class GoldCard extends StatelessWidget {
  const GoldCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(18), this.accent});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: GV.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (accent ?? GV.line).withValues(alpha: accent == null ? 1 : 0.55)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(children: [
        Container(width: 4, height: 22, decoration: BoxDecoration(gradient: GV.goldGradient, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20))),
        ?trailing,
      ]),
    );
  }
}

/// Fades + slides children in, staggered by [index].
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index.clamp(0, 8) * 60)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// Sensitive value hidden until tapped; hides itself again after 15 seconds.
class RevealText extends StatefulWidget {
  const RevealText(this.value, {super.key, this.style, this.placeholder = '••••••'});
  final String? value;
  final TextStyle? style;
  final String placeholder;
  @override
  State<RevealText> createState() => _RevealTextState();
}

class _RevealTextState extends State<RevealText> {
  bool _shown = false;
  Timer? _t;

  void _toggle() {
    setState(() => _shown = !_shown);
    _t?.cancel();
    if (_shown) _t = Timer(const Duration(seconds: 15), () => mounted ? setState(() => _shown = false) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    if (v == null || v.isEmpty || v == '—') return Text('—', style: widget.style);
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(_shown ? v : widget.placeholder,
                key: ValueKey(_shown), style: widget.style),
          ),
          const SizedBox(width: 8),
          Icon(_shown ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: GV.gold),
          if (!_shown) ...[
            const SizedBox(width: 4),
            Text(context.t('common.tapReveal'), style: const TextStyle(fontSize: 12, color: GV.muted)),
          ],
        ]),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.icon, this.color = GV.gold, this.sensitive = false, this.onTap});
  final VoidCallback? onTap;
  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final bool sensitive;
  @override
  Widget build(BuildContext context) {
    final vs = TextStyle(fontFamily: GV.display, fontSize: 24, fontWeight: FontWeight.w700, color: color);
    return GoldCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) Icon(icon, color: color, size: 22),
          if (icon != null) const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: GV.muted, fontSize: 14.5))),
        ]),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: sensitive ? RevealText(value, style: vs) : Text(value, style: vs),
        ),
      ]),
    );
  }
}

Color statusColor(String s) => switch (s) {
      Opt.inLocker => GV.gold,
      Opt.atHome => GV.ok,
      Opt.worn => const Color(0xFF4FC3F7),
      Opt.repair => const Color(0xFFFFB74D),
      Opt.lent => const Color(0xFFBA68C8),
      Opt.pledged => GV.danger,
      _ => GV.muted,
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(context.s.status(status), style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 12});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: GV.goldDeep),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: GV.muted, fontSize: 16.5)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}

/// Decrypts and shows a stored photo.
class VaultImage extends StatelessWidget {
  const VaultImage(this.file, {super.key, this.fit = BoxFit.cover, this.size});
  final String? file;
  final BoxFit fit;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: GV.surface2,
      child: const Icon(Icons.diamond_outlined, color: GV.goldDeep),
    );
    if (file == null) return placeholder;
    return FutureBuilder<Uint8List?>(
      future: AppServices.I.photos.load(file!),
      builder: (_, s) => s.data == null
          ? placeholder
          : Image.memory(s.data!, fit: fit, width: size, height: size, gaplessPlayback: true, cacheWidth: size == null ? null : (size! * 3).round()),
    );
  }
}

class PhotoThumb extends StatelessWidget {
  const PhotoThumb(this.file, {super.key, this.size = 64});
  final String? file;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: size, height: size, child: VaultImage(file, size: size)),
      );
}

Future<bool> confirm(BuildContext context, String title, String body, {String? ok, bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.t('common.cancel'))),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: GV.danger) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok ?? context.t('common.ok')),
        ),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<String?> promptText(BuildContext context, String title,
    {String? initial, String? label, TextInputType? keyboard, bool obscure = false}) async {
  final c = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(d, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(context.t('common.cancel'))),
        FilledButton(onPressed: () => Navigator.pop(d, c.text), child: Text(context.t('common.save'))),
      ],
    ),
  );
  return (r == null || r.trim().isEmpty) ? null : r.trim();
}

/// Big gold primary action used on home and inventory screens.
class AddOrnamentFab extends StatelessWidget {
  const AddOrnamentFab({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: GV.gold.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: onPressed,
          icon: const Icon(Icons.add_circle_outline, size: 28),
          label: Text(context.t('item.add')),
        ),
      );
}

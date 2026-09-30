import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

enum GlowStyle {
  pulse('Pulse', 'Fades bright and soft'),
  blink('Blink', 'Switches on and off'),
  steady('Steady', 'Always on, no flashing'),
  off('Off', 'No border');

  const GlowStyle(this.label, this.help);
  final String label, help;
}

enum GlowSpeed {
  fast('Fast', 400),
  medium('Medium', 900),
  slow('Slow', 1800);

  const GlowSpeed(this.label, this.ms);
  final String label;
  final int ms;
}

enum GlowWidth {
  thin('Thin', 2),
  mid('Medium', 3),
  thick('Thick', 5);

  const GlowWidth(this.label, this.dp);
  final String label;
  final double dp;
}

/// How the Today widget's border shines while someone is still to be wished.
class WidgetGlow {
  const WidgetGlow({
    this.color = const Color(0xFFE7B75A),
    this.style = GlowStyle.pulse,
    this.speed = GlowSpeed.medium,
    this.width = GlowWidth.mid,
  });

  final Color color;
  final GlowStyle style;
  final GlowSpeed speed;
  final GlowWidth width;

  static const colors = <String, Color>{
    'Gold': Color(0xFFE7B75A),
    'Red': Color(0xFFFF4B3E),
    'Orange': Color(0xFFFF9A2E),
    'Pink': Color(0xFFFF5FA2),
    'Purple': Color(0xFFB07CFF),
    'Blue': Color(0xFF4DA3FF),
    'Green': Color(0xFF4CD483),
    'White': Color(0xFFFFFFFF),
  };

  /// Ready-made choices, from most to least urgent.
  static const presets = <(String, String, WidgetGlow)>[
    ('Very urgent', 'Fast red blink, thick border',
        WidgetGlow(color: Color(0xFFFF4B3E), style: GlowStyle.blink, speed: GlowSpeed.fast, width: GlowWidth.thick)),
    ('High priority', 'Quick orange pulse',
        WidgetGlow(color: Color(0xFFFF9A2E), style: GlowStyle.pulse, speed: GlowSpeed.fast, width: GlowWidth.thick)),
    ('Normal', 'Gold pulse (default)', WidgetGlow()),
    ('Low priority', 'Slow, soft blue pulse',
        WidgetGlow(color: Color(0xFF4DA3FF), style: GlowStyle.pulse, speed: GlowSpeed.slow, width: GlowWidth.thin)),
    ('Calm', 'Steady gold border, no flashing', WidgetGlow(style: GlowStyle.steady, width: GlowWidth.thin)),
  ];

  String get hex => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String toJson() => jsonEncode({'c': hex, 's': style.name, 'v': speed.ms, 'w': width.name});

  static WidgetGlow parse(String? json) {
    if (json == null || json.isEmpty) return const WidgetGlow();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final hex = (m['c'] as String? ?? '#E7B75A').replaceFirst('#', '');
      return WidgetGlow(
        color: Color(0xFF000000 | int.parse(hex, radix: 16)),
        style: GlowStyle.values.asNameMap()[m['s']] ?? GlowStyle.pulse,
        speed: GlowSpeed.values.firstWhere((s) => s.ms == m['v'], orElse: () => GlowSpeed.medium),
        width: GlowWidth.values.asNameMap()[m['w']] ?? GlowWidth.mid,
      );
    } catch (_) {
      return const WidgetGlow();
    }
  }

  WidgetGlow copyWith({Color? color, GlowStyle? style, GlowSpeed? speed, GlowWidth? width}) => WidgetGlow(
        color: color ?? this.color,
        style: style ?? this.style,
        speed: speed ?? this.speed,
        width: width ?? this.width,
      );

  bool same(WidgetGlow o) => o.toJson() == toJson();

  String get summary => style == GlowStyle.off
      ? 'Off'
      : [
          presets.where((p) => p.$3.same(this)).firstOrNull?.$1 ??
              colors.entries.where((e) => e.value.toARGB32() == color.toARGB32()).firstOrNull?.key ??
              'Custom',
          style.label.toLowerCase(),
          if (style != GlowStyle.steady) speed.label.toLowerCase(),
        ].join(' · ');
}

final widgetGlowProvider = StreamProvider<WidgetGlow>(
    (ref) => ref.watch(databaseProvider).watchSetting('widgetGlow').map(WidgetGlow.parse));

/// Settings › Today widget flash.
class WidgetGlowScreen extends ConsumerWidget {
  const WidgetGlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(widgetGlowProvider).value ?? const WidgetGlow();
    void save(WidgetGlow v) => ref.read(databaseProvider).setSetting('widgetGlow', v.toJson());

    Widget chips<T>(List<T> values, T selected, String Function(T) label, void Function(T) pick) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (_) => pick(v)),
          ],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Today widget flash')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('The border shines while someone celebrating today is still to be wished, '
              'and stops once you tap ✓ Done for everyone.',
              style: context.text.bodyMedium?.copyWith(color: context.c.muted)),
          const SizedBox(height: 16),
          GlowPreview(glow: g),
          const SizedBox(height: 20),
          const SectionLabel('Ready-made'),
          for (final (name, help, p) in WidgetGlow.presets)
            _Choice(name: name, help: help, color: p.color, selected: p.same(g), onTap: () => save(p)),
          _Choice(
            name: 'Off',
            help: 'No border, just the list',
            selected: g.style == GlowStyle.off,
            onTap: () => save(g.copyWith(style: GlowStyle.off)),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Or make your own'),
          const SizedBox(height: 8),
          Text('Colour', style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in WidgetGlow.colors.entries)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => save(g.copyWith(color: e.value, style: g.style == GlowStyle.off ? GlowStyle.pulse : null)),
                child: Tooltip(
                  message: e.key,
                  child: _Dot(color: e.value, size: 40, selected: e.value.toARGB32() == g.color.toARGB32()),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Text('Style', style: context.text.titleSmall),
          const SizedBox(height: 8),
          chips(GlowStyle.values, g.style, (s) => s.label, (s) => save(g.copyWith(style: s))),
          const SizedBox(height: 4),
          Text(g.style.help, style: context.text.bodySmall),
          if (g.style == GlowStyle.pulse || g.style == GlowStyle.blink) ...[
            const SizedBox(height: 16),
            Text('Speed', style: context.text.titleSmall),
            const SizedBox(height: 8),
            chips(GlowSpeed.values, g.speed, (s) => s.label, (s) => save(g.copyWith(speed: s))),
          ],
          if (g.style != GlowStyle.off) ...[
            const SizedBox(height: 16),
            Text('Border', style: context.text.titleSmall),
            const SizedBox(height: 8),
            chips(GlowWidth.values, g.width, (s) => s.label, (s) => save(g.copyWith(width: s))),
          ],
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.name, required this.help, this.color, required this.selected, required this.onTap});
  final String name, help;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: color == null ? const Icon(Icons.block_rounded) : _Dot(color: color!),
        title: Text(name),
        subtitle: Text(help),
        trailing: selected ? Icon(Icons.check_circle_rounded, color: context.c.gold) : null,
        onTap: onTap,
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 24, this.selected = false});
  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? context.c.text : Colors.transparent, width: 3),
        ),
        child: selected ? Icon(Icons.check_rounded, size: size * 0.55, color: Colors.black87) : null,
      );
}

/// A small copy of the Today widget showing the chosen border.
class GlowPreview extends StatefulWidget {
  const GlowPreview({super.key, required this.glow});
  final WidgetGlow glow;

  @override
  State<GlowPreview> createState() => _GlowPreviewState();
}

class _GlowPreviewState extends State<GlowPreview> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(GlowPreview old) {
    super.didUpdateWidget(old);
    if (!old.glow.same(widget.glow)) _restart();
  }

  void _restart() {
    _anim.duration = Duration(milliseconds: widget.glow.speed.ms * 2);
    final moving = widget.glow.style == GlowStyle.pulse || widget.glow.style == GlowStyle.blink;
    if (moving) {
      _anim.repeat();
    } else {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double _strength(double t) => switch (widget.glow.style) {
        GlowStyle.pulse => 0.2 + 0.8 * (1 - (2 * t - 1).abs()),
        GlowStyle.blink => t < 0.5 ? 1 : 0,
        GlowStyle.steady => 1,
        GlowStyle.off => 0,
      };

  @override
  Widget build(BuildContext context) {
    final g = widget.glow;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final a = _strength(_anim.value);
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1C1A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: a == 0 ? const Color(0x55D6B26E) : g.color.withValues(alpha: a),
              width: a == 0 ? 1 : g.width.dp,
            ),
          ),
          child: child,
        );
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('SMRITI · TODAY',
                style: TextStyle(
                    color: Color(0xFFD6B26E), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          Text('1 to wish', style: TextStyle(color: g.color, fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Shanta',
              style: TextStyle(
                  color: Color(0xFFF3ECDD), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          const SizedBox(width: 8),
          const Expanded(child: Text('Birthday', style: TextStyle(color: Color(0xFFCFC6B6), fontSize: 16))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFD6B26E), borderRadius: BorderRadius.circular(99)),
            child: const Text('✓ Done',
                style: TextStyle(color: Color(0xFF1E1C1A), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }
}

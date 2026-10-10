import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

enum GlowStyle {
  pulse('Pulse', 'Fades bright and soft'),
  blink('Blink', 'Switches on and off'),
  steady('Steady', 'Always on, no flashing'),
  fire('🔥 Fire', 'Flames lick up all round the widget', moving: true),
  rays('✴️ Light rays', 'Rays of light spin slowly behind the names', moving: true),
  chase('☄️ Comet chase', 'Two bright comets race round the edge', moving: true),
  rainbow('🌈 Rainbow', 'A rainbow flows round the border', moving: true),
  sparkle('✨ Twinkle', 'Stars twinkle all along the edge', moving: true),
  heartbeat('💓 Heartbeat', 'Lub-dub: the border and a little heart beat', moving: true),
  lightning('⚡ Lightning', 'Electric sparks crackle along the edge', moving: true),
  diya('🪔 Diyas', 'A row of flickering diya lamps', moving: true),
  confetti('🎊 Confetti', 'Coloured confetti falls gently', moving: true),
  balloons('🎈 Balloons', 'Balloons float up at both ends', moving: true),
  fireworks('🎆 Fireworks', 'Bursts pop in the corners', moving: true),
  marquee('💡 Marquee lights', 'Theatre bulbs chase round the edge', moving: true),
  aurora('🌌 Aurora', 'Northern-lights colours flow round', moving: true),
  mandala('🏵️ Rangoli', 'Rangoli flowers slowly turn at both ends', moving: true),
  muzzle('💥 Muzzle flash', 'Bang! A flash, a bullet along the bottom, sparks', moving: true),
  tracer('🔫 Tracer fire', 'Glowing rounds race along the top and bottom', moving: true),
  bullseye('🎯 Bullseye', 'A shot hits the target: ripples and sparks', moving: true),
  ricochet('🪃 Ricochet', 'A bullet bounces round, sparking off the walls', moving: true),
  glass('🪟 Shattered glass', 'Bullet holes crack the glass, then it clears', moving: true),
  laser('🔴 Laser blaster', 'Pew-pew laser bolts and a hunting sight dot', moving: true),
  off('Off', 'No border');

  const GlowStyle(this.label, this.help, {this.moving = false});
  final String label, help;

  /// Drawn as moving pictures on the widget (not just a flashing border).
  final bool moving;
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
    this.natural = false,
  });

  final Color color;

  /// Each effect's own colours (fire orange, red rays, rainbow balloons…).
  final bool natural;
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
    (
      'Very urgent',
      'Fast red blink, thick border',
      WidgetGlow(color: Color(0xFFFF4B3E), style: GlowStyle.blink, speed: GlowSpeed.fast, width: GlowWidth.thick),
    ),
    (
      'High priority',
      'Quick orange pulse',
      WidgetGlow(color: Color(0xFFFF9A2E), style: GlowStyle.pulse, speed: GlowSpeed.fast, width: GlowWidth.thick),
    ),
    ('Normal', 'Gold pulse (default)', WidgetGlow()),
    (
      'Low priority',
      'Slow, soft blue pulse',
      WidgetGlow(color: Color(0xFF4DA3FF), style: GlowStyle.pulse, speed: GlowSpeed.slow, width: GlowWidth.thin),
    ),
    ('Calm', 'Steady gold border, no flashing', WidgetGlow(style: GlowStyle.steady, width: GlowWidth.thin)),
    (
      '🔥 On fire',
      'Flames all round: impossible to miss',
      WidgetGlow(style: GlowStyle.fire, speed: GlowSpeed.fast, width: GlowWidth.thick, natural: true),
    ),
    ('✴️ Spotlight', 'Red light rays spinning behind the names', WidgetGlow(style: GlowStyle.rays, natural: true)),
    ('🎈 Birthday party', 'Balloons and confetti feel', WidgetGlow(style: GlowStyle.balloons, natural: true)),
    ('🪔 Festive', 'Flickering diya lamps', WidgetGlow(style: GlowStyle.diya, natural: true)),
    ('🎆 Celebration', 'Fireworks popping', WidgetGlow(style: GlowStyle.fireworks, natural: true)),
    (
      '🎯 Shooting range',
      'Fast muzzle flash and a bullet: bang on time',
      WidgetGlow(style: GlowStyle.muzzle, speed: GlowSpeed.fast, natural: true),
    ),
  ];

  String get hex => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  String toJson() => jsonEncode({'c': natural ? 'auto' : hex, 's': style.name, 'v': speed.ms, 'w': width.name});

  static WidgetGlow parse(String? json) {
    if (json == null || json.isEmpty) return const WidgetGlow();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final raw = m['c'] as String? ?? '#E7B75A';
      final natural = raw == 'auto';
      final hex = (natural ? '#E7B75A' : raw).replaceFirst('#', '');
      return WidgetGlow(
        natural: natural,
        color: Color(0xFF000000 | int.parse(hex, radix: 16)),
        style: GlowStyle.values.asNameMap()[m['s']] ?? GlowStyle.pulse,
        speed: GlowSpeed.values.firstWhere((s) => s.ms == m['v'], orElse: () => GlowSpeed.medium),
        width: GlowWidth.values.asNameMap()[m['w']] ?? GlowWidth.mid,
      );
    } catch (_) {
      return const WidgetGlow();
    }
  }

  WidgetGlow copyWith({Color? color, GlowStyle? style, GlowSpeed? speed, GlowWidth? width, bool? natural}) =>
      WidgetGlow(
        color: color ?? this.color,
        style: style ?? this.style,
        speed: speed ?? this.speed,
        width: width ?? this.width,
        natural: natural ?? (color == null && this.natural),
      );

  bool same(WidgetGlow o) => o.toJson() == toJson();

  String get summary => style == GlowStyle.off
      ? 'Off'
      : [
          presets.where((p) => p.$3.same(this)).firstOrNull?.$1 ??
              (natural ? 'Natural colours' : null) ??
              colors.entries.where((e) => e.value.toARGB32() == color.toARGB32()).firstOrNull?.key ??
              'Custom',
          style.label.toLowerCase(),
          if (style != GlowStyle.steady) speed.label.toLowerCase(),
        ].join(' · ');
}

enum TextSize {
  xs('Extra small', 0.75),
  s('Small', 0.88),
  m('Medium', 1),
  l('Large', 1.2);

  const TextSize(this.label, this.scale);
  final String label;
  final double scale;
}

/// Text size for each widget, and whether "Next up" shows its first date big.
class WidgetLook {
  const WidgetLook({this.sizes = const {}, this.nextBig = true, this.minStars = 4});

  /// Widget key (next, countdown, list, today) → text size; Medium when missing.
  final Map<String, TextSize> sizes;
  final bool nextBig;

  /// Coming-up widgets show only people with at least this many stars (1 = everyone);
  /// the others appear on their day in the Today widget.
  final int minStars;

  static const widgets = {'today': 'Today', 'next': 'Next up', 'countdown': 'Countdown', 'list': 'Coming up'};

  TextSize size(String key) => sizes[key] ?? TextSize.m;

  WidgetLook withSize(String key, TextSize v) =>
      WidgetLook(sizes: {...sizes, key: v}, nextBig: nextBig, minStars: minStars);

  WidgetLook withNextBig(bool v) => WidgetLook(sizes: sizes, nextBig: v, minStars: minStars);

  WidgetLook withMinStars(int v) => WidgetLook(sizes: sizes, nextBig: nextBig, minStars: v);

  String toJson() =>
      jsonEncode({for (final e in sizes.entries) e.key: e.value.name, 'nextBig': nextBig, 'stars': minStars});

  static WidgetLook parse(String? json) {
    if (json == null || json.isEmpty) return const WidgetLook();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return WidgetLook(
        sizes: {for (final k in widgets.keys) k: ?TextSize.values.asNameMap()[m[k]]},
        nextBig: m['nextBig'] != false,
        minStars: ((m['stars'] as num?)?.toInt() ?? 4).clamp(1, 5),
      );
    } catch (_) {
      return const WidgetLook();
    }
  }
}

final widgetLookProvider = StreamProvider<WidgetLook>(
  (ref) => ref.watch(databaseProvider).watchSetting('widgetLook').map(WidgetLook.parse),
);

final widgetGlowProvider = StreamProvider<WidgetGlow>(
  (ref) => ref.watch(databaseProvider).watchSetting('widgetGlow').map(WidgetGlow.parse),
);

/// Settings › Today widget flash.
class WidgetGlowScreen extends ConsumerWidget {
  const WidgetGlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(widgetGlowProvider).value ?? const WidgetGlow();
    final look = ref.watch(widgetLookProvider).value ?? const WidgetLook();
    void save(WidgetGlow v) => ref.read(databaseProvider).setSetting('widgetGlow', v.toJson());
    void saveLook(WidgetLook v) => ref.read(databaseProvider).setSetting('widgetLook', v.toJson());

    Widget chips<T>(List<T> values, T selected, String Function(T) label, void Function(T) pick) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values) ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (_) => pick(v)),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Widget size & flash')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionLabel('Text size'),
          const SizedBox(height: 4),
          for (final e in WidgetLook.widgets.entries) ...[
            Text(e.value, style: context.text.titleSmall),
            const SizedBox(height: 6),
            chips(TextSize.values, look.size(e.key), (s) => s.label, (s) => saveLook(look.withSize(e.key, s))),
            const SizedBox(height: 12),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Next up: big first date'),
            subtitle: Text(
              look.nextBig
                  ? 'The next date is shown large, with three more below'
                  : 'Small: all dates in a simple list',
            ),
            value: look.nextBig,
            onChanged: (v) => saveLook(look.withNextBig(v)),
          ),
          Text(
            'To make a widget itself bigger or smaller, long-press it on the home screen and drag its edges.',
            style: context.text.bodySmall?.copyWith(color: context.c.muted),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Who shows on the widgets'),
          const SizedBox(height: 4),
          Text(
            'Next up, Countdown and Coming up show only the important people. '
            'Everyone else appears on the Today widget on their day.',
            style: context.text.bodyMedium?.copyWith(color: context.c.muted),
          ),
          const SizedBox(height: 10),
          chips(
            const [5, 4, 3, 1],
            look.minStars,
            (n) => switch (n) { 5 => '★★★★★ only', 1 => 'Everyone', _ => '${'★' * n} and up' },
            (n) => saveLook(look.withMinStars(n)),
          ),
          const SizedBox(height: 6),
          Text(
            'Stars are set on each person (★ = less important, ★★★★★ = most). '
            'Festivals and other dates always show.',
            style: context.text.bodySmall?.copyWith(color: context.c.muted),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Today widget flash'),
          const SizedBox(height: 4),
          Text(
            'The border shines while someone celebrating today is still to be wished, '
            'and stops once you tap ✓ Done for everyone.',
            style: context.text.bodyMedium?.copyWith(color: context.c.muted),
          ),
          const SizedBox(height: 16),
          GlowPreview(glow: g, scale: look.size('today').scale),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => save(g.copyWith(natural: true, style: g.style == GlowStyle.off ? GlowStyle.fire : null)),
                child: Tooltip(
                  message: 'Natural: each effect\'s own colours',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFFFF4B3E),
                          Color(0xFFFF9A2E),
                          Color(0xFFFFD60A),
                          Color(0xFF4CD483),
                          Color(0xFF4DA3FF),
                          Color(0xFFB07CFF),
                          Color(0xFFFF4B3E),
                        ],
                      ),
                      border: Border.all(color: g.natural ? context.c.text : Colors.transparent, width: 3),
                    ),
                    child: g.natural ? const Icon(Icons.check_rounded, size: 22, color: Colors.black87) : null,
                  ),
                ),
              ),
              for (final e in WidgetGlow.colors.entries)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => save(
                    g.copyWith(
                      color: e.value,
                      natural: false,
                      style: g.style == GlowStyle.off ? GlowStyle.pulse : null,
                    ),
                  ),
                  child: Tooltip(
                    message: e.key,
                    child: _Dot(
                      color: e.value,
                      size: 40,
                      selected: !g.natural && e.value.toARGB32() == g.color.toARGB32(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            g.natural
                ? 'Natural: fire is flame-orange, rays red, balloons and confetti in many colours'
                : 'Every effect in this colour',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Moving effects', style: context.text.titleSmall),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: [
              for (final st in GlowStyle.values.where((x) => x.moving))
                _StyleTile(
                  style: st,
                  selected: st == g.style,
                  onTap: () => save(g.copyWith(style: st)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Simple border', style: context.text.titleSmall),
          const SizedBox(height: 8),
          chips(
            GlowStyle.values.where((x) => !x.moving).toList(),
            g.style,
            (s) => s.label,
            (s) => save(g.copyWith(style: s)),
          ),
          const SizedBox(height: 4),
          Text(g.style.help, style: context.text.bodySmall),
          if (g.style == GlowStyle.pulse || g.style == GlowStyle.blink || g.style.moving) ...[
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

class _StyleTile extends StatelessWidget {
  const _StyleTile({required this.style, required this.selected, required this.onTap});
  final GlowStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.c.gold.withValues(alpha: 0.18) : context.c.raised,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: selected ? context.c.gold : context.c.line, width: selected ? 2 : 1),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(style.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
            ),
            if (selected) Icon(Icons.check_circle_rounded, size: 18, color: context.c.goldText),
          ],
        ),
      ),
    ),
  );
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
  const GlowPreview({super.key, required this.glow, this.scale = 1});
  final WidgetGlow glow;
  final double scale;

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
    GlowStyle.off => 0,
    _ => 1,
  };

  @override
  Widget build(BuildContext context) {
    final g = widget.glow;
    final k = widget.scale;
    if (g.style.moving) {
      return _MovingPreview(glow: g, child: _sample(g, k));
    }
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
      child: _sample(g, k),
    );
  }

  Widget _sample(WidgetGlow g, double k) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'SMRITI · TODAY',
              style: TextStyle(
                color: const Color(0xFFD6B26E),
                fontSize: 11 * k,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          Text(
            '1 to wish',
            style: TextStyle(color: g.color, fontSize: 13 * k, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      SizedBox(height: 8 * k),
      Row(
        children: [
          Text(
            'Shanta',
            style: TextStyle(
              color: const Color(0xFFF3ECDD),
              fontSize: 18 * k,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Birthday',
              style: TextStyle(color: const Color(0xFFCFC6B6), fontSize: 14 * k),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * k, vertical: 5 * k),
            decoration: BoxDecoration(color: const Color(0xFFD6B26E), borderRadius: BorderRadius.circular(99)),
            child: Text(
              '✓ Done',
              style: TextStyle(color: const Color(0xFF1E1C1A), fontSize: 14 * k, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ],
  );
}

/// The phone draws the same pictures the widget will show; they flip here like on the home screen.
class _MovingPreview extends StatefulWidget {
  const _MovingPreview({required this.glow, required this.child});
  final WidgetGlow glow;
  final Widget child;

  @override
  State<_MovingPreview> createState() => _MovingPreviewState();
}

class _MovingPreviewState extends State<_MovingPreview> {
  static const _channel = MethodChannel('smriti/window');
  static final _cache = <String, List<Uint8List>>{};
  List<Uint8List> _frames = const [];
  int _i = 0;
  Timer? _timer;

  String get _key => widget.glow.toJson();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_MovingPreview old) {
    super.didUpdateWidget(old);
    if (!old.glow.same(widget.glow)) _load();
  }

  Future<void> _load() async {
    final key = _key;
    var frames = _cache[key];
    if (frames == null) {
      try {
        final g = widget.glow;
        final raw = await _channel.invokeListMethod<Object?>('glowFrames', {
          'style': g.style.name,
          'color': g.natural ? null : g.color.toARGB32(),
          'w': 330,
          'h': 96,
          'width': g.width.name,
        });
        frames = [for (final b in raw ?? const []) b as Uint8List];
      } catch (_) {
        frames = const [];
      }
      _cache[key] = frames;
    }
    if (!mounted || key != _key) return;
    _timer?.cancel();
    setState(() {
      _frames = frames!;
      _i = 0;
    });
    if (frames.length > 1) {
      _timer = Timer.periodic(Duration(milliseconds: (widget.glow.speed.ms ~/ 8).clamp(60, 240)), (_) {
        if (mounted) setState(() => _i = (_i + 1) % _frames.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Container(
      color: const Color(0xFF1E1C1A),
      child: Stack(
        children: [
          if (_frames.isNotEmpty)
            Positioned.fill(child: Image.memory(_frames[_i], fit: BoxFit.fill, gaplessPlayback: true))
          else
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: widget.glow.natural ? const Color(0xFFFF9A2E) : widget.glow.color,
                    width: 2,
                  ),
                ),
              ),
            ),
          Padding(padding: const EdgeInsets.fromLTRB(18, 14, 14, 14), child: widget.child),
        ],
      ),
    ),
  );
}

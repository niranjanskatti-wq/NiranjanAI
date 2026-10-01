import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../widget/home_widget_service.dart';

/// How the moving border looks.
enum FrameStyle {
  neon('Neon frame', 'Double neon lines with moving gaps'),
  dashes('Running dashes', 'Dashes travel around the edge'),
  comet('Comet', 'A bright light chases round'),
  twin('Twin comets', 'Two lights race each other'),
  sweep('Colour sweep', 'Colours flow round the border'),
  pulse('Pulse', 'The whole border breathes'),
  sparkle('Sparkle', 'Twinkling lights on the edge'),
  steady('Steady glow', 'Glows without moving');

  const FrameStyle(this.label, this.help);
  final String label, help;
}

/// Colour sets for the frame (first two are blended along the border).
enum FramePalette {
  neon('Neon', [Color(0xFF3D7BFF), Color(0xFFB14DFF), Color(0xFF2EE6FF)]),
  gold('Gold', [Color(0xFFFFD27A), Color(0xFFE7B75A), Color(0xFFFFF1C9)]),
  fire('Fire', [Color(0xFFFF4B3E), Color(0xFFFF9A2E), Color(0xFFFFE066)]),
  rose('Rose', [Color(0xFFFF5FA2), Color(0xFFFF9EC7), Color(0xFFB14DFF)]),
  emerald('Emerald', [Color(0xFF2EE6A6), Color(0xFF4CD483), Color(0xFFB8FFDA)]),
  ocean('Ocean', [Color(0xFF00C2FF), Color(0xFF3D7BFF), Color(0xFF7CF4FF)]),
  rainbow('Rainbow', [
    Color(0xFFFF4B3E),
    Color(0xFFFF9A2E),
    Color(0xFFFFE066),
    Color(0xFF4CD483),
    Color(0xFF2EB8FF),
    Color(0xFFB14DFF),
  ]),
  white('White', [Color(0xFFFFFFFF), Color(0xFFDDE6FF), Color(0xFFFFFFFF)]);

  const FramePalette(this.label, this.colors);
  final String label;
  final List<Color> colors;
}

enum FrameSpeed {
  slow('Slow', 4200),
  medium('Medium', 2600),
  fast('Fast', 1400);

  const FrameSpeed(this.label, this.ms);
  final String label;
  final int ms;
}

enum FrameWidth {
  thin('Thin', 1.6),
  medium('Medium', 2.6),
  thick('Thick', 4);

  const FrameWidth(this.label, this.px);
  final String label;
  final double px;
}

/// How far ahead a date lights up.
enum FrameWindow {
  today('Today only', 0),
  day('Within 1 day (24 h)', 1),
  three('Within 3 days', 3),
  week('Within a week', 7);

  const FrameWindow(this.label, this.days);
  final String label;
  final int days;
}

/// Settings › Highlight coming dates.
class HighlightPrefs {
  const HighlightPrefs({
    this.on = true,
    this.style = FrameStyle.neon,
    this.palette = FramePalette.neon,
    this.speed = FrameSpeed.medium,
    this.width = FrameWidth.medium,
    this.window = FrameWindow.day,
    this.onTopCard = true,
    this.onRows = true,
    this.stopWhenWished = true,
  });

  final bool on;
  final FrameStyle style;
  final FramePalette palette;
  final FrameSpeed speed;
  final FrameWidth width;
  final FrameWindow window;
  final bool onTopCard, onRows, stopWhenWished;

  HighlightPrefs copyWith({
    bool? on,
    FrameStyle? style,
    FramePalette? palette,
    FrameSpeed? speed,
    FrameWidth? width,
    FrameWindow? window,
    bool? onTopCard,
    bool? onRows,
    bool? stopWhenWished,
  }) => HighlightPrefs(
    on: on ?? this.on,
    style: style ?? this.style,
    palette: palette ?? this.palette,
    speed: speed ?? this.speed,
    width: width ?? this.width,
    window: window ?? this.window,
    onTopCard: onTopCard ?? this.onTopCard,
    onRows: onRows ?? this.onRows,
    stopWhenWished: stopWhenWished ?? this.stopWhenWished,
  );

  String toJson() => jsonEncode({
    'on': on,
    'style': style.name,
    'palette': palette.name,
    'speed': speed.name,
    'width': width.name,
    'window': window.name,
    'top': onTopCard,
    'rows': onRows,
    'stop': stopWhenWished,
  });

  static HighlightPrefs parse(String? json) {
    if (json == null || json.isEmpty) return const HighlightPrefs();
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return HighlightPrefs(
        on: m['on'] != false,
        style: FrameStyle.values.asNameMap()[m['style']] ?? FrameStyle.neon,
        palette: FramePalette.values.asNameMap()[m['palette']] ?? FramePalette.neon,
        speed: FrameSpeed.values.asNameMap()[m['speed']] ?? FrameSpeed.medium,
        width: FrameWidth.values.asNameMap()[m['width']] ?? FrameWidth.medium,
        window: FrameWindow.values.asNameMap()[m['window']] ?? FrameWindow.day,
        onTopCard: m['top'] != false,
        onRows: m['rows'] != false,
        stopWhenWished: m['stop'] != false,
      );
    } catch (_) {
      return const HighlightPrefs();
    }
  }

  /// Whether [u] should light up.
  bool lights(Upcoming u, Set<String> wished) {
    if (!on || u.daysLeft < 0 || u.daysLeft > window.days) return false;
    if (stopWhenWished && wished.contains('${HomeWidgetService.keyOf(u.entry)}|${u.date}')) return false;
    return true;
  }
}

final highlightProvider = StreamProvider<HighlightPrefs>(
  (ref) => ref.watch(databaseProvider).watchSetting('highlight').map(HighlightPrefs.parse),
);

/// Wraps [child] in the moving frame when [item] is coming soon.
class SoonHighlight extends ConsumerWidget {
  const SoonHighlight({super.key, required this.item, required this.child, this.radius = 16, this.topCard = false});

  final Upcoming item;
  final Widget child;
  final double radius;
  final bool topCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(highlightProvider).value ?? const HighlightPrefs();
    final where = topCard ? p.onTopCard : p.onRows;
    if (!where || !p.lights(item, ref.watch(wishedKeysProvider))) return child;
    return GlowFrame(prefs: p, radius: radius, child: child);
  }
}

/// The animated border itself.
class GlowFrame extends StatefulWidget {
  const GlowFrame({super.key, required this.prefs, required this.child, this.radius = 16});

  final HighlightPrefs prefs;
  final Widget child;
  final double radius;

  @override
  State<GlowFrame> createState() => _GlowFrameState();
}

class _GlowFrameState extends State<GlowFrame> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.prefs.speed.ms),
  );

  @override
  void initState() {
    super.initState();
    if (widget.prefs.style != FrameStyle.steady) _anim.repeat();
  }

  @override
  void didUpdateWidget(GlowFrame old) {
    super.didUpdateWidget(old);
    _anim.duration = Duration(milliseconds: widget.prefs.speed.ms);
    if (widget.prefs.style == FrameStyle.steady) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _FramePainter(widget.prefs, widget.radius, still ? null : _anim),
        child: Padding(padding: const EdgeInsets.all(3), child: widget.child),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.p, this.radius, this.anim) : super(repaint: anim);

  final HighlightPrefs p;
  final double radius;
  final Animation<double>? anim;

  double get t => anim?.value ?? 0.25;
  List<Color> get colors => p.palette.colors;

  Paint _stroke(double w, {Shader? shader, Color? color, double blur = 0}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..color = color ?? Colors.white
    ..shader = shader
    ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;

  /// Draws [path] twice: a soft glow underneath and a bright core on top.
  void _glow(Canvas canvas, Path path, Rect rect, double w, {Color? color, double alpha = 1}) {
    final shader = color == null ? _gradient(rect, alpha) : null;
    final c = color?.withValues(alpha: alpha);
    canvas.drawPath(path, _stroke(w * 3.2, shader: shader, color: c, blur: w * 2.4));
    canvas.drawPath(path, _stroke(w, shader: shader, color: c));
  }

  Shader _gradient(Rect rect, double alpha) {
    final cs = [for (final c in colors) c.withValues(alpha: alpha)];
    return SweepGradient(colors: [...cs, cs.first], transform: GradientRotation(2 * math.pi * t)).createShader(rect);
  }

  Path _border(Rect r, double inset) {
    final rr = RRect.fromRectAndRadius(r.deflate(inset), Radius.circular(math.max(0, radius - inset)));
    return Path()..addRRect(rr);
  }

  /// Pieces of [metric] from [from] for [len] (wrapping round the end).
  Path _piece(ui.PathMetric m, double from, double len) {
    final total = m.length;
    final start = (from % total + total) % total;
    final end = start + len;
    final out = m.extractPath(start, math.min(end, total));
    if (end > total) out.addPath(m.extractPath(0, end - total), Offset.zero);
    return out;
  }

  /// [count] dashes evenly round [m] with [gap] between them, shifted by [shift] (0..1 of one step).
  Path _dashes(ui.PathMetric m, int count, double gap, double shift) {
    final out = Path();
    final step = m.length / count;
    final dash = math.max(2.0, step - gap);
    for (var i = 0; i < count; i++) {
      out.addPath(_piece(m, (i + shift) * step, dash), Offset.zero);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = p.width.px;
    final outer = _border(rect, w);
    final m = outer.computeMetrics().first;
    switch (p.style) {
      case FrameStyle.neon:
        // Like a neon sign: an outer and inner line, gaps drifting opposite ways.
        final inner = _border(rect, w + 6).computeMetrics().first;
        _glow(canvas, _dashes(m, 7, 14, 7 * t), rect, w);
        _glow(canvas, _dashes(inner, 9, 10, -9 * t), rect, w * 0.7, color: colors.last, alpha: 0.85);
      case FrameStyle.dashes:
        final n = math.max(8, (m.length / 30).round());
        _glow(canvas, _dashes(m, n, 12, 4 * t), rect, w);
      case FrameStyle.comet:
        canvas.drawPath(outer, _stroke(w * 0.6, color: colors.first.withValues(alpha: 0.25)));
        final head = m.length * t;
        for (var i = 0; i < 8; i++) {
          final seg = _piece(m, head - i * m.length / 40, m.length / 40);
          _glow(canvas, seg, rect, w * (1 - i / 10), color: colors[i % colors.length], alpha: 1 - i / 9);
        }
      case FrameStyle.twin:
        canvas.drawPath(outer, _stroke(w * 0.6, color: colors.first.withValues(alpha: 0.2)));
        for (final (k, base) in [(0, 0.0), (1, 0.5)]) {
          final head = m.length * ((t + base) % 1);
          _glow(canvas, _piece(m, head - m.length / 6, m.length / 6), rect, w, color: colors[k % colors.length]);
        }
      case FrameStyle.sweep:
        _glow(canvas, outer, rect, w);
      case FrameStyle.pulse:
        final a = 0.35 + 0.65 * (0.5 - 0.5 * math.cos(2 * math.pi * t));
        _glow(canvas, outer, rect, w * (0.8 + 0.4 * a), alpha: a);
      case FrameStyle.sparkle:
        canvas.drawPath(outer, _stroke(w * 0.6, color: colors.first.withValues(alpha: 0.3)));
        const n = 14;
        for (var i = 0; i < n; i++) {
          final phase = (t * 2 + i * 0.37) % 1;
          final a = math.sin(phase * math.pi);
          final pos = m.getTangentForOffset(m.length * i / n + 6)!.position;
          final c = colors[i % colors.length].withValues(alpha: a);
          canvas.drawCircle(
            pos,
            w * 2.2 * a + 0.5,
            Paint()
              ..color = c
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 1.5),
          );
          canvas.drawCircle(pos, w * 0.8 * a + 0.3, Paint()..color = Colors.white.withValues(alpha: a));
        }
      case FrameStyle.steady:
        _glow(canvas, outer, rect, w);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.p.toJson() != p.toJson() || old.radius != radius;
}

/// Settings › Highlight coming dates: switch on/off, pick a style with live previews.
class HighlightScreen extends ConsumerWidget {
  const HighlightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(highlightProvider).value ?? const HighlightPrefs();
    final theme = Theme.of(context);
    void save(HighlightPrefs v) => ref.read(databaseProvider).setSetting('highlight', v.toJson());

    Widget chips<T>(List<T> values, T selected, String Function(T) label, void Function(T) pick) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (_) => pick(v)),
          ],
        );

    Widget title(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(t, style: theme.textTheme.titleSmall),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Highlight coming dates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Light up dates that are coming soon'),
            subtitle: const Text('A moving border on Home, so you can\'t miss them'),
            value: p.on,
            onChanged: (v) => save(p.copyWith(on: v)),
          ),
          if (p.on) ...[
            const SizedBox(height: 8),
            GlowFrame(prefs: p, radius: 18, child: const _SampleRow()),
            title('When'),
            chips(FrameWindow.values, p.window, (w) => w.label, (w) => save(p.copyWith(window: w))),
            title('Style (tap one)'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                for (final s in FrameStyle.values)
                  GestureDetector(
                    onTap: () => save(p.copyWith(style: s)),
                    child: GlowFrame(
                      prefs: p.copyWith(style: s),
                      radius: 14,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: s == p.style ? theme.colorScheme.primary.withValues(alpha: 0.18) : const Color(0xFF15151C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(s.label,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(color: Colors.white)),
                          if (s == p.style) const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white70),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(p.style.help, style: theme.textTheme.bodySmall),
            ),
            title('Colours'),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final c in FramePalette.values)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => save(p.copyWith(palette: c)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(colors: [...c.colors, c.colors.first]),
                        border: Border.all(color: c == p.palette ? Colors.white : Colors.transparent, width: 3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(c.label, style: theme.textTheme.labelSmall),
                  ]),
                ),
            ]),
            if (p.style != FrameStyle.steady) ...[
              title('Speed'),
              chips(FrameSpeed.values, p.speed, (s) => s.label, (s) => save(p.copyWith(speed: s))),
            ],
            title('Thickness'),
            chips(FrameWidth.values, p.width, (s) => s.label, (s) => save(p.copyWith(width: s))),
            title('Where'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Big card at the top of Home'),
              value: p.onTopCard,
              onChanged: (v) => save(p.copyWith(onTopCard: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dates in lists (Home, Calendar, profiles)'),
              value: p.onRows,
              onChanged: (v) => save(p.copyWith(onRows: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Stop once wished'),
              subtitle: const Text('The light goes off after you mark them wished'),
              value: p.stopWhenWished,
              onChanged: (v) => save(p.copyWith(stopWhenWished: v)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => save(const HighlightPrefs()),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Back to the original look'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A made-up row to show the frame on.
class _SampleRow extends StatelessWidget {
  const _SampleRow();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF15151C), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const CircleAvatar(radius: 22, child: Text('🎂')),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('‹name›', style: t.titleMedium?.copyWith(color: Colors.white)),
            Text('Birthday · Turning 31', style: t.bodySmall?.copyWith(color: Colors.white70)),
          ]),
        ),
        Text('Tomorrow', style: t.titleSmall?.copyWith(color: Colors.white)),
      ]),
    );
  }
}

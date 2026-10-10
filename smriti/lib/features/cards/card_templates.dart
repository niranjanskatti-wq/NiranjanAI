import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// What the card is for; decides which designs come first.
enum CardKind { birthday, milestone, anniversary, festival, thankYou, general }

/// The words on a card.
class CardData {
  const CardData({
    required this.kind,
    required this.headline,
    this.name = '',
    this.message = '',
    this.footer = '',
    this.years,
    this.festivalId,
  });

  final CardKind kind;
  final String headline, name, message, footer;
  final int? years;
  final String? festivalId;

  CardData copyWith({String? headline, String? name, String? message, String? footer}) => CardData(
    kind: kind,
    headline: headline ?? this.headline,
    name: name ?? this.name,
    message: message ?? this.message,
    footer: footer ?? this.footer,
    years: years,
    festivalId: festivalId,
  );
}

typedef CardPaint = void Function(Canvas canvas, Size size, CardData data);

/// One design: background, colours, drawing and where the words go.
class CardTemplate {
  const CardTemplate({
    required this.id,
    required this.name,
    required this.kinds,
    this.festivals = const {},
    required this.bg,
    required this.ink,
    required this.accent,
    required this.paint,
    this.textTop = 0.26,
    this.textBottom = 0.10,
  });

  final String id, name;
  final Set<CardKind> kinds;
  final Set<String> festivals;
  final List<Color> bg;
  final Color ink, accent;
  final CardPaint paint;

  /// Fractions of the card height kept free for the drawing.
  final double textTop, textBottom;
}

const _all = {...CardKind.values};
const _diwali = {'dhanteras', 'naraka_chaturdashi', 'diwali_lakshmi_puja', 'balipratipada', 'bhai_dooj'};
const _pooja = {
  'ganesh_chaturthi',
  'gowri_habba',
  'varamahalakshmi',
  'ugadi',
  'akshaya_tritiya',
  'ram_navami',
  'hanuman_jayanti',
  'krishna_janmashtami',
  'anant_chaturdashi',
  'nag_panchami',
  'navratri_begins',
  'vijayadashami',
};

/// Designs in the order they're offered for [data]: festival-specific first,
/// then ones made for that kind of day, then the rest.
List<CardTemplate> templatesFor(CardData data) {
  int rank(CardTemplate t) {
    if (data.festivalId != null && t.festivals.contains(data.festivalId)) return 0;
    if (t.kinds.contains(data.kind)) return t.festivals.isEmpty ? 1 : 2;
    return 3;
  }

  final list = [...cardTemplates];
  final order = {for (var i = 0; i < list.length; i++) list[i].id: i};
  list.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : order[a.id]!.compareTo(order[b.id]!);
  });
  return list;
}

CardTemplate templateById(String? id) => cardTemplates.firstWhere((t) => t.id == id, orElse: () => cardTemplates.first);

// ---------------------------------------------------------------------------
// Drawing helpers. Everything is in fractions of the card size so the card
// looks the same as a thumbnail and as a 1080 × 1350 image.

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

void _border(Canvas c, Size s, Color color, double inset, double width) => c.drawRect(
  Rect.fromLTRB(s.width * inset, s.width * inset, s.width * (1 - inset), s.height - s.width * inset),
  _stroke(color, s.width * width),
);

void _flower(Canvas c, Offset o, double r, int petals, Color petal, Color heart, {double turn = 0}) {
  for (var i = 0; i < petals; i++) {
    final a = turn + i * 2 * math.pi / petals;
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    c.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.55), width: r * 0.62, height: r * 1.05), _fill(petal));
    c.restore();
  }
  c.drawCircle(o, r * 0.28, _fill(heart));
}

void _leaf(Canvas c, Offset o, double len, double angle, Color color) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(angle);
  final p = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(len * 0.5, -len * 0.28, len, 0)
    ..quadraticBezierTo(len * 0.5, len * 0.28, 0, 0);
  c.drawPath(p, _fill(color));
  c.restore();
}

void _sparkle(Canvas c, Offset o, double r, Color color) {
  final p = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r);
  c.drawPath(p, _fill(color));
}

void _glow(Canvas c, Offset o, double r, Color color) => c.drawCircle(
  o,
  r,
  Paint()
    ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)),
);

void _text(
  Canvas c,
  String t,
  Offset center,
  double size,
  Color color, {
  String family = serif,
  FontWeight weight = FontWeight.w700,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: t,
      style: TextStyle(fontFamily: family, fontSize: size, color: color, fontWeight: weight, height: 1),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

// ---------------------------------------------------------------------------
// The designs.

void _minimal(Canvas c, Size s, CardData d) {
  const gold = Color(0xFFB08A45);
  _border(c, s, gold, 0.05, 0.003);
  final y = s.height * 0.17, w = s.width;
  c.drawLine(Offset(w * 0.30, y), Offset(w * 0.44, y), _stroke(gold, w * 0.003));
  c.drawLine(Offset(w * 0.56, y), Offset(w * 0.70, y), _stroke(gold, w * 0.003));
  _sparkle(c, Offset(w / 2, y), w * 0.035, gold);
}

void _charcoalGold(Canvas c, Size s, CardData d) {
  const gold = Color(0xFFD6B26E);
  final w = s.width;
  _border(c, s, gold, 0.045, 0.004);
  _border(c, s, gold.withValues(alpha: 0.6), 0.065, 0.0015);
  for (final (x, y, sx, sy) in [
    (0.045, 0.0, 1.0, 1.0),
    (0.955, 0.0, -1.0, 1.0),
    (0.045, 1.0, 1.0, -1.0),
    (0.955, 1.0, -1.0, -1.0),
  ]) {
    final o = Offset(w * x, y == 0 ? w * 0.045 : s.height - w * 0.045);
    c.drawArc(
      Rect.fromCircle(center: o + Offset(sx * w * 0.06, sy * w * 0.06), radius: w * 0.04),
      0,
      2 * math.pi,
      false,
      _stroke(gold, w * 0.003),
    );
  }
  _sparkle(c, Offset(w / 2, s.height * 0.16), w * 0.04, gold);
  _sparkle(c, Offset(w * 0.42, s.height * 0.175), w * 0.015, gold.withValues(alpha: 0.7));
  _sparkle(c, Offset(w * 0.58, s.height * 0.175), w * 0.015, gold.withValues(alpha: 0.7));
}

void _floralCorners(Canvas c, Size s, CardData d) {
  final w = s.width;
  void cluster(Offset o, double turn) {
    _leaf(c, o, w * 0.2, turn + 0.2, const Color(0xFF8FAF7E));
    _leaf(c, o, w * 0.18, turn + 1.3, const Color(0xFFA9C497));
    _flower(c, o, w * 0.1, 5, const Color(0xFFE8A0A8), const Color(0xFFF6D28B));
    _flower(
      c,
      o + Offset(math.cos(turn + 0.75) * w * 0.14, math.sin(turn + 0.75) * w * 0.14),
      w * 0.065,
      5,
      const Color(0xFFF2C09A),
      const Color(0xFFE8A0A8),
      turn: 0.4,
    );
  }

  cluster(Offset(w * 0.06, w * 0.06), 0);
  cluster(Offset(w * 0.94, s.height - w * 0.06), math.pi);
}

void _roseBlush(Canvas c, Size s, CardData d) {
  final r = math.Random(4);
  for (var i = 0; i < 26; i++) {
    final x = r.nextDouble() * s.width, y = r.nextDouble() * s.height;
    if (y > s.height * 0.22 && y < s.height * 0.88 && x > s.width * 0.12 && x < s.width * 0.88) continue;
    c.save();
    c.translate(x, y);
    c.rotate(r.nextDouble() * math.pi);
    final pw = s.width * (0.03 + r.nextDouble() * 0.03);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: pw, height: pw * 1.5),
      _fill(Color.lerp(const Color(0xFFE38A9A), const Color(0xFFC2566E), r.nextDouble())!.withValues(alpha: 0.75)),
    );
    c.restore();
  }
  _flower(c, Offset(s.width / 2, s.height * 0.13), s.width * 0.07, 6, const Color(0xFFC2566E), const Color(0xFFF3C6A0));
}

void _rangoli(Canvas c, Size s, CardData d) {
  final o = Offset(s.width / 2, s.height * 0.17), w = s.width;
  _glow(c, o, w * 0.28, const Color(0x40F4B942));
  const rings = [
    (0.2, 16, Color(0xFFF08A24)),
    (0.155, 12, Color(0xFFE0457B)),
    (0.11, 10, Color(0xFFF4C542)),
    (0.065, 8, Color(0xFFFFFFFF)),
  ];
  for (final (r, n, col) in rings) {
    _flower(c, o, w * r, n, col, col, turn: r * 7);
  }
  c.drawCircle(o, w * 0.025, _fill(const Color(0xFF2E7D5B)));
  for (var i = 0; i < 24; i++) {
    final a = i * math.pi / 12;
    c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * w * 0.235, w * 0.007, _fill(const Color(0xFFFFF3E0)));
  }
  _border(c, s, const Color(0xFFF4B942), 0.035, 0.003);
}

void _toran(Canvas c, Size s, CardData d) {
  final w = s.width;
  final string = Path()
    ..moveTo(0, w * 0.04)
    ..quadraticBezierTo(w / 2, w * 0.14, w, w * 0.04);
  c.drawPath(string, _stroke(const Color(0xFF8A5A2B), w * 0.004));
  for (var i = 0; i <= 12; i++) {
    final t = i / 12;
    final x = w * t;
    final y = w * 0.04 + 4 * t * (1 - t) * w * 0.05;
    if (i.isOdd) {
      _leaf(c, Offset(x, y), w * 0.13, math.pi / 2 - 0.1, const Color(0xFF4F7A3A));
    } else {
      for (var k = 0; k < 3; k++) {
        _flower(
          c,
          Offset(x, y + k * w * 0.05),
          w * 0.03,
          10,
          k.isEven ? const Color(0xFFF28C28) : const Color(0xFFF6B93B),
          const Color(0xFFB8551A),
        );
      }
    }
  }
  // Small kalash-like diyas at the bottom corners.
  for (final x in [0.1, 0.9]) {
    final o = Offset(w * x, s.height - w * 0.08);
    c.drawArc(Rect.fromCenter(center: o, width: w * 0.1, height: w * 0.06), 0, math.pi, true, _fill(const Color(0xFFC8641E)));
    _glow(c, o - Offset(0, w * 0.03), w * 0.05, const Color(0x99FFC857));
  }
}

void _templeArch(Canvas c, Size s, CardData d) {
  const gold = Color(0xFFE8C07A);
  final w = s.width, h = s.height;
  Path arch(double inset) => Path()
    ..moveTo(w * inset, h - w * inset)
    ..lineTo(w * inset, h * 0.3)
    ..quadraticBezierTo(w * inset, h * 0.12 + w * inset, w / 2, w * inset + h * 0.02)
    ..quadraticBezierTo(w * (1 - inset), h * 0.12 + w * inset, w * (1 - inset), h * 0.3)
    ..lineTo(w * (1 - inset), h - w * inset)
    ..close();
  c.drawPath(arch(0.06), _stroke(gold, w * 0.005));
  c.drawPath(arch(0.085), _stroke(gold.withValues(alpha: 0.5), w * 0.002));
  for (final x in [0.25, 0.5, 0.75]) {
    final top = Offset(w * x, x == 0.5 ? h * 0.08 : h * 0.13);
    c.drawLine(top, top + Offset(0, w * 0.06), _stroke(gold, w * 0.003));
    c.drawArc(
      Rect.fromCenter(center: top + Offset(0, w * 0.085), width: w * 0.05, height: w * 0.05),
      math.pi,
      math.pi,
      true,
      _fill(gold),
    );
  }
}

void _diyas(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final r = math.Random(8);
  for (var i = 0; i < 40; i++) {
    c.drawCircle(
      Offset(r.nextDouble() * w, r.nextDouble() * h * 0.6),
      w * 0.003 * (1 + r.nextDouble()),
      _fill(const Color(0xFFFFE1A1).withValues(alpha: 0.3 + r.nextDouble() * 0.5)),
    );
  }
  for (final (x, scale) in [(0.25, 0.8), (0.5, 1.0), (0.75, 0.8)]) {
    final base = Offset(w * x, h * 0.86);
    final bw = w * 0.2 * scale;
    _glow(c, base - Offset(0, bw * 0.45), bw * 1.1, const Color(0x88FFB347));
    final bowl = Path()
      ..moveTo(base.dx - bw / 2, base.dy - bw * 0.1)
      ..quadraticBezierTo(base.dx, base.dy + bw * 0.45, base.dx + bw / 2, base.dy - bw * 0.1)
      ..quadraticBezierTo(base.dx + bw * 0.62, base.dy - bw * 0.2, base.dx + bw * 0.35, base.dy - bw * 0.12)
      ..close();
    c.drawPath(bowl, _fill(const Color(0xFFB5541C)));
    c.drawOval(Rect.fromCenter(center: base - Offset(0, bw * 0.1), width: bw, height: bw * 0.14), _fill(const Color(0xFFE07B2E)));
    final f = base - Offset(bw * 0.05, bw * 0.18);
    final flame = Path()
      ..moveTo(f.dx, f.dy - bw * 0.42)
      ..quadraticBezierTo(f.dx + bw * 0.14, f.dy - bw * 0.1, f.dx, f.dy)
      ..quadraticBezierTo(f.dx - bw * 0.14, f.dy - bw * 0.1, f.dx, f.dy - bw * 0.42);
    c.drawPath(flame, _fill(const Color(0xFFFFD166)));
    c.drawOval(Rect.fromCenter(center: f - Offset(0, bw * 0.1), width: bw * 0.06, height: bw * 0.14), _fill(Colors.white));
  }
}

void _fireworks(Canvas c, Size s, CardData d) {
  final w = s.width;
  final r = math.Random(21);
  const colors = [Color(0xFFF7C66B), Color(0xFFF06292), Color(0xFF4DD0E1), Color(0xFFB39DDB), Color(0xFFFFFFFF)];
  for (final (x, y, size) in [(0.22, 0.14, 0.15), (0.72, 0.1, 0.18), (0.5, 0.25, 0.1), (0.1, 0.9, 0.09), (0.88, 0.86, 0.12)]) {
    final o = Offset(w * x, s.height * y);
    final col = colors[r.nextInt(colors.length)];
    final n = 18 + r.nextInt(8);
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final dir = Offset(math.cos(a), math.sin(a));
      c.drawLine(o + dir * w * size * 0.3, o + dir * w * size, _stroke(col.withValues(alpha: 0.85), w * 0.004));
      c.drawCircle(o + dir * w * size * 1.1, w * 0.005, _fill(col));
    }
    _glow(c, o, w * size * 0.5, col.withValues(alpha: 0.35));
  }
}

void _holi(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  const colors = [
    Color(0xFFEC407A),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];
  final r = math.Random(3);
  for (var i = 0; i < 14; i++) {
    final edge = i % 4;
    final t = r.nextDouble();
    final o = switch (edge) {
      0 => Offset(w * t, h * 0.02),
      1 => Offset(w * 0.98, h * t),
      2 => Offset(w * t, h * 0.98),
      _ => Offset(w * 0.02, h * t),
    };
    final col = colors[i % colors.length];
    c.drawCircle(
      o,
      w * (0.12 + r.nextDouble() * 0.1),
      Paint()
        ..color = col.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );
    for (var k = 0; k < 8; k++) {
      c.drawCircle(
        o + Offset((r.nextDouble() - 0.5) * w * 0.4, (r.nextDouble() - 0.5) * w * 0.4),
        w * 0.006 * (1 + r.nextDouble() * 2),
        _fill(col.withValues(alpha: 0.8)),
      );
    }
  }
}

void _kites(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  for (final (x, y, size, col, tilt) in [
    (0.2, 0.12, 0.13, const Color(0xFFE0612C), -0.3),
    (0.78, 0.09, 0.16, const Color(0xFF7B3FA0), 0.25),
    (0.55, 0.2, 0.09, const Color(0xFF2A9D8F), 0.1),
  ]) {
    final o = Offset(w * x, h * y), k = w * size;
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(tilt);
    final p = Path()
      ..moveTo(0, -k * 0.6)
      ..lineTo(k * 0.45, 0)
      ..lineTo(0, k * 0.6)
      ..lineTo(-k * 0.45, 0)
      ..close();
    c.drawPath(p, _fill(col));
    c.drawLine(Offset(0, -k * 0.6), Offset(0, k * 0.6), _stroke(Colors.white.withValues(alpha: 0.7), w * 0.002));
    c.drawLine(Offset(-k * 0.45, 0), Offset(k * 0.45, 0), _stroke(Colors.white.withValues(alpha: 0.7), w * 0.002));
    c.drawPath(
      Path()
        ..moveTo(0, k * 0.6)
        ..lineTo(-k * 0.12, k * 0.78)
        ..lineTo(k * 0.12, k * 0.78)
        ..close(),
      _fill(col),
    );
    c.restore();
    final tail = Path()
      ..moveTo(o.dx, o.dy + k * 0.6)
      ..cubicTo(o.dx - w * 0.2, h * 0.5, o.dx + w * 0.2, h * 0.75, w * 0.5 + (x - 0.5) * w * 0.3, h * 1.02);
    c.drawPath(tail, _stroke(const Color(0x661F3A5F), w * 0.0025));
  }
  // Sesame-jaggery sweets at the bottom.
  for (var i = 0; i < 5; i++) {
    c.drawCircle(Offset(w * (0.36 + i * 0.07), h * 0.94), w * 0.028, _fill(const Color(0xFFD9A441)));
  }
}

void _lotus(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final o = Offset(w / 2, h * 0.86);
  _glow(c, o - Offset(0, w * 0.08), w * 0.35, const Color(0x55F8BBD0));
  for (final (angle, len, col) in [
    (-1.1, 0.2, const Color(0xFFF3A6C4)),
    (1.1, 0.2, const Color(0xFFF3A6C4)),
    (-0.6, 0.24, const Color(0xFFE77FA8)),
    (0.6, 0.24, const Color(0xFFE77FA8)),
    (0.0, 0.27, const Color(0xFFD8588D)),
  ]) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    final l = w * len;
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(l * 0.4, -l * 0.5, 0, -l)
      ..quadraticBezierTo(-l * 0.4, -l * 0.5, 0, 0);
    c.drawPath(p, _fill(col));
    c.restore();
  }
  for (var i = 0; i < 3; i++) {
    final y = h * 0.9 + i * w * 0.025;
    c.drawLine(Offset(w * (0.2 + i * 0.05), y), Offset(w * (0.8 - i * 0.05), y), _stroke(const Color(0x668E6A9B), w * 0.003));
  }
  _sparkle(c, Offset(w / 2, h * 0.06), w * 0.03, const Color(0xFFB8467C));
}

void _rakhi(Canvas c, Size s, CardData d) {
  final w = s.width, y = s.height * 0.18;
  for (final (dy, col) in [(-0.006, const Color(0xFFC0392B)), (0.0, const Color(0xFFE6B450)), (0.006, const Color(0xFFC0392B))]) {
    final p = Path()..moveTo(0, y + w * dy);
    for (var x = 0.0; x <= 1.0; x += 0.05) {
      p.lineTo(w * x, y + w * dy + math.sin(x * math.pi * 6) * w * 0.006);
    }
    c.drawPath(p, _stroke(col, w * 0.006));
  }
  final o = Offset(w / 2, y);
  _flower(c, o, w * 0.2, 12, const Color(0xFFE6B450), const Color(0xFFE6B450));
  _flower(c, o, w * 0.14, 10, const Color(0xFFC0392B), const Color(0xFFC0392B), turn: 0.3);
  _flower(c, o, w * 0.08, 8, const Color(0xFFF7E1A0), const Color(0xFF1E88E5));
  for (final x in [0.12, 0.88]) {
    c.drawCircle(Offset(w * x, y), w * 0.018, _fill(const Color(0xFFE6B450)));
  }
}

void _balloons(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  for (final (x, y, col) in [
    (0.12, 0.1, const Color(0xFFE05A47)),
    (0.24, 0.05, const Color(0xFF2BB3A3)),
    (0.2, 0.18, const Color(0xFFF2B33D)),
    (0.8, 0.07, const Color(0xFF9C7BD6)),
    (0.9, 0.16, const Color(0xFFE05A47)),
    (0.72, 0.17, const Color(0xFF2BB3A3)),
  ]) {
    final o = Offset(w * x, h * y);
    final bw = w * 0.13;
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + bw * 1.2)
        ..cubicTo(o.dx - bw * 0.3, o.dy + bw * 2, o.dx + bw * 0.3, o.dy + bw * 2.6, o.dx, o.dy + bw * 3.4),
      _stroke(const Color(0x8823324A), w * 0.002),
    );
    c.drawOval(Rect.fromCenter(center: o + Offset(0, bw * 0.55), width: bw, height: bw * 1.25), _fill(col));
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + bw * 1.15)
        ..lineTo(o.dx - bw * 0.08, o.dy + bw * 1.28)
        ..lineTo(o.dx + bw * 0.08, o.dy + bw * 1.28)
        ..close(),
      _fill(col),
    );
    c.drawOval(
      Rect.fromCenter(center: o + Offset(-bw * 0.2, bw * 0.3), width: bw * 0.18, height: bw * 0.3),
      _fill(Colors.white.withValues(alpha: 0.45)),
    );
  }
}

void _confetti(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  const colors = [Color(0xFFD14B7C), Color(0xFFF2B33D), Color(0xFF2BB3A3), Color(0xFF5B7BE0), Color(0xFFE8703A)];
  final r = math.Random(11);
  for (var i = 0; i < 90; i++) {
    final x = r.nextDouble() * w, y = r.nextDouble() * h;
    final inside = x > w * 0.1 && x < w * 0.9 && y > h * 0.2 && y < h * 0.9;
    if (inside && r.nextDouble() > 0.12) continue;
    c.save();
    c.translate(x, y);
    c.rotate(r.nextDouble() * math.pi);
    final col = colors[r.nextInt(colors.length)];
    if (i.isEven) {
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: w * 0.02, height: w * 0.01), _fill(col));
    } else {
      c.drawCircle(Offset.zero, w * 0.007, _fill(col));
    }
    c.restore();
  }
}

void _cake(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final base = h * 0.95;
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.24, base - w * 0.2, w * 0.76, base), Radius.circular(w * 0.03)),
    _fill(const Color(0xFFD6477A)),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.32, base - w * 0.36, w * 0.68, base - w * 0.2), Radius.circular(w * 0.03)),
    _fill(const Color(0xFFF7A8C4)),
  );
  final drip = Path()..moveTo(w * 0.24, base - w * 0.2);
  for (var i = 0; i < 8; i++) {
    final x0 = w * (0.24 + i * 0.065);
    drip.quadraticBezierTo(x0 + w * 0.0325, base - w * (i.isEven ? 0.13 : 0.16), x0 + w * 0.065, base - w * 0.2);
  }
  drip.close();
  c.drawPath(drip, _fill(const Color(0xFFFFF1F5)));
  c.drawRect(Rect.fromLTRB(w * 0.18, base, w * 0.82, base + w * 0.015), _fill(const Color(0xFFB08A45)));
  for (var i = 0; i < 5; i++) {
    final x = w * (0.38 + i * 0.06);
    c.drawRect(
      Rect.fromLTWH(x - w * 0.007, base - w * 0.44, w * 0.014, w * 0.08),
      _fill(i.isEven ? const Color(0xFF5B7BE0) : const Color(0xFFF2B33D)),
    );
    _glow(c, Offset(x, base - w * 0.46), w * 0.03, const Color(0x99FFC857));
    c.drawOval(
      Rect.fromCenter(center: Offset(x, base - w * 0.46), width: w * 0.014, height: w * 0.026),
      _fill(const Color(0xFFFFB300)),
    );
  }
  _confettiTop(c, s);
}

void _confettiTop(Canvas c, Size s) {
  final r = math.Random(5);
  for (var i = 0; i < 16; i++) {
    _sparkle(
      c,
      Offset(r.nextDouble() * s.width, r.nextDouble() * s.height * 0.1 + s.width * 0.04),
      s.width * 0.012,
      const Color(0xFFD6477A).withValues(alpha: 0.5),
    );
  }
}

void _rings(Canvas c, Size s, CardData d) {
  final w = s.width, o = Offset(w / 2, s.height * 0.18);
  final gold = Paint()
    ..shader = const LinearGradient(colors: [Color(0xFFE9CF8E), Color(0xFFB08A45), Color(0xFFE9CF8E)])
        .createShader(Rect.fromCircle(center: o, radius: w * 0.2))
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.018;
  c.drawCircle(o - Offset(w * 0.06, 0), w * 0.1, gold);
  c.drawCircle(o + Offset(w * 0.06, 0), w * 0.1, gold);
  _sparkle(c, o + Offset(w * 0.16, -w * 0.1), w * 0.025, const Color(0xFFB08A45));
  _sparkle(c, o + Offset(-w * 0.18, w * 0.08), w * 0.015, const Color(0xFFB08A45));
  _border(c, s, const Color(0xFFB08A45), 0.04, 0.002);
}

void _goldNumber(Canvas c, Size s, CardData d) {
  final w = s.width;
  const gold = Color(0xFFD6B26E);
  _glow(c, Offset(w / 2, s.height * 0.2), w * 0.35, const Color(0x33D6B26E));
  if (d.years != null) {
    _text(c, '${d.years}', Offset(w / 2, s.height * 0.2), w * 0.3, gold);
  } else {
    _sparkle(c, Offset(w / 2, s.height * 0.2), w * 0.1, gold);
  }
  _border(c, s, gold.withValues(alpha: 0.7), 0.04, 0.0025);
}

void _laurel(Canvas c, Size s, CardData d) {
  final w = s.width, o = Offset(w / 2, s.height * 0.2);
  const green = Color(0xFF6E8B4E);
  for (final side in [-1.0, 1.0]) {
    for (var i = 0; i < 9; i++) {
      final a = math.pi / 2 + side * (0.35 + i * 0.28);
      final p = o + Offset(math.cos(a), math.sin(a)) * w * 0.17;
      _leaf(c, p, w * 0.07, a + side * (math.pi / 2 + 0.5), green);
    }
  }
  if (d.years != null) {
    _text(c, '${d.years}', o, w * 0.13, const Color(0xFFB08A45));
  } else {
    _sparkle(c, o, w * 0.05, const Color(0xFFB08A45));
  }
}

void _starry(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final r = math.Random(2);
  for (var i = 0; i < 80; i++) {
    final p = Offset(r.nextDouble() * w, r.nextDouble() * h);
    final middle = p.dx > w * 0.1 && p.dx < w * 0.9 && p.dy > h * 0.22 && p.dy < h * 0.88;
    if (middle && r.nextDouble() > 0.2) continue;
    c.drawCircle(p, w * 0.002 * (1 + r.nextDouble() * 2), _fill(Colors.white.withValues(alpha: 0.3 + r.nextDouble() * 0.6)));
  }
  final moon = Offset(w * 0.78, h * 0.12);
  _glow(c, moon, w * 0.2, const Color(0x55F5D38A));
  c.drawCircle(moon, w * 0.07, _fill(const Color(0xFFF7E3B0)));
  _sparkle(c, Offset(w * 0.2, h * 0.14), w * 0.03, const Color(0xFFF5D38A));
}

void _watercolour(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  for (final (x, y, r, col) in [
    (0.1, 0.08, 0.3, const Color(0x66F7B29A)),
    (0.9, 0.12, 0.25, const Color(0x5598C1B8)),
    (0.85, 0.92, 0.32, const Color(0x55A7C4E5)),
    (0.1, 0.95, 0.24, const Color(0x55F2D38C)),
  ]) {
    c.drawCircle(
      Offset(w * x, h * y),
      w * r,
      Paint()
        ..color = col
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06),
    );
  }
  final stem = Offset(w * 0.5, h * 0.2);
  _leaf(c, stem, w * 0.12, -math.pi + 0.5, const Color(0xFF5E8C7E));
  _leaf(c, stem, w * 0.12, -0.5, const Color(0xFF7FA597));
  _leaf(c, stem, w * 0.1, -math.pi / 2, const Color(0xFF4F7D6F));
}

void _artDeco(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  const gold = Color(0xFFD4AF37);
  for (final (o, dir) in [(Offset(w / 2, 0), 1.0), (Offset(w / 2, h), -1.0)]) {
    for (var i = 0; i <= 12; i++) {
      final a = math.pi * i / 12;
      final end = o + Offset(math.cos(a) * w * 0.3, dir * math.sin(a) * w * 0.2);
      c.drawLine(o, end, _stroke(gold.withValues(alpha: 0.7), w * 0.002));
    }
    for (final r in [0.1, 0.2, 0.3]) {
      c.drawArc(
        Rect.fromCenter(center: o, width: w * r * 2, height: w * r * 1.34),
        dir > 0 ? 0 : math.pi,
        math.pi,
        false,
        _stroke(gold, w * 0.003),
      );
    }
  }
  _border(c, s, gold, 0.04, 0.003);
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(w * 0.04, h * 0.5 - w * 0.02 + i * w * 0.02),
      Offset(w * 0.1, h * 0.5 - w * 0.02 + i * w * 0.02),
      _stroke(gold, w * 0.002),
    );
    c.drawLine(
      Offset(w * 0.9, h * 0.5 - w * 0.02 + i * w * 0.02),
      Offset(w * 0.96, h * 0.5 - w * 0.02 + i * w * 0.02),
      _stroke(gold, w * 0.002),
    );
  }
}

void _dandiya(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final o = Offset(w / 2, h * 0.17);
  for (final a in [-0.6, 0.6]) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    for (var i = 0; i < 8; i++) {
      c.drawRect(
        Rect.fromLTWH(-w * 0.012, -w * 0.18 + i * w * 0.045, w * 0.024, w * 0.045),
        _fill(i.isEven ? const Color(0xFFFFB300) : const Color(0xFFE53935)),
      );
    }
    c.restore();
  }
  // Mirror-work dots around the edge.
  for (var i = 0; i < 40; i++) {
    final t = i / 40;
    final p = t < 0.25
        ? Offset(w * t * 4, w * 0.03)
        : t < 0.5
        ? Offset(w * 0.97, h * (t - 0.25) * 4)
        : t < 0.75
        ? Offset(w * (1 - (t - 0.5) * 4), h - w * 0.03)
        : Offset(w * 0.03, h * (1 - (t - 0.75) * 4));
    c.drawCircle(p, w * 0.012, _fill(i.isEven ? const Color(0xFFFFE9A8) : const Color(0xFF26C6DA)));
  }
}

void _tricolour(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final top = Path()
    ..moveTo(0, 0)
    ..lineTo(w, 0)
    ..lineTo(w, h * 0.08)
    ..quadraticBezierTo(w * 0.5, h * 0.16, 0, h * 0.06)
    ..close();
  c.drawPath(top, _fill(const Color(0xFFFF9933)));
  final bottom = Path()
    ..moveTo(0, h)
    ..lineTo(w, h)
    ..lineTo(w, h * 0.93)
    ..quadraticBezierTo(w * 0.5, h * 0.85, 0, h * 0.95)
    ..close();
  c.drawPath(bottom, _fill(const Color(0xFF138808)));
  final o = Offset(w / 2, h * 0.22);
  const navy = Color(0xFF0B2A6F);
  c.drawCircle(o, w * 0.07, _stroke(navy, w * 0.006));
  for (var i = 0; i < 24; i++) {
    final a = i * math.pi / 12;
    c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * w * 0.07, _stroke(navy, w * 0.002));
  }
}

void _kannada(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  c.drawRect(Rect.fromLTWH(0, 0, w, h * 0.09), _fill(const Color(0xFFFFD500)));
  c.drawRect(Rect.fromLTWH(0, h * 0.09, w, h * 0.04), _fill(const Color(0xFFD32F2F)));
  c.drawRect(Rect.fromLTWH(0, h * 0.91, w, h * 0.09), _fill(const Color(0xFFD32F2F)));
  c.drawRect(Rect.fromLTWH(0, h * 0.87, w, h * 0.04), _fill(const Color(0xFFFFD500)));
  _flower(c, Offset(w / 2, h * 0.22), w * 0.08, 8, const Color(0xFFFFD500), const Color(0xFFD32F2F));
}

void _christmas(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final r = math.Random(9);
  for (var i = 0; i < 60; i++) {
    c.drawCircle(
      Offset(r.nextDouble() * w, r.nextDouble() * h),
      w * 0.004 * (1 + r.nextDouble()),
      _fill(Colors.white.withValues(alpha: 0.5 + r.nextDouble() * 0.4)),
    );
  }
  final top = Offset(w / 2, h * 0.05);
  for (var i = 0; i < 3; i++) {
    final y = top.dy + w * 0.05 + i * w * 0.07;
    final half = w * (0.08 + i * 0.05);
    c.drawPath(
      Path()
        ..moveTo(top.dx, y - w * 0.05)
        ..lineTo(top.dx + half, y + w * 0.07)
        ..lineTo(top.dx - half, y + w * 0.07)
        ..close(),
      _fill(Color.lerp(const Color(0xFF3F8F5E), const Color(0xFF2E6B47), i / 2)!),
    );
  }
  c.drawRect(
    Rect.fromCenter(center: Offset(top.dx, top.dy + w * 0.33), width: w * 0.05, height: w * 0.05),
    _fill(const Color(0xFF7A4A24)),
  );
  _sparkle(c, top, w * 0.04, const Color(0xFFF5D38A));
  for (final (dx, dy, col) in [
    (-0.05, 0.14, Color(0xFFE53935)),
    (0.06, 0.2, Color(0xFFF5D38A)),
    (-0.09, 0.27, Color(0xFFF5D38A)),
    (0.1, 0.28, Color(0xFFE53935)),
  ]) {
    c.drawCircle(top + Offset(w * dx, w * dy), w * 0.012, _fill(col));
  }
}

void _thankYouNote(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  for (var y = h * 0.3; y < h * 0.88; y += w * 0.06) {
    c.drawLine(Offset(w * 0.1, y), Offset(w * 0.9, y), _stroke(const Color(0x1A5E86B8), w * 0.002));
  }
  c.drawLine(Offset(w * 0.08, 0), Offset(w * 0.08, h), _stroke(const Color(0x40D1495B), w * 0.002));
  _flower(c, Offset(w * 0.86, h * 0.1), w * 0.06, 5, const Color(0xFFF2C09A), const Color(0xFFD1495B));
  _leaf(c, Offset(w * 0.86, h * 0.1), w * 0.1, 2.4, const Color(0xFF8FAF7E));
}

void _sunrise(Canvas c, Size s, CardData d) {
  final w = s.width, h = s.height;
  final o = Offset(w / 2, h * 0.24);
  _glow(c, o, w * 0.45, const Color(0x66FFD54F));
  for (var i = 0; i < 16; i++) {
    final a = math.pi + i * math.pi / 15;
    c.drawLine(
      o + Offset(math.cos(a), math.sin(a)) * w * 0.13,
      o + Offset(math.cos(a), math.sin(a)) * w * 0.24,
      _stroke(const Color(0xFFF08A24), w * 0.004),
    );
  }
  c.drawArc(Rect.fromCircle(center: o, radius: w * 0.11), math.pi, math.pi, true, _fill(const Color(0xFFF6A623)));
  c.drawLine(Offset(w * 0.12, o.dy), Offset(w * 0.88, o.dy), _stroke(const Color(0xFF8A5A2B), w * 0.004));
  // Neem and mango leaves for new beginnings.
  for (var i = 0; i < 5; i++) {
    _leaf(c, Offset(w * (0.3 + i * 0.1), o.dy + w * 0.02), w * 0.07, math.pi / 2 + (i - 2) * 0.2, const Color(0xFF4F7A3A));
  }
}

// ---------------------------------------------------------------------------

const _ivory = [Color(0xFFFBF7EE), Color(0xFFF3EBDA)];
const _charcoal = [Color(0xFF2A2724), Color(0xFF171513)];

final cardTemplates = <CardTemplate>[
  const CardTemplate(
    id: 'charcoal_gold',
    name: 'Charcoal & gold',
    kinds: _all,
    bg: _charcoal,
    ink: Color(0xFFF3ECDD),
    accent: Color(0xFFD6B26E),
    paint: _charcoalGold,
  ),
  const CardTemplate(
    id: 'minimal',
    name: 'Minimal ivory',
    kinds: _all,
    bg: _ivory,
    ink: Color(0xFF2A2724),
    accent: Color(0xFFA07A38),
    paint: _minimal,
  ),
  const CardTemplate(
    id: 'balloons',
    name: 'Balloons',
    kinds: {CardKind.birthday, CardKind.milestone},
    bg: [Color(0xFFEAF5FF), Color(0xFFFFFFFF)],
    ink: Color(0xFF23324A),
    accent: Color(0xFFD9483A),
    paint: _balloons,
    textTop: 0.3,
  ),
  const CardTemplate(
    id: 'cake',
    name: 'Birthday cake',
    kinds: {CardKind.birthday, CardKind.milestone},
    bg: [Color(0xFFFFF1F4), Color(0xFFFFE3EA)],
    ink: Color(0xFF5B2340),
    accent: Color(0xFFC23B6C),
    paint: _cake,
    textTop: 0.07,
    textBottom: 0.47,
  ),
  const CardTemplate(
    id: 'confetti',
    name: 'Confetti',
    kinds: {CardKind.birthday, CardKind.milestone, CardKind.general},
    bg: [Color(0xFFFFFFFF), Color(0xFFFFF7E8)],
    ink: Color(0xFF2A2724),
    accent: Color(0xFFC23B6C),
    paint: _confetti,
    textTop: 0.2,
  ),
  const CardTemplate(
    id: 'floral',
    name: 'Floral corners',
    kinds: {CardKind.birthday, CardKind.anniversary, CardKind.thankYou, CardKind.general},
    bg: _ivory,
    ink: Color(0xFF3B2F2A),
    accent: Color(0xFFB0506A),
    paint: _floralCorners,
    textTop: 0.22,
    textBottom: 0.16,
  ),
  const CardTemplate(
    id: 'watercolour',
    name: 'Watercolour',
    kinds: {CardKind.birthday, CardKind.thankYou, CardKind.general},
    bg: [Color(0xFFFFFFFF), Color(0xFFFAF7F2)],
    ink: Color(0xFF2E3A3A),
    accent: Color(0xFF4F7D6F),
    paint: _watercolour,
  ),
  const CardTemplate(
    id: 'gold_number',
    name: 'Golden number',
    kinds: {CardKind.milestone, CardKind.anniversary},
    bg: _charcoal,
    ink: Color(0xFFF3ECDD),
    accent: Color(0xFFD6B26E),
    paint: _goldNumber,
    textTop: 0.36,
  ),
  const CardTemplate(
    id: 'laurel',
    name: 'Laurel wreath',
    kinds: {CardKind.milestone, CardKind.anniversary, CardKind.general},
    bg: _ivory,
    ink: Color(0xFF2F3324),
    accent: Color(0xFF8A6A2E),
    paint: _laurel,
    textTop: 0.38,
  ),
  const CardTemplate(
    id: 'rings',
    name: 'Two rings',
    kinds: {CardKind.anniversary},
    bg: [Color(0xFFFAF5EC), Color(0xFFF2E8D6)],
    ink: Color(0xFF3B2F22),
    accent: Color(0xFF9C7636),
    paint: _rings,
    textTop: 0.34,
  ),
  const CardTemplate(
    id: 'rose',
    name: 'Rose petals',
    kinds: {CardKind.anniversary, CardKind.birthday},
    bg: [Color(0xFFFCEDEB), Color(0xFFF6D6D3)],
    ink: Color(0xFF5A2B34),
    accent: Color(0xFFA8405A),
    paint: _roseBlush,
  ),
  const CardTemplate(
    id: 'art_deco',
    name: 'Art deco',
    kinds: {CardKind.anniversary, CardKind.milestone, CardKind.general},
    festivals: {'new_year'},
    bg: [Color(0xFF151515), Color(0xFF0B0B0B)],
    ink: Color(0xFFF3E6C8),
    accent: Color(0xFFD4AF37),
    paint: _artDeco,
    textTop: 0.24,
    textBottom: 0.2,
  ),
  const CardTemplate(
    id: 'starry',
    name: 'Starry night',
    kinds: {CardKind.general, CardKind.birthday, CardKind.thankYou, CardKind.festival},
    festivals: {'guru_purnima', 'maha_shivaratri'},
    bg: [Color(0xFF0D1B3E), Color(0xFF1A2F5E)],
    ink: Color(0xFFF0EEE6),
    accent: Color(0xFFF5D38A),
    paint: _starry,
    textTop: 0.24,
  ),
  const CardTemplate(
    id: 'thank_you',
    name: 'Thank-you note',
    kinds: {CardKind.thankYou},
    bg: [Color(0xFFFFFDF7), Color(0xFFFBF6EA)],
    ink: Color(0xFF2E3440),
    accent: Color(0xFFB0485E),
    paint: _thankYouNote,
    textTop: 0.16,
  ),
  // Traditional and festival designs.
  const CardTemplate(
    id: 'rangoli',
    name: 'Rangoli',
    kinds: {CardKind.festival, CardKind.general},
    festivals: _pooja,
    bg: [Color(0xFF5B1A1A), Color(0xFF3A0F0F)],
    ink: Color(0xFFFFF3E0),
    accent: Color(0xFFF4B942),
    paint: _rangoli,
    textTop: 0.4,
  ),
  const CardTemplate(
    id: 'toran',
    name: 'Marigold toran',
    kinds: {CardKind.festival, CardKind.general},
    festivals: {..._pooja, ..._diwali},
    bg: [Color(0xFFFFF7E8), Color(0xFFFFEBCF)],
    ink: Color(0xFF4A2A12),
    accent: Color(0xFFB8551A),
    paint: _toran,
    textTop: 0.3,
    textBottom: 0.14,
  ),
  const CardTemplate(
    id: 'temple',
    name: 'Temple arch',
    kinds: {CardKind.festival, CardKind.anniversary, CardKind.general},
    festivals: {'ram_navami', 'hanuman_jayanti', 'krishna_janmashtami', 'maha_shivaratri', 'akshaya_tritiya'},
    bg: [Color(0xFF7A1F2B), Color(0xFF4E1320)],
    ink: Color(0xFFFDF1DC),
    accent: Color(0xFFE8C07A),
    paint: _templeArch,
    textTop: 0.3,
    textBottom: 0.12,
  ),
  const CardTemplate(
    id: 'diyas',
    name: 'Diya glow',
    kinds: {CardKind.festival},
    festivals: {..._diwali, 'vijayadashami'},
    bg: [Color(0xFF1B1328), Color(0xFF2E1832)],
    ink: Color(0xFFFFF1D6),
    accent: Color(0xFFF7C66B),
    paint: _diyas,
    textTop: 0.12,
    textBottom: 0.3,
  ),
  const CardTemplate(
    id: 'fireworks',
    name: 'Fireworks',
    kinds: {CardKind.festival, CardKind.birthday, CardKind.milestone},
    festivals: {'new_year', 'diwali_lakshmi_puja', 'naraka_chaturdashi'},
    bg: [Color(0xFF0B1026), Color(0xFF1B1440)],
    ink: Color(0xFFFFF8EA),
    accent: Color(0xFFF7C66B),
    paint: _fireworks,
    textTop: 0.34,
    textBottom: 0.16,
  ),
  const CardTemplate(
    id: 'holi',
    name: 'Holi colours',
    kinds: {CardKind.festival},
    festivals: {'holi', 'holika_dahan'},
    bg: [Color(0xFFFFFFFF), Color(0xFFFFFBF2)],
    ink: Color(0xFF3A2350),
    accent: Color(0xFFC2185B),
    paint: _holi,
    textTop: 0.22,
    textBottom: 0.18,
  ),
  const CardTemplate(
    id: 'kites',
    name: 'Kites',
    kinds: {CardKind.festival},
    festivals: {'makar_sankranti'},
    bg: [Color(0xFF9ED8F2), Color(0xFFE6F6FF)],
    ink: Color(0xFF1F3A5F),
    accent: Color(0xFFC4501E),
    paint: _kites,
    textTop: 0.32,
    textBottom: 0.12,
  ),
  const CardTemplate(
    id: 'lotus',
    name: 'Lotus',
    kinds: {CardKind.festival, CardKind.general},
    festivals: {'ganesh_chaturthi', 'varamahalakshmi', 'gowri_habba', 'guru_purnima', 'akshaya_tritiya', 'nag_panchami'},
    bg: [Color(0xFFFBEFF5), Color(0xFFF1DDEB)],
    ink: Color(0xFF4A2440),
    accent: Color(0xFFA23A6C),
    paint: _lotus,
    textTop: 0.12,
    textBottom: 0.36,
  ),
  const CardTemplate(
    id: 'rakhi',
    name: 'Rakhi',
    kinds: {CardKind.festival},
    festivals: {'raksha_bandhan', 'bhai_dooj'},
    bg: [Color(0xFFFFF6EA), Color(0xFFFFE9D2)],
    ink: Color(0xFF5A1E12),
    accent: Color(0xFFB03427),
    paint: _rakhi,
    textTop: 0.34,
  ),
  const CardTemplate(
    id: 'dandiya',
    name: 'Dandiya',
    kinds: {CardKind.festival},
    festivals: {'navratri_begins', 'vijayadashami'},
    bg: [Color(0xFF4A0E57), Color(0xFF6A1B5C)],
    ink: Color(0xFFFFF0C2),
    accent: Color(0xFFFFB300),
    paint: _dandiya,
    textTop: 0.34,
    textBottom: 0.1,
  ),
  const CardTemplate(
    id: 'sunrise',
    name: 'New sunrise',
    kinds: {CardKind.festival, CardKind.general},
    festivals: {'ugadi', 'makar_sankranti', 'new_year'},
    bg: [Color(0xFFFFF4DC), Color(0xFFFFE2B8)],
    ink: Color(0xFF4A2A12),
    accent: Color(0xFFB8551A),
    paint: _sunrise,
    textTop: 0.32,
  ),
  const CardTemplate(
    id: 'tricolour',
    name: 'Tiranga',
    kinds: {CardKind.festival},
    festivals: {'republic_day', 'independence_day', 'gandhi_jayanti'},
    bg: [Color(0xFFFFFFFF), Color(0xFFF7F7F2)],
    ink: Color(0xFF0B2A6F),
    accent: Color(0xFFD9731A),
    paint: _tricolour,
    textTop: 0.32,
    textBottom: 0.15,
  ),
  const CardTemplate(
    id: 'kannada',
    name: 'Kannada colours',
    kinds: {CardKind.festival},
    festivals: {'kannada_rajyotsava'},
    bg: [Color(0xFFFFFDF3), Color(0xFFFFF6D8)],
    ink: Color(0xFF3A1A00),
    accent: Color(0xFFC62828),
    paint: _kannada,
    textTop: 0.32,
    textBottom: 0.15,
  ),
  const CardTemplate(
    id: 'christmas',
    name: 'Christmas tree',
    kinds: {CardKind.festival},
    festivals: {'christmas'},
    bg: [Color(0xFF0F3D2E), Color(0xFF082219)],
    ink: Color(0xFFFFF8EA),
    accent: Color(0xFFF5D38A),
    paint: _christmas,
    textTop: 0.44,
  ),
];

/// A card at any size; 4 : 5 like a phone photo.
class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key, required this.template, required this.data});

  final CardTemplate template;
  final CardData data;

  @override
  Widget build(BuildContext context) {
    final t = template;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight, k = w / 360;
          final msg = data.message.trim();
          final msgSize =
              (msg.length > 360
                  ? 12.0
                  : msg.length > 240
                  ? 13.5
                  : msg.length > 140
                  ? 15.0
                  : 17.0) *
              k;
          TextStyle style(String family, double size, Color color, {FontWeight w = FontWeight.w600, bool italic = false}) =>
              TextStyle(
                fontFamily: family,
                fontFamilyFallback: fontFallback,
                fontSize: size,
                color: color,
                fontWeight: w,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                height: 1.25,
              );
          return ClipRect(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: t.bg),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _CardPainter(t, data))),
                  Positioned(
                    left: w * 0.11,
                    right: w * 0.11,
                    top: h * t.textTop,
                    bottom: h * t.textBottom,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: w * 0.78,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (data.headline.isNotEmpty)
                              Text(
                                data.headline,
                                textAlign: TextAlign.center,
                                style: style(serif, 25 * k, t.accent, italic: true),
                                maxLines: 2,
                              ),
                            if (data.name.isNotEmpty) ...[
                              SizedBox(height: 2 * k),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(data.name, style: style(serif, 46 * k, t.ink, w: FontWeight.w700), maxLines: 1),
                              ),
                            ],
                            if (msg.isNotEmpty) ...[
                              SizedBox(height: 12 * k),
                              Text(
                                msg,
                                textAlign: TextAlign.center,
                                style: style(sans, msgSize, t.ink.withValues(alpha: 0.88), w: FontWeight.w500),
                              ),
                            ],
                            if (data.footer.isNotEmpty) ...[
                              SizedBox(height: 12 * k),
                              Text(data.footer, textAlign: TextAlign.center, style: style(serif, 20 * k, t.accent, italic: true)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  _CardPainter(this.t, this.data);

  final CardTemplate t;
  final CardData data;

  @override
  void paint(Canvas canvas, Size size) => t.paint(canvas, size, data);

  @override
  bool shouldRepaint(_CardPainter old) => old.t != t || old.data.years != data.years;
}

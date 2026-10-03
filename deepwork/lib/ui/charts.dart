import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import 'widgets.dart';

// Validated categorical palette (fixed order, never cycled), light and dark steps.
const _catLight = [Color(0xFF2A78D6), Color(0xFFEB6834), Color(0xFF1BAF7A), Color(0xFFEDA100), Color(0xFFE87BA4), Color(0xFF008300), Color(0xFF4A3AA7), Color(0xFFE34948)];
const _catDark = [Color(0xFF3987E5), Color(0xFFD95926), Color(0xFF199E70), Color(0xFFC98500), Color(0xFFD55181), Color(0xFF008300), Color(0xFF9085E9), Color(0xFFE66767)];

List<Color> categorical(BuildContext context) => context.pal.isDark ? _catDark : _catLight;

class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CardHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 4),
          child,
        ]),
      );
}

double _niceMax(double v) {
  if (v <= 0) return 1;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final m in [1, 2, 2.5, 5, 10]) {
    if (v <= m * mag) return m * mag;
  }
  return v;
}

Widget _axisLabel(BuildContext context, String text, TitleMeta meta) =>
    SideTitleWidget(meta: meta, space: 6, child: Text(text, style: TextStyle(color: context.pal.muted, fontSize: 10.5, fontFeatures: tabular)));

/// Single-series bar chart: thin rounded bars, recessive grid, tap for a tooltip.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.labels, required this.values, this.color, this.unit = '', this.height = 190, this.valueLabel = ''});
  final List<String> labels;
  final List<double> values;
  final Color? color;
  final String unit, valueLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = color ?? p.accent;
    final maxV = _niceMax(values.fold<double>(0, math.max));
    final every = (labels.length / 7).ceil().clamp(1, 1000);
    final barW = (220 / math.max(1, labels.length)).clamp(3.0, 22.0);
    return SizedBox(
      height: height,
      child: BarChart(BarChartData(
        maxY: maxY(maxV),
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => p.card2,
            tooltipBorder: BorderSide(color: p.border),
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              '${labels[group.x]}\n',
              TextStyle(color: p.muted, fontSize: 11),
              children: [TextSpan(text: '${_fmt(rod.toY)}${unit.isEmpty ? '' : ' $unit'}', style: TextStyle(color: p.fg, fontWeight: FontWeight.w600, fontSize: 12.5))],
            ),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxV / 2, getDrawingHorizontalLine: (_) => FlLine(color: p.border.withValues(alpha: 0.7), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: maxV / 2, getTitlesWidget: (v, m) => _axisLabel(context, _fmt(v), m))),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length || (i % every != 0 && i != labels.length - 1)) return const SizedBox.shrink();
                return _axisLabel(context, labels[i], m);
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: values[i], color: c, width: barW, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            ]),
        ],
      )),
    );
  }

  double maxY(double v) => v;
}

/// Single-series line chart (0–100 by default for rates).
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({super.key, required this.labels, required this.values, this.color, this.maxY, this.suffix = '', this.height = 190, this.tooltip});
  final List<String> labels;
  final List<double?> values;
  final Color? color;
  final double? maxY;
  final String suffix;
  final double height;
  final String Function(int i)? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = color ?? p.accent;
    final top = maxY ?? _niceMax(values.whereType<double>().fold<double>(0, math.max));
    final every = (labels.length / 7).ceil().clamp(1, 1000);
    final spots = [for (var i = 0; i < values.length; i++) if (values[i] != null) FlSpot(i.toDouble(), values[i]!)];
    return SizedBox(
      height: height,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: top,
        minX: 0,
        maxX: math.max(1, labels.length - 1).toDouble(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.card2,
            tooltipBorder: BorderSide(color: p.border),
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${labels[s.x.toInt()]}\n',
                  TextStyle(color: p.muted, fontSize: 11),
                  children: [TextSpan(text: tooltip?.call(s.x.toInt()) ?? '${_fmt(s.y)}$suffix', style: TextStyle(color: p.fg, fontWeight: FontWeight.w600, fontSize: 12.5))],
                ),
            ],
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: top / 2, getDrawingHorizontalLine: (_) => FlLine(color: p.border.withValues(alpha: 0.7), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: top / 2, getTitlesWidget: (v, m) => _axisLabel(context, '${_fmt(v)}$suffix', m))),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (v != i || i < 0 || i >= labels.length || (i % every != 0 && i != labels.length - 1)) return const SizedBox.shrink();
                return _axisLabel(context, labels[i], m);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: c,
            barWidth: 2,
            dotData: FlDotData(show: labels.length <= 31, getDotPainter: (s, a, b, i) => FlDotCirclePainter(radius: 3, color: c, strokeWidth: 0)),
            belowBarData: BarAreaData(show: true, color: c.withValues(alpha: 0.08)),
          ),
        ],
      )),
    );
  }
}

/// Donut with a legend; colors follow each item's fixed color (identity), never its rank.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.items, this.centerLabel = 'total'});
  final List<(String, double, Color)> items;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final total = items.fold<double>(0, (a, e) => a + e.$2);
    return Row(children: [
      SizedBox(
        width: 150,
        height: 150,
        child: Stack(alignment: Alignment.center, children: [
          PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 46,
            startDegreeOffset: -90,
            sections: [for (final e in items) PieChartSectionData(value: e.$2, color: e.$3, radius: 24, showTitle: false)],
          )),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_fmt(total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, fontFeatures: tabular)),
            Text(centerLabel, style: TextStyle(color: p.muted, fontSize: 11)),
          ]),
        ]),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final e in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Dot(e.$3, size: 9),
                const SizedBox(width: 8),
                Expanded(child: Text(e.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                Text('${total == 0 ? 0 : (e.$2 / total * 100).round()}%', style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: tabular)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

String _fmt(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

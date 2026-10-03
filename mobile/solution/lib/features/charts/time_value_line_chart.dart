import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/formatters.dart';
import 'time_series.dart';

/// Touch-responsive line chart of dated values (x = date, y = value).
///
/// Tap or drag anywhere on the chart to move a crosshair to the nearest data
/// point; its exact date and value appear in a tooltip and are reported via
/// [onPointSelected] (null when the finger lifts).
///
/// Handles 1–2 point series (axes padded, dots shown) and gaps in the data
/// (the line breaks instead of interpolating across missing dates).
class TimeValueLineChart extends StatelessWidget {
  const TimeValueLineChart({
    super.key,
    required this.series,
    this.height = 220,
    this.color,
    this.valueFormatter = Fmt.money,
    this.axisValueFormatter = Fmt.compactMoney,
    this.onPointSelected,
    this.semanticLabel,
  });

  final ChartSeries series;
  final double height;
  final Color? color;
  final String Function(num) valueFormatter;
  final String Function(num) axisValueFormatter;
  final ValueChanged<TimeValuePoint?>? onPointSelected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = color ?? theme.colorScheme.primary;
    final labelStyle = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final pointCount = series.points.length;
    final showDots = pointCount <= 12;
    final xSpan = series.maxX - series.minX;
    final ySpan = series.maxY - series.minY;

    final chart = LineChart(
      LineChartData(
        minX: series.minX,
        maxX: series.maxX,
        minY: series.minY,
        maxY: series.maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: ySpan > 0 ? ySpan / 4 : null,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: ySpan > 0 ? ySpan / 4 : null,
              getTitlesWidget: (value, meta) {
                // Skip the padded min/max edges, which are not "real" values.
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(axisValueFormatter(value), style: labelStyle),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xSpan > 0 ? xSpan / 3 : null,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                child: Text(
                  _axisDateLabel(dateFromDayX(value), xSpan),
                  style: labelStyle,
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          // Nearest point by x, wherever the finger is (not just near a dot).
          touchSpotThreshold: double.infinity,
          touchCallback: (event, response) {
            if (onPointSelected == null) return;
            if (!event.isInterestedForInteractions) {
              onPointSelected!(null);
              return;
            }
            final spot = response?.lineBarSpots?.firstOrNull;
            onPointSelected!(spot == null ? null : _pointAt(spot.x));
          },
          getTouchedSpotIndicator: (bar, indexes) => [
            for (final _ in indexes)
              TouchedSpotIndicatorData(
                FlLine(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [4, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => theme.colorScheme.inverseSurface,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${Fmt.date(dateFromDayX(spot.x))}\n',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface
                        .withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: valueFormatter(spot.y),
                      style: TextStyle(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: series.spots,
            color: lineColor,
            barWidth: 2.5,
            isCurved: false, // Curves would invent values between points.
            dotData: FlDotData(
              show: showDots,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: pointCount <= 2 ? 4.5 : 3,
                color: lineColor,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: pointCount > 1,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.22),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
    );

    return Semantics(
      label: semanticLabel ?? _defaultSemantics(),
      child: SizedBox(
        height: height,
        child: Listener(
          onPointerDown: (_) => HapticFeedback.selectionClick(),
          child: chart,
        ),
      ),
    );
  }

  TimeValuePoint? _pointAt(double x) {
    for (final p in series.points) {
      if (dayX(p.date) == x) return p;
    }
    return null;
  }

  String _defaultSemantics() {
    if (series.isEmpty) return 'Chart with no data';
    final first = series.points.first;
    final last = series.points.last;
    return 'Line chart from ${Fmt.date(first.date)} (${valueFormatter(first.value)}) '
        'to ${Fmt.date(last.date)} (${valueFormatter(last.value)}), '
        '${series.points.length} points.';
  }

  static String _axisDateLabel(DateTime date, double spanDays) {
    if (spanDays > 300) return '${_months[date.month - 1]} ${date.year % 100}';
    return '${_months[date.month - 1]} ${date.day}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

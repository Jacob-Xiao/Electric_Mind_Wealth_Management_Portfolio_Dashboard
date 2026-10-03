import 'package:fl_chart/fl_chart.dart';

import '../shared/formatters.dart';

/// A dated value: a portfolio market value or a single security's price.
class TimeValuePoint {
  const TimeValuePoint(this.date, this.value);

  final DateTime date; // UTC calendar date
  final double value;

  /// Parses `[{date, <valueKey>}]` rows, dropping malformed entries and
  /// returning them sorted by date with duplicate dates removed (last wins).
  static List<TimeValuePoint> parseList(Object? raw, {required String valueKey}) {
    if (raw is! List) return const [];
    final byDate = <DateTime, TimeValuePoint>{};
    for (final row in raw) {
      if (row is! Map) continue;
      final date = Fmt.parseIsoDate(row['date'] as String?);
      final value = row[valueKey];
      if (date == null || value is! num || !value.isFinite) continue;
      byDate[date] = TimeValuePoint(date, value.toDouble());
    }
    final points = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}

const _msPerDay = 86400000;

/// X coordinate for a date: whole days since the epoch, so the x-axis is real
/// time and missing dates take up horizontal space instead of being squeezed.
double dayX(DateTime date) =>
    (date.toUtc().millisecondsSinceEpoch / _msPerDay).roundToDouble();

DateTime dateFromDayX(double x) =>
    DateTime.fromMillisecondsSinceEpoch((x * _msPerDay).round(), isUtc: true);

/// Spots ready for fl_chart plus some facts about them.
class ChartSeries {
  const ChartSeries({
    required this.spots,
    required this.points,
    required this.gapCount,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  /// May contain [FlSpot.nullSpot] where the data has a gap, which fl_chart
  /// draws as a break in the line (no interpolation across missing dates).
  final List<FlSpot> spots;
  final List<TimeValuePoint> points;
  final int gapCount;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  bool get isEmpty => points.isEmpty;
  bool get hasGaps => gapCount > 0;
}

/// Builds a [ChartSeries], breaking the line where consecutive points are
/// further apart than the series' usual spacing.
///
/// The usual spacing is the median gap between points, so daily, weekly or
/// monthly series all work. A gap counts as missing data when it exceeds
/// [gapFactor] × median (and is at least 2 days, so weekends in a daily
/// series of trading days are not flagged when the median is 1).
ChartSeries buildChartSeries(
  List<TimeValuePoint> points, {
  double gapFactor = 1.5,
}) {
  if (points.isEmpty) {
    return const ChartSeries(
      spots: [], points: [], gapCount: 0,
      minX: 0, maxX: 1, minY: 0, maxY: 1,
    );
  }

  final xs = points.map((p) => dayX(p.date)).toList(growable: false);
  final gapThreshold = _gapThreshold(xs, gapFactor);

  final spots = <FlSpot>[];
  var gapCount = 0;
  var minY = points.first.value;
  var maxY = points.first.value;
  for (var i = 0; i < points.length; i++) {
    if (i > 0 && gapThreshold != null && xs[i] - xs[i - 1] > gapThreshold) {
      spots.add(FlSpot.nullSpot);
      gapCount++;
    }
    spots.add(FlSpot(xs[i], points[i].value));
    if (points[i].value < minY) minY = points[i].value;
    if (points[i].value > maxY) maxY = points[i].value;
  }

  // Pad the axes so 1-point and flat series don't collapse to zero height /
  // width (which would otherwise render as a degenerate chart).
  var minX = xs.first;
  var maxX = xs.last;
  if (maxX - minX < 1) {
    minX -= 1;
    maxX += 1;
  }
  final ySpan = maxY - minY;
  final yPad = ySpan == 0
      ? (maxY.abs() * 0.02).clamp(1.0, double.infinity)
      : ySpan * 0.08;

  return ChartSeries(
    spots: spots,
    points: points,
    gapCount: gapCount,
    minX: minX,
    maxX: maxX,
    minY: minY - yPad,
    maxY: maxY + yPad,
  );
}

double? _gapThreshold(List<double> xs, double factor) {
  if (xs.length < 3) return null; // Not enough points to know "usual" spacing.
  final diffs = <double>[
    for (var i = 1; i < xs.length; i++) xs[i] - xs[i - 1],
  ]..sort();
  final median = diffs[diffs.length ~/ 2];
  final threshold = median * factor;
  return threshold < 2 ? 2 : threshold;
}

/// Time windows offered above the portfolio value chart.
enum ChartRange {
  oneMonth('1M', Duration(days: 31)),
  threeMonths('3M', Duration(days: 92)),
  oneYear('1Y', Duration(days: 366)),
  all('All', null);

  const ChartRange(this.label, this.window);

  final String label;
  final Duration? window;

  List<TimeValuePoint> apply(List<TimeValuePoint> points) {
    final window = this.window;
    if (window == null || points.isEmpty) return points;
    final cutoff = points.last.date.subtract(window);
    return points.where((p) => !p.date.isBefore(cutoff)).toList();
  }
}

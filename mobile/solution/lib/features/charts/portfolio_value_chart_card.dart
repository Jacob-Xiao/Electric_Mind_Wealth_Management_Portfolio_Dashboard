import 'package:flutter/material.dart';

import '../shared/formatters.dart';
import 'time_series.dart';
import 'time_value_line_chart.dart';

/// Task 10 — Portfolio value over time.
///
/// Feed it `performanceHistory` from `GET /portfolios/{id}`, e.g.
/// `TimeValuePoint.parseList(json['performanceHistory'], valueKey: 'marketValue')`.
///
/// The header shows the latest value and change over the selected range; while
/// the user touches the chart it shows the touched point's date and value.
class PortfolioValueChartCard extends StatefulWidget {
  const PortfolioValueChartCard({
    super.key,
    required this.history,
    this.title = 'Portfolio value',
    this.initialRange = ChartRange.threeMonths,
  });

  final List<TimeValuePoint> history;
  final String title;
  final ChartRange initialRange;

  @override
  State<PortfolioValueChartCard> createState() =>
      _PortfolioValueChartCardState();
}

class _PortfolioValueChartCardState extends State<PortfolioValueChartCard> {
  late ChartRange _range = widget.initialRange;
  TimeValuePoint? _touched;

  // Rebuilding spots on every touch event would make dragging laggy on long
  // series, so cache them per (history, range).
  List<TimeValuePoint>? _cachedHistory;
  ChartRange? _cachedRange;
  ChartSeries _series = buildChartSeries(const []);

  ChartSeries get _currentSeries {
    if (!identical(_cachedHistory, widget.history) || _cachedRange != _range) {
      _cachedHistory = widget.history;
      _cachedRange = _range;
      _series = buildChartSeries(_range.apply(widget.history));
    }
    return _series;
  }

  /// Ranges that would show something different from a shorter one.
  List<ChartRange> get _availableRanges {
    final history = widget.history;
    if (history.length < 2) return const [];
    final span = history.last.date.difference(history.first.date);
    return [
      for (final range in ChartRange.values)
        if (range.window == null || range.window! < span) range,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranges = _availableRanges;
    if (!ranges.contains(_range) && ranges.isNotEmpty) _range = ChartRange.all;
    final series = _currentSeries;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            if (series.isEmpty)
              _EmptyChart(message: 'No value history is available yet.')
            else ...[
              _Header(series: series, touched: _touched),
              const SizedBox(height: 12),
              TimeValueLineChart(
                series: series,
                onPointSelected: (p) {
                  if (p?.date != _touched?.date) setState(() => _touched = p);
                },
              ),
              if (series.points.length == 1)
                _Caption('Only one data point so far. The trend line will '
                    'appear as more history is recorded.'),
              if (series.hasGaps)
                _Caption('Breaks in the line mark dates with no data; values '
                    'are not estimated across them.'),
              if (ranges.length > 1) ...[
                const SizedBox(height: 8),
                Center(
                  child: SegmentedButton<ChartRange>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: [
                      for (final r in ranges)
                        ButtonSegment(value: r, label: Text(r.label)),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) => setState(() {
                      _range = s.first;
                      _touched = null;
                    }),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.series, required this.touched});

  final ChartSeries series;
  final TimeValuePoint? touched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = series.points.first;
    final shown = touched ?? series.points.last;
    final change = shown.value - first.value;
    final changePct = first.value == 0 ? 0.0 : change / first.value * 100;
    final changeColor = TrendStyle.color(context, change);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Fmt.money(shown.value),
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (series.points.length > 1) ...[
              Icon(TrendStyle.icon(change), color: changeColor, size: 20),
              Text(
                '${Fmt.signedMoney(change)} (${Fmt.signedPercentPoints(changePct)})',
                style: theme.textTheme.bodyMedium?.copyWith(color: changeColor),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                touched == null
                    ? 'as of ${Fmt.date(shown.date)}'
                    : Fmt.date(shown.date),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 120,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

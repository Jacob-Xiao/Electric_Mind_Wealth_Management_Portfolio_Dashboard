import 'package:flutter/material.dart';

import '../charts/time_series.dart';
import '../charts/time_value_line_chart.dart';
import '../shared/feature_api_client.dart';
import '../shared/formatters.dart';
import 'holding_detail.dart';

typedef HoldingDetailLoader = Future<HoldingDetail> Function(String ticker);

/// Task 9 — Detailed holding view.
///
/// Open it with a standard push so Android/iOS give the native transition and
/// back gesture, and the holdings list underneath keeps its scroll position:
///
/// ```dart
/// Navigator.of(context).push(HoldingDetailScreen.route(
///   summary: HoldingSummaryArgs(ticker: h.ticker, name: h.name, ...),
///   loadDetail: api.getHoldingDetail,
/// ));
/// ```
class HoldingDetailScreen extends StatefulWidget {
  const HoldingDetailScreen({
    super.key,
    required this.summary,
    required this.loadDetail,
  });

  final HoldingSummaryArgs summary;
  final HoldingDetailLoader loadDetail;

  static Route<void> route({
    required HoldingSummaryArgs summary,
    required HoldingDetailLoader loadDetail,
  }) =>
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/holding/${summary.ticker}'),
        builder: (_) =>
            HoldingDetailScreen(summary: summary, loadDetail: loadDetail),
      );

  @override
  State<HoldingDetailScreen> createState() => _HoldingDetailScreenState();
}

class _HoldingDetailScreenState extends State<HoldingDetailScreen> {
  late Future<HoldingDetail> _future = widget.loadDetail(widget.summary.ticker);

  void _retry() =>
      setState(() => _future = widget.loadDetail(widget.summary.ticker));

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    return Scaffold(
      appBar: AppBar(
        title: Text(summary.ticker),
        centerTitle: false,
      ),
      body: FutureBuilder<HoldingDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return _Body(summary: summary, detail: null, loading: true);
          }
          if (snap.hasError) {
            final error = snap.error;
            final notFound = error is ApiException && error.isNotFound;
            return _ErrorState(
              message: notFound
                  ? 'Details for ${summary.ticker} are not available.'
                  : 'Could not load details for ${summary.ticker}.',
              onRetry: notFound ? null : _retry,
            );
          }
          return _Body(summary: summary, detail: snap.data, loading: false);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.summary,
    required this.detail,
    required this.loading,
  });

  final HoldingSummaryArgs summary;
  final HoldingDetail? detail;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = detail;
    final price = d?.price ?? summary.price;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          d?.name ?? summary.name ?? summary.ticker,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (price != null)
          Text('${Fmt.money(price)} per unit',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (_hasPosition) ...[
          _PositionCard(summary: summary, costBasis: d?.costBasisPerShare),
          const SizedBox(height: 12),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (d != null) ...[
          _Section(
            title: 'Price history',
            child: d.priceHistory.isEmpty
                ? const _NoHistory()
                : TimeValueLineChart(
                    series: buildChartSeries(d.priceHistory),
                    height: 200,
                    axisValueFormatter: (v) => Fmt.money(v),
                  ),
          ),
          const SizedBox(height: 12),
          if (d.fiftyTwoWeekLow != null && d.fiftyTwoWeekHigh != null) ...[
            _Section(
              title: '52-week range',
              child: PriceRangeBar(
                low: d.fiftyTwoWeekLow!,
                high: d.fiftyTwoWeekHigh!,
                current: price,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _Section(
            title: 'Details',
            child: Column(
              children: [
                _Row('Cost basis per unit', _moneyOrDash(d.costBasisPerShare)),
                _Row('Purchase date',
                    d.purchaseDate == null ? '—' : Fmt.date(d.purchaseDate!)),
                _Row('Sector', d.sector ?? '—'),
                _Row('Asset class', d.assetClass ?? '—'),
                _Row(
                  'Dividend yield',
                  d.dividendYield == null
                      ? 'None'
                      : Fmt.ratio(d.dividendYield!),
                ),
                if (d.fiftyTwoWeekLow == null || d.fiftyTwoWeekHigh == null)
                  _Row('52-week range', '—'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasPosition =>
      summary.quantity != null ||
      summary.marketValue != null ||
      summary.gainLoss != null;

  static String _moneyOrDash(double? v) => v == null ? '—' : Fmt.money(v);
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.summary, required this.costBasis});

  final HoldingSummaryArgs summary;
  final double? costBasis;

  @override
  Widget build(BuildContext context) {
    final gain = summary.gainLoss;
    final totalCost = (costBasis != null && summary.quantity != null)
        ? costBasis! * summary.quantity!
        : null;
    return _Section(
      title: 'Your position',
      child: Column(
        children: [
          if (summary.quantity != null)
            _Row('Quantity', Fmt.quantity(summary.quantity!)),
          if (summary.marketValue != null)
            _Row('Market value', Fmt.money(summary.marketValue!)),
          if (totalCost != null) _Row('Total cost', Fmt.money(totalCost)),
          if (gain != null)
            _Row(
              'Unrealized gain/loss',
              totalCost != null && totalCost != 0
                  ? '${Fmt.signedMoney(gain)} (${Fmt.signedRatio(gain / totalCost)})'
                  : Fmt.signedMoney(gain),
              valueColor: TrendStyle.color(context, gain),
            ),
          if (summary.weightPercent != null)
            _Row('Portfolio weight',
                '${summary.weightPercent!.toStringAsFixed(2)}%'),
        ],
      ),
    );
  }
}

/// Horizontal low–high bar with a marker at the current price.
class PriceRangeBar extends StatelessWidget {
  const PriceRangeBar({
    super.key,
    required this.low,
    required this.high,
    this.current,
  });

  final double low;
  final double high;
  final double? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final span = high - low;
    final fraction = (current == null || span <= 0)
        ? null
        : ((current! - low) / span).clamp(0.0, 1.0);
    final labelStyle = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 20,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  if (fraction != null)
                    Positioned(
                      left: (width - 14) * fraction,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('Low ${Fmt.money(low)}', style: labelStyle),
            const Spacer(),
            Text('High ${Fmt.money(high)}', style: labelStyle),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHistory extends StatelessWidget {
  const _NoHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.show_chart, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text('No price history available for this holding.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

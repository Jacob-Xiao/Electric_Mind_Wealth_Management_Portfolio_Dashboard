import 'package:flutter/material.dart';

import '../models/portfolio.dart';
import '../utils/formatters.dart';
import '../utils/portfolio_colors.dart';

/// The at-a-glance summary card shown at the top of the overview screen:
/// total market value, today's change, and total return since inception.
class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({super.key, required this.portfolio});

  final Portfolio portfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayColor = valueColor(context, portfolio.dayChangeAmount);
    final returnColor =
        valueColor(context, portfolio.totalReturnSinceInception);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Market Value',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatCurrency(portfolio.totalMarketValue),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: "Today's Change",
                    value: '${formatSignedCurrency(portfolio.dayChangeAmount)} '
                        '(${formatPercentPoints(portfolio.dayChangePercent)})',
                    color: dayColor,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Since Inception',
                    value: formatPercentRatio(
                      portfolio.totalReturnSinceInception,
                    ),
                    color: returnColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

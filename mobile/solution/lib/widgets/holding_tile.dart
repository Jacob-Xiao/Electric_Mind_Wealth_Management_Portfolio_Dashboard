import 'package:flutter/material.dart';

import '../models/holding.dart';
import '../utils/formatters.dart';
import '../utils/portfolio_colors.dart';

/// A single row in the holdings list: ticker/name on the left, market value
/// and gain/loss on the right, with gain/loss colored by sign.
class HoldingTile extends StatelessWidget {
  const HoldingTile({super.key, required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gainColor = valueColor(context, holding.gainLoss);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.ticker,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  holding.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(holding.marketValue),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatSignedCurrency(holding.gainLoss),
                style: theme.textTheme.bodyMedium?.copyWith(color: gainColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// DEMO ONLY — a throwaway stand-in for the Task 2–4 portfolio models and
// repository so Tasks 5–10 can be run and verified before the merge.
// Delete this folder once the real overview screen is wired up.

import '../features/charts/time_series.dart';

class DemoHolding {
  const DemoHolding({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.price,
    required this.marketValue,
    required this.gainLoss,
    required this.weightPercent,
  });

  factory DemoHolding.fromJson(Map<String, dynamic> j) => DemoHolding(
        ticker: j['ticker'] as String,
        name: j['name'] as String? ?? j['ticker'] as String,
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        marketValue: (j['marketValue'] as num?)?.toDouble() ?? 0,
        gainLoss: (j['gainLoss'] as num?)?.toDouble() ?? 0,
        weightPercent: (j['weightPercent'] as num?)?.toDouble() ?? 0,
      );

  final String ticker;
  final String name;
  final double quantity;
  final double price;
  final double marketValue;
  final double gainLoss;
  final double weightPercent;
}

class DemoPortfolio {
  const DemoPortfolio({
    required this.accountId,
    required this.label,
    required this.asOf,
    required this.totalMarketValue,
    required this.dayChangeAmount,
    required this.dayChangePercent,
    required this.totalReturnSinceInception,
    required this.holdings,
    required this.history,
  });

  factory DemoPortfolio.fromJson(Map<String, dynamic> j) {
    final p = j['portfolio'] as Map<String, dynamic>;
    return DemoPortfolio(
      accountId: p['accountId'] as String,
      label: p['label'] as String? ?? p['accountId'] as String,
      asOf: DateTime.tryParse(j['asOf'] as String? ?? ''),
      totalMarketValue: (p['totalMarketValue'] as num).toDouble(),
      dayChangeAmount: (p['dayChangeAmount'] as num).toDouble(),
      dayChangePercent: (p['dayChangePercent'] as num).toDouble(),
      totalReturnSinceInception:
          (p['totalReturnSinceInception'] as num).toDouble(),
      holdings: (j['holdings'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DemoHolding.fromJson)
          .toList(growable: false),
      history: TimeValuePoint.parseList(j['performanceHistory'],
          valueKey: 'marketValue'),
    );
  }

  final String accountId;
  final String label;
  final DateTime? asOf;
  final double totalMarketValue;
  final double dayChangeAmount;
  final double dayChangePercent;
  final double totalReturnSinceInception;
  final List<DemoHolding> holdings;
  final List<TimeValuePoint> history;
}

import 'holding.dart';

/// The portfolio summary plus its holdings, as returned by the mock API's
/// `GET /portfolios/{id}` response.
class Portfolio {
  const Portfolio({
    required this.portfolioId,
    required this.label,
    required this.totalMarketValue,
    required this.dayChangeAmount,
    required this.dayChangePercent,
    required this.totalReturnSinceInception,
    required this.holdings,
    this.asOf,
  });

  final String portfolioId;
  final String label;
  final double totalMarketValue;
  final double dayChangeAmount;
  final double dayChangePercent;
  final double totalReturnSinceInception;
  final List<Holding> holdings;
  final DateTime? asOf;

  bool get isEmpty => holdings.isEmpty;

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final portfolio = json['portfolio'] as Map<String, dynamic>? ?? const {};
    final holdings = (json['holdings'] as List<dynamic>? ?? const [])
        .map((e) => Holding.fromJson(e as Map<String, dynamic>))
        .toList();

    return Portfolio(
      portfolioId: portfolio['portfolioId'] as String? ?? '',
      label: portfolio['label'] as String? ?? '',
      totalMarketValue: _toDouble(portfolio['totalMarketValue']),
      dayChangeAmount: _toDouble(portfolio['dayChangeAmount']),
      dayChangePercent: _toDouble(portfolio['dayChangePercent']),
      totalReturnSinceInception:
          _toDouble(portfolio['totalReturnSinceInception']),
      holdings: holdings,
      asOf: json['asOf'] is String
          ? DateTime.tryParse(json['asOf'] as String)
          : null,
    );
  }

  static double _toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;
}

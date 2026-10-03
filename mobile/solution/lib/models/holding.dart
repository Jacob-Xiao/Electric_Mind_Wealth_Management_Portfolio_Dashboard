/// A single portfolio position (holding).
///
/// Mirrors the `Holding` shape from `mobile/API-CONTRACT.md`. Only the fields
/// the overview screen needs are modelled now; the detail-only fields
/// (`assetClass`, `sector`, `costBasisPerShare`, `dividendYield`, etc.) are
/// added in the Detailed Holding View task.
class Holding {
  const Holding({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.price,
    required this.marketValue,
    required this.weightPercent,
    required this.gainLoss,
  });

  final String ticker;
  final String name;
  final double quantity;
  final double price;
  final double marketValue;
  final double weightPercent;
  final double gainLoss;

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      ticker: json['ticker'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: _toDouble(json['quantity']),
      price: _toDouble(json['price']),
      marketValue: _toDouble(json['marketValue']),
      weightPercent: _toDouble(json['weightPercent']),
      gainLoss: _toDouble(json['gainLoss']),
    );
  }

  static double _toDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'quantity': quantity,
        'price': price,
        'marketValue': marketValue,
        'weightPercent': weightPercent,
        'gainLoss': gainLoss,
      };
}

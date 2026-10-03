import '../charts/time_series.dart';
import '../shared/formatters.dart';

/// `GET /holdings/{ticker}/detail`. Optional fields are nullable so missing or
/// null values render as "—" rather than "null"/"undefined".
class HoldingDetail {
  const HoldingDetail({
    required this.ticker,
    required this.name,
    this.sector,
    this.assetClass,
    this.price,
    this.costBasisPerShare,
    this.purchaseDate,
    this.dividendYield,
    this.fiftyTwoWeekLow,
    this.fiftyTwoWeekHigh,
    this.priceHistory = const [],
  });

  factory HoldingDetail.fromJson(Map<String, dynamic> json) => HoldingDetail(
        ticker: json['ticker'] as String,
        name: (json['name'] as String?) ?? json['ticker'] as String,
        sector: _string(json['sector']),
        assetClass: _string(json['assetClass']),
        price: _num(json['price']),
        costBasisPerShare: _num(json['costBasisPerShare']),
        purchaseDate: Fmt.parseIsoDate(json['purchaseDate'] as String?),
        dividendYield: _num(json['dividendYield']),
        fiftyTwoWeekLow: _num(json['fiftyTwoWeekLow']),
        fiftyTwoWeekHigh: _num(json['fiftyTwoWeekHigh']),
        priceHistory:
            TimeValuePoint.parseList(json['priceHistory'], valueKey: 'price'),
      );

  final String ticker;
  final String name;
  final String? sector;
  final String? assetClass;
  final double? price;
  final double? costBasisPerShare;
  final DateTime? purchaseDate;

  /// Ratio (0.005 = 0.5%). Null means the security pays no dividend.
  final double? dividendYield;
  final double? fiftyTwoWeekLow;
  final double? fiftyTwoWeekHigh;
  final List<TimeValuePoint> priceHistory;

  static double? _num(Object? v) =>
      v is num && v.isFinite ? v.toDouble() : null;

  static String? _string(Object? v) =>
      v is String && v.trim().isNotEmpty ? v : null;
}

/// What the holdings list already knows about a position. Passed into the
/// detail screen so it can show account-specific quantity and gain/loss (the
/// detail endpoint is per-ticker, not per-account) and render a header
/// instantly while details load.
class HoldingSummaryArgs {
  const HoldingSummaryArgs({
    required this.ticker,
    this.name,
    this.quantity,
    this.price,
    this.marketValue,
    this.gainLoss,
    this.weightPercent,
  });

  final String ticker;
  final String? name;
  final double? quantity;
  final double? price;
  final double? marketValue;
  final double? gainLoss;
  final double? weightPercent;
}

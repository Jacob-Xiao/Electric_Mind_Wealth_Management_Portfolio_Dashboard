import 'package:electric_mind_portfolio/models/holding.dart';
import 'package:electric_mind_portfolio/models/portfolio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Portfolio toJson/fromJson round-trips for the local store', () {
    final portfolio = Portfolio(
      portfolioId: 'P-9001',
      label: 'Taxable Brokerage',
      totalMarketValue: 482350.12,
      dayChangeAmount: 1520.44,
      dayChangePercent: 0.32,
      totalReturnSinceInception: 0.187,
      asOf: DateTime.utc(2026, 1, 2, 3, 4, 5),
      holdings: const [
        Holding(
          ticker: 'AAPL',
          name: 'Apple Inc.',
          quantity: 120,
          price: 227.5,
          marketValue: 27300,
          weightPercent: 5.66,
          gainLoss: 3200,
        ),
      ],
    );

    final restored = Portfolio.fromJson(portfolio.toJson());

    expect(restored.portfolioId, 'P-9001');
    expect(restored.label, 'Taxable Brokerage');
    expect(restored.totalMarketValue, closeTo(482350.12, 1e-9));
    expect(restored.dayChangeAmount, closeTo(1520.44, 1e-9));
    expect(restored.dayChangePercent, closeTo(0.32, 1e-9));
    expect(restored.totalReturnSinceInception, closeTo(0.187, 1e-9));
    expect(restored.asOf, DateTime.utc(2026, 1, 2, 3, 4, 5));
    expect(restored.holdings, hasLength(1));
    expect(restored.holdings.first.ticker, 'AAPL');
    expect(restored.holdings.first.marketValue, closeTo(27300, 1e-9));
    expect(restored.holdings.first.gainLoss, closeTo(3200, 1e-9));
  });
}

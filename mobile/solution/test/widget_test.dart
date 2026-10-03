import 'package:electric_mind_portfolio/main.dart';
import 'package:electric_mind_portfolio/models/holding.dart';
import 'package:electric_mind_portfolio/models/portfolio.dart';
import 'package:electric_mind_portfolio/screens/portfolio_overview_screen.dart';
import 'package:electric_mind_portfolio/services/portfolio_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements PortfolioRepository {
  _FakeRepository(this._portfolio);

  final Portfolio _portfolio;
  int calls = 0;

  @override
  Future<Portfolio> fetchPortfolio(String portfolioId) async {
    calls++;
    return _portfolio;
  }
}

const _aapl = Holding(
  ticker: 'AAPL',
  name: 'Apple Inc.',
  quantity: 120,
  price: 227.50,
  marketValue: 27300.00,
  weightPercent: 5.66,
  gainLoss: 3200.00,
);

const _bnd = Holding(
  ticker: 'BND',
  name: 'Vanguard Total Bond ETF',
  quantity: 300,
  price: 72.10,
  marketValue: 21630.00,
  weightPercent: 4.48,
  gainLoss: -410.50,
);

Portfolio _portfolio({
  double marketValue = 482350.12,
  double dayAmount = 1520.44,
  double dayPercent = 0.32,
  double returnSince = 0.187,
  List<Holding>? holdings,
}) {
  return Portfolio(
    portfolioId: 'P-9001',
    label: 'Taxable Brokerage',
    totalMarketValue: marketValue,
    dayChangeAmount: dayAmount,
    dayChangePercent: dayPercent,
    totalReturnSinceInception: returnSince,
    holdings: holdings ?? const [_aapl, _bnd],
  );
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('app boots and renders header + summary from sample data',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(PortfolioApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('ELECTRIC MIND'), findsOneWidget);
    expect(find.text('Portfolio Overview'), findsOneWidget);
    expect(find.text('Total Market Value'), findsOneWidget);
    expect(find.text(r'$482,350.12'), findsOneWidget);
  });

  testWidgets('holdings list shows ticker/name, market value and gain/loss',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(_wrap(PortfolioOverviewScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('AAPL'), findsOneWidget);
    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(find.text(r'$27,300.00'), findsOneWidget);
    expect(find.text(r'+$3,200.00'), findsOneWidget);
    expect(find.text(r'-$410.50'), findsOneWidget);
  });

  testWidgets('empty holdings shows a graceful message but keeps the summary',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio(
      marketValue: 0,
      dayAmount: 0,
      dayPercent: 0,
      returnSince: 0,
      holdings: const [],
    ));
    await tester.pumpWidget(_wrap(PortfolioOverviewScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('No holdings to display'), findsOneWidget);
    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text('Total Market Value'), findsOneWidget);
  });

  testWidgets('zero day change is formatted neutrally',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio(dayAmount: 0, dayPercent: 0));
    await tester.pumpWidget(_wrap(PortfolioOverviewScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text(r'$0.00 (0.00%)'), findsOneWidget);
  });

  testWidgets('large holdings list (60) renders lazily and scrolls',
      (WidgetTester tester) async {
    final holdings = List<Holding>.generate(
      60,
      (i) => Holding(
        ticker: 'DEMO${i + 1}',
        name: 'Holding ${i + 1}',
        quantity: 1,
        price: 10,
        marketValue: 10,
        weightPercent: 0,
        gainLoss: 0,
      ),
    );
    final repo = _FakeRepository(_portfolio(holdings: holdings));
    await tester.pumpWidget(_wrap(PortfolioOverviewScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('DEMO1'), findsOneWidget);
    // Lazy list: the last item is not built until scrolled to.
    expect(find.text('DEMO60'), findsNothing);
    await tester.scrollUntilVisible(find.text('DEMO60'), 400);
    expect(find.text('DEMO60'), findsOneWidget);
  });

  testWidgets('pull-to-refresh re-fetches data', (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(_wrap(PortfolioOverviewScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);

    await tester.fling(
        find.byType(CustomScrollView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
  });
}

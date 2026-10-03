import 'dart:async';

import 'package:electric_mind_portfolio/main.dart';
import 'package:electric_mind_portfolio/models/holding.dart';
import 'package:electric_mind_portfolio/models/portfolio.dart';
import 'package:electric_mind_portfolio/screens/portfolio_overview_screen.dart';
import 'package:electric_mind_portfolio/services/connectivity_service.dart';
import 'package:electric_mind_portfolio/services/portfolio_repository.dart';
import 'package:electric_mind_portfolio/services/portfolio_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---- Fakes ---------------------------------------------------------------

class _FakeRepository implements PortfolioRepository {
  _FakeRepository(this.portfolio);

  Portfolio portfolio;
  int calls = 0;
  bool fail = false;
  Completer<Portfolio>? gate;

  @override
  Future<Portfolio> fetchPortfolio(String portfolioId) {
    calls++;
    if (fail) return Future.error(Exception('network down'));
    if (gate != null) return gate!.future;
    return Future.value(portfolio);
  }
}

class _FakeStore implements PortfolioStore {
  final Map<String, CachedPortfolio> data = {};
  int reads = 0;
  int writes = 0;

  void seed(String id, Portfolio portfolio, {DateTime? cachedAt}) {
    data[id] = CachedPortfolio(
      portfolio: portfolio,
      cachedAt: cachedAt ?? DateTime.now(),
    );
  }

  @override
  Future<CachedPortfolio?> read(String portfolioId) async {
    reads++;
    return data[portfolioId];
  }

  @override
  Future<void> write(String portfolioId, Portfolio portfolio,
      {DateTime? cachedAt}) async {
    writes++;
    data[portfolioId] = CachedPortfolio(
      portfolio: portfolio,
      cachedAt: cachedAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> clear() async => data.clear();
}

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({bool online = true}) : _online = online;

  final _controller = StreamController<bool>.broadcast();
  bool _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  @override
  Future<bool> get currentOnline async => _online;

  void emit(bool online) {
    _online = online;
    _controller.add(online);
  }
}

// ---- Fixtures ------------------------------------------------------------

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

Widget _screen({
  required PortfolioRepository repository,
  PortfolioStore? store,
  ConnectivityService? connectivity,
}) {
  return MaterialApp(
    home: PortfolioOverviewScreen(
      repository: repository,
      store: store ?? _FakeStore(),
      connectivity: connectivity ?? _FakeConnectivity(),
    ),
  );
}

// ---- Tests ---------------------------------------------------------------

void main() {
  testWidgets('app boots and renders header + summary from sample data',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(PortfolioApp(
      repository: repo,
      store: _FakeStore(),
      connectivity: _FakeConnectivity(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ELECTRIC MIND'), findsOneWidget);
    expect(find.text('Portfolio Overview'), findsOneWidget);
    expect(find.text('Total Market Value'), findsOneWidget);
    expect(find.text(r'$482,350.12'), findsOneWidget);
  });

  testWidgets('holdings list shows ticker/name, market value and gain/loss',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(_screen(repository: repo));
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
    await tester.pumpWidget(_screen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('No holdings to display'), findsOneWidget);
    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text('Total Market Value'), findsOneWidget);
  });

  testWidgets('zero day change is formatted neutrally',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio(dayAmount: 0, dayPercent: 0));
    await tester.pumpWidget(_screen(repository: repo));
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
    await tester.pumpWidget(_screen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('DEMO1'), findsOneWidget);
    expect(find.text('DEMO60'), findsNothing);
    await tester.scrollUntilVisible(find.text('DEMO60'), 400);
    expect(find.text('DEMO60'), findsOneWidget);
  });

  testWidgets('pull-to-refresh re-fetches data', (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(_screen(repository: repo));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);

    await tester.fling(
        find.byType(CustomScrollView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
  });

  testWidgets('Task 3: renders cached data immediately, then refreshes + persists',
      (WidgetTester tester) async {
    final store = _FakeStore()
      ..seed(
        'P-9001',
        _portfolio(marketValue: 100000),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
    final repo = _FakeRepository(_portfolio(marketValue: 200000))
      ..gate = Completer<Portfolio>();

    await tester.pumpWidget(_screen(repository: repo, store: store));
    await tester.pump(); // let the cache read complete

    // Cached value is shown before the network result arrives.
    expect(find.text(r'$100,000.00'), findsOneWidget);
    expect(find.text(r'$200,000.00'), findsNothing);

    repo.gate!.complete(_portfolio(marketValue: 200000));
    await tester.pumpAndSettle();

    expect(find.text(r'$200,000.00'), findsOneWidget);
    expect(store.writes, 1);
  });

  testWidgets('Task 3: first launch with no cache fetches and persists',
      (WidgetTester tester) async {
    final store = _FakeStore();
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(_screen(repository: repo, store: store));
    await tester.pumpAndSettle();

    expect(find.text(r'$482,350.12'), findsOneWidget);
    expect(store.writes, 1);
  });

  testWidgets('Task 4: offline with cache shows banner + staleness',
      (WidgetTester tester) async {
    final store = _FakeStore()
      ..seed(
        'P-9001',
        _portfolio(marketValue: 100000),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(_screen(
      repository: repo,
      store: store,
      connectivity: _FakeConnectivity(online: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Offline — showing cached data'), findsOneWidget);
    expect(find.textContaining('Prices as of'), findsOneWidget);
    expect(find.text(r'$100,000.00'), findsOneWidget);
    expect(repo.calls, 0); // no network call while offline
  });

  testWidgets('Task 4: offline with no cache shows a distinct first-load state',
      (WidgetTester tester) async {
    final repo = _FakeRepository(_portfolio());
    await tester.pumpWidget(_screen(
      repository: repo,
      store: _FakeStore(),
      connectivity: _FakeConnectivity(online: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Offline — showing cached data'), findsNothing);
  });

  testWidgets('Task 4: reconnect auto re-fetches and clears the banner',
      (WidgetTester tester) async {
    final store = _FakeStore()..seed('P-9001', _portfolio(marketValue: 100000));
    final repo = _FakeRepository(_portfolio(marketValue: 300000));
    final connectivity = _FakeConnectivity(online: false);

    await tester.pumpWidget(_screen(
      repository: repo,
      store: store,
      connectivity: connectivity,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Offline — showing cached data'), findsOneWidget);
    expect(repo.calls, 0);

    connectivity.emit(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Offline — showing cached data'), findsNothing);
    expect(repo.calls, 1);
    expect(find.text(r'$300,000.00'), findsOneWidget);
  });

  testWidgets('Task 4: rapid flapping collapses to a single fetch',
      (WidgetTester tester) async {
    final store = _FakeStore()..seed('P-9001', _portfolio(marketValue: 100000));
    final repo = _FakeRepository(_portfolio(marketValue: 400000));
    final connectivity = _FakeConnectivity(online: false);

    await tester.pumpWidget(_screen(
      repository: repo,
      store: store,
      connectivity: connectivity,
    ));
    await tester.pumpAndSettle();

    connectivity.emit(false);
    connectivity.emit(true);
    connectivity.emit(false);
    connectivity.emit(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(repo.calls, 1);
  });
}

import 'dart:convert';

import 'package:electric_mind_portfolio/features/holding_detail/holding_detail.dart';
import 'package:electric_mind_portfolio/features/holding_detail/holding_detail_screen.dart';
import 'package:electric_mind_portfolio/features/shared/feature_api_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _aapl = {
  'ticker': 'AAPL',
  'name': 'Apple Inc.',
  'sector': 'Technology',
  'assetClass': 'Equity',
  'price': 227.5,
  'costBasisPerShare': 158.75,
  'purchaseDate': '2022-03-14',
  'dividendYield': 0.005,
  'fiftyTwoWeekLow': 164.10,
  'fiftyTwoWeekHigh': 232.40,
  'priceHistory': [
    {'date': '2025-01-01', 'price': 195.20},
    {'date': '2025-02-01', 'price': 210.75},
  ],
};

// Mirrors the mock API's CASH holding: null dividend, no price history.
const _cash = {
  'ticker': 'CASH',
  'name': 'Canadian Dollar Cash',
  'sector': 'Cash',
  'assetClass': 'Cash',
  'price': 1,
  'costBasisPerShare': 1,
  'purchaseDate': '2022-03-14',
  'dividendYield': null,
  'fiftyTwoWeekLow': 0.8,
  'fiftyTwoWeekHigh': 1.1,
  'priceHistory': <Object>[],
};

FeatureApiClient apiReturning(Map<String, Object> byTicker) => FeatureApiClient(
      config: const FeatureApiConfig(baseUrl: 'http://test'),
      httpClient: MockClient((req) async {
        final ticker = req.url.pathSegments[1];
        final body = byTicker[ticker];
        if (body == null) {
          return http.Response(
              jsonEncode({'error': 'not_found', 'message': 'No such holding'}),
              404);
        }
        return http.Response(jsonEncode(body), 200);
      }),
    );

void main() {
  final api = apiReturning({'AAPL': _aapl, 'CASH': _cash});

  Future<void> open(WidgetTester tester, HoldingSummaryArgs args) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
                HoldingDetailScreen.route(
                    summary: args, loadDetail: api.getHoldingDetail)),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    // MockClient completes on a real timer.
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  test('parses the detail payload, including null dividend', () {
    final d = HoldingDetail.fromJson(_cash);
    expect(d.dividendYield, isNull);
    expect(d.priceHistory, isEmpty);
    expect(HoldingDetail.fromJson(_aapl).priceHistory.length, 2);
  });

  testWidgets('shows data not in the holdings list', (tester) async {
    await open(
        tester,
        const HoldingSummaryArgs(
            ticker: 'AAPL',
            name: 'Apple Inc.',
            quantity: 120,
            marketValue: 27300,
            gainLoss: 8250));

    expect(find.text('AAPL'), findsOneWidget); // app bar
    expect(find.text('120'), findsOneWidget); // account-specific quantity
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Asset class'), 200);
    expect(find.text(r'$158.75'), findsOneWidget); // cost basis
    expect(find.text('Mar 14, 2022'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
    expect(find.text('0.50%'), findsOneWidget);
    expect(find.text(r'Low $164.10'), findsOneWidget);
    expect(find.text(r'High $232.40'), findsOneWidget);
  });

  testWidgets('null dividend and empty history render gracefully',
      (tester) async {
    await open(tester, const HoldingSummaryArgs(ticker: 'CASH'));
    await tester.scrollUntilVisible(find.text('Dividend yield'), 200);
    expect(find.text('None'), findsOneWidget); // dividend yield
    expect(find.textContaining('null'), findsNothing);
    expect(find.textContaining('undefined'), findsNothing);
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('No price history available for this holding.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown ticker shows a not-available message', (tester) async {
    await open(tester, const HoldingSummaryArgs(ticker: 'ZZZZ'));
    expect(find.text('Details for ZZZZ are not available.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('back returns to the list', (tester) async {
    await open(tester, const HoldingSummaryArgs(ticker: 'AAPL'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}

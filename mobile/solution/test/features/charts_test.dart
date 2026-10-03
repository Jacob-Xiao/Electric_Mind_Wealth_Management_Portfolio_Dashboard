import 'package:electric_mind_portfolio/features/charts/portfolio_value_chart_card.dart';
import 'package:electric_mind_portfolio/features/charts/time_series.dart';
import 'package:electric_mind_portfolio/features/charts/time_value_line_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<TimeValuePoint> daily(int n, {DateTime? start, double base = 400000}) {
  final s = start ?? DateTime.utc(2025, 1, 1);
  return [
    for (var i = 0; i < n; i++)
      TimeValuePoint(s.add(Duration(days: i)), base + i * 1000.0),
  ];
}

Widget host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 390, child: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('TimeValuePoint.parseList', () {
    test('sorts, drops malformed rows and de-duplicates dates', () {
      final points = TimeValuePoint.parseList([
        {'date': '2025-03-01', 'marketValue': 418200.0},
        {'date': '2025-01-01', 'marketValue': 410000.0},
        {'date': 'not-a-date', 'marketValue': 1},
        {'date': '2025-02-01', 'marketValue': null},
        {'date': '2025-01-01', 'marketValue': 411000.0},
        'junk',
      ], valueKey: 'marketValue');
      expect(points.map((p) => p.value), [411000.0, 418200.0]);
    });

    test('non-list input yields empty', () {
      expect(TimeValuePoint.parseList(null, valueKey: 'price'), isEmpty);
    });
  });

  group('buildChartSeries', () {
    test('task sample (monthly) has no gaps', () {
      final s = buildChartSeries([
        TimeValuePoint(DateTime.utc(2025, 1, 1), 410000),
        TimeValuePoint(DateTime.utc(2025, 2, 1), 423500),
        TimeValuePoint(DateTime.utc(2025, 3, 1), 418200),
      ]);
      expect(s.hasGaps, isFalse);
      expect(s.spots.where((p) => p.isNull()), isEmpty);
    });

    test('breaks the line at missing dates instead of interpolating', () {
      // Like the mock "gaps" scenario: 4 days present, 3 missing.
      final dates = <DateTime>[];
      var d = DateTime.utc(2025, 8, 29);
      for (var week = 0; week < 4; week++) {
        for (var i = 0; i < 4; i++) {
          dates.add(d);
          d = d.add(const Duration(days: 1));
        }
        d = d.add(const Duration(days: 3));
      }
      final s = buildChartSeries(
          [for (final date in dates) TimeValuePoint(date, 1000)]);
      expect(s.gapCount, 3);
      expect(s.spots.where((p) => p.isNull()).length, 3);
      expect(s.spots.where((p) => p.isNotNull()).length, dates.length);
    });

    test('one point gets a padded, non-degenerate range', () {
      final s = buildChartSeries(
          [TimeValuePoint(DateTime.utc(2026, 10, 3), 65680)]);
      expect(s.maxX, greaterThan(s.minX));
      expect(s.maxY, greaterThan(s.minY));
    });

    test('flat series gets vertical padding', () {
      final s = buildChartSeries(daily(5, base: 100).map(
          (p) => TimeValuePoint(p.date, 100)).toList());
      expect(s.maxY, greaterThan(s.minY));
    });
  });

  test('ChartRange keeps only the trailing window', () {
    final points = daily(400);
    expect(ChartRange.oneMonth.apply(points).length, 32);
    expect(ChartRange.all.apply(points).length, 400);
  });

  group('PortfolioValueChartCard', () {
    testWidgets('renders 1 point with explanation', (tester) async {
      await tester.pumpWidget(host(PortfolioValueChartCard(
          history: [TimeValuePoint(DateTime.utc(2026, 10, 3), 65680)])));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.textContaining('Only one data point'), findsOneWidget);
      expect(find.byType(SegmentedButton<ChartRange>), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 2 points', (tester) async {
      await tester.pumpWidget(host(PortfolioValueChartCard(history: [
        TimeValuePoint(DateTime.utc(2025, 1, 1), 410000),
        TimeValuePoint(DateTime.utc(2025, 2, 1), 423500),
      ])));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text(r'$423,500.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty history shows placeholder, not a broken chart',
        (tester) async {
      await tester
          .pumpWidget(host(const PortfolioValueChartCard(history: [])));
      expect(find.byType(LineChart), findsNothing);
      expect(find.textContaining('No value history'), findsOneWidget);
    });

    testWidgets('dragging across a long series shows the touched point',
        (tester) async {
      final history = daily(401);
      await tester.pumpWidget(host(PortfolioValueChartCard(
          history: history, initialRange: ChartRange.all)));
      await tester.pumpAndSettle();
      expect(find.text(r'$800,000.00'), findsOneWidget); // latest value

      final chart = find.byType(TimeValueLineChart);
      final gesture = await tester.startGesture(tester.getCenter(chart));
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(-10, 0));
        await tester.pump();
      }
      // Header switched from "as of <date>" to the touched point.
      expect(find.text(r'$800,000.00'), findsNothing);
      expect(find.textContaining('as of'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(r'$800,000.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching range rebuilds the chart', (tester) async {
      await tester.pumpWidget(host(PortfolioValueChartCard(history: daily(401))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1Y'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

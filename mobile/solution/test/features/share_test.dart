import 'package:electric_mind_portfolio/features/share/portfolio_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

const _sample = PortfolioShareSnapshot(
  accountLabel: 'Taxable Brokerage',
  totalMarketValue: 482350.12,
  dayChangeAmount: 1520.44,
  dayChangePercent: 0.32,
  totalReturnSinceInception: 0.187,
);

void main() {
  group('buildPortfolioShareText', () {
    test('positive day', () {
      expect(
        buildPortfolioShareText(_sample),
        'My Taxable Brokerage portfolio: \$482,350.12 CAD\n'
        'Today: up \$1,520.44 (+0.32%)\n'
        'Total return since inception: +18.70%',
      );
    });

    test('negative day and negative return', () {
      final text = buildPortfolioShareText(const PortfolioShareSnapshot(
        totalMarketValue: 1000,
        dayChangeAmount: -12.5,
        dayChangePercent: -1.23,
        totalReturnSinceInception: -0.05,
      ));
      expect(text, contains('My portfolio: \$1,000.00 CAD'));
      expect(text, contains('Today: down \$12.50 (−1.23%)'));
      expect(text, contains('Total return since inception: −5.00%'));
    });

    test('zero day change is neutral', () {
      final text = buildPortfolioShareText(const PortfolioShareSnapshot(
        totalMarketValue: 1000,
        dayChangeAmount: 0,
        dayChangePercent: 0,
        totalReturnSinceInception: 0,
      ));
      expect(text, contains('Today: unchanged (0.00%)'));
    });

    test('contains nothing beyond the summary', () {
      final text = buildPortfolioShareText(_sample);
      expect(text, isNot(contains('P-9001')));
      expect(text.split('\n').length, 3);
    });
  });

  group('SharePortfolioButton', () {
    Widget host(Widget button) =>
        MaterialApp(home: Scaffold(appBar: AppBar(actions: [button])));

    testWidgets('passes formatted text; dismissal leaves UI usable',
        (tester) async {
      final calls = <ShareParams>[];
      await tester.pumpWidget(host(SharePortfolioButton(
        snapshot: _sample,
        launcher: (p) async {
          calls.add(p);
          return const ShareResult('', ShareResultStatus.dismissed);
        },
      )));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(calls.single.text, buildPortfolioShareText(_sample));
      expect(find.byType(SnackBar), findsNothing);

      // Button is enabled again and can be used a second time.
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(calls.length, 2);
    });

    testWidgets('platform error shows a message instead of crashing',
        (tester) async {
      await tester.pumpWidget(host(SharePortfolioButton(
        snapshot: _sample,
        launcher: (_) async => throw PlatformException(code: 'boom'),
      )));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Could not open the share sheet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled until data is loaded', (tester) async {
      await tester.pumpWidget(host(const SharePortfolioButton(snapshot: null)));
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });
  });
}

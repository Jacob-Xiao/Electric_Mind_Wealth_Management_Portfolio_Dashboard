import 'dart:async';

import 'package:electric_mind_portfolio/features/accounts/account.dart';
import 'package:electric_mind_portfolio/features/accounts/account_selection_controller.dart';
import 'package:electric_mind_portfolio/features/accounts/account_switcher.dart';
import 'package:electric_mind_portfolio/features/notifications/deep_link_bus.dart';
import 'package:electric_mind_portfolio/features/notifications/deep_link_handler.dart';
import 'package:electric_mind_portfolio/features/notifications/portfolio_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const taxable = Account(
    accountId: 'P-9001', label: 'Taxable Brokerage', totalMarketValue: 482350.12);
const ira = Account(
    accountId: 'P-9002', label: 'Traditional IRA', totalMarketValue: 215600);

AccountSelectionController controllerWith(List<Account> accounts) =>
    AccountSelectionController(loader: () async => accounts);

void main() {
  group('AccountSelectionController', () {
    test('defaults to first account and switches', () async {
      final c = controllerWith([taxable, ira]);
      await c.load();
      expect(c.selectedAccountId, 'P-9001');
      c.select('P-9002');
      expect(c.selectedAccount, ira);
      c.select('nope');
      expect(c.selectedAccount, ira, reason: 'unknown IDs are ignored');
    });

    test('keeps selection across reloads when still present', () async {
      final c = controllerWith([taxable, ira]);
      await c.load();
      c.select('P-9002');
      await c.load();
      expect(c.selectedAccountId, 'P-9002');
    });

    test('deep link to existing account selects it', () async {
      final c = controllerWith([taxable, ira]);
      await c.load();
      final r = await c.requestAccount('P-9002');
      expect(r.fellBack, isFalse);
      expect(c.selectedAccountId, 'P-9002');
    });

    test('deep link to unknown account falls back to default', () async {
      final c = controllerWith([taxable, ira]);
      await c.load();
      c.select('P-9002');
      final r = await c.requestAccount('P-UNKNOWN');
      expect(r.fellBack, isTrue);
      expect(r.selected, taxable);
      expect(c.selectedAccountId, 'P-9001');
    });

    test('deep link before accounts load waits for them (cold start)',
        () async {
      final gate = Completer<List<Account>>();
      final c = AccountSelectionController(loader: () => gate.future);
      final pending = c.requestAccount('P-9002');
      gate.complete([taxable, ira]);
      final r = await pending;
      expect(r.selected, ira);
      expect(c.selectedAccountId, 'P-9002');
    });

    test('deep link when accounts fail to load completes with null', () async {
      final c = AccountSelectionController(
          loader: () async => throw Exception('offline'));
      final r = await c.requestAccount('P-9002');
      expect(r.selected, isNull);
    });
  });

  group('PortfolioNotificationPayload.tryParse', () {
    test('parses the fixture shape', () {
      final p = PortfolioNotificationPayload.tryParse(
          '{"title":"Portfolio Alert","body":"Your portfolio is up 2.1% today",'
          '"data":{"portfolioId":"P-9001","type":"portfolio_alert"}}');
      expect(p?.portfolioId, 'P-9001');
      expect(p?.body, 'Your portfolio is up 2.1% today');
    });

    test('round-trips encode()', () {
      const p = MockNotifications.unknownPortfolio;
      expect(PortfolioNotificationPayload.tryParse(p.encode()), p);
    });

    test('rejects malformed payloads without throwing', () {
      for (final raw in [
        null,
        '',
        'not json',
        '[]',
        '{"data":{}}',
        '{"data":{"portfolioId":""}}',
        '{"data":{"portfolioId":42}}',
      ]) {
        expect(PortfolioNotificationPayload.tryParse(raw), isNull,
            reason: raw);
      }
    });
  });

  group('AccountSwitcher', () {
    testWidgets('single account renders a plain label, no picker',
        (tester) async {
      final c = controllerWith([taxable]);
      await c.load();
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: AccountSwitcher(controller: c))));
      expect(find.text('Taxable Brokerage'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('multiple accounts: bottom sheet switches account',
        (tester) async {
      final c = controllerWith([taxable, ira]);
      await c.load();
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: AccountSwitcher(controller: c))));
      await tester.tap(find.text('Taxable Brokerage'));
      await tester.pumpAndSettle();
      expect(find.text('Switch account'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

      await tester.tap(find.text('Traditional IRA'));
      await tester.pumpAndSettle();
      expect(find.text('Switch account'), findsNothing);
      expect(c.selectedAccountId, 'P-9002');
      expect(find.text('Traditional IRA'), findsOneWidget);
    });
  });

  group('DeepLinkHandler', () {
    Widget app(DeepLinkBus bus, AccountSelectionController c) => MaterialApp(
          home: DeepLinkHandler(
            deepLinks: bus,
            accounts: c,
            child: Builder(
              builder: (context) => Scaffold(
                body: ListenableBuilder(
                  listenable: c,
                  builder: (_, __) => Column(children: [
                    Text('selected:${c.selectedAccountId}'),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const Scaffold(body: Text('DETAIL')))),
                      child: const Text('open detail'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );

    testWidgets('cold start: queued tap is applied after first frame',
        (tester) async {
      final bus = DeepLinkBus()..push(MockNotifications.validPortfolio);
      final c = controllerWith([taxable, ira]);
      await tester.pumpWidget(app(bus, c));
      await tester.pumpAndSettle();
      expect(find.text('selected:P-9002'), findsOneWidget);
      expect(find.text('Opened Traditional IRA'), findsOneWidget);
      expect(bus.pending, isNull);
    });

    testWidgets('background/foreground tap pops to overview and switches',
        (tester) async {
      final bus = DeepLinkBus();
      final c = controllerWith([taxable, ira]);
      await c.load();
      await tester.pumpWidget(app(bus, c));
      await tester.tap(find.text('open detail'));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL'), findsOneWidget);

      bus.push(MockNotifications.validPortfolio);
      await tester.pumpAndSettle();
      expect(find.text('DETAIL'), findsNothing);
      expect(find.text('selected:P-9002'), findsOneWidget);
    });

    testWidgets('unknown portfolio falls back gracefully', (tester) async {
      final bus = DeepLinkBus();
      final c = controllerWith([taxable, ira]);
      await c.load();
      c.select('P-9002');
      await tester.pumpWidget(app(bus, c));

      bus.push(MockNotifications.unknownPortfolio);
      await tester.pumpAndSettle();
      expect(find.text('selected:P-9001'), findsOneWidget);
      expect(find.textContaining("P-UNKNOWN isn't available"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

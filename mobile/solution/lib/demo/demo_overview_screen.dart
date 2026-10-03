// DEMO ONLY — a minimal stand-in for the Task 2 Core Portfolio Screen that
// hosts the Task 5–10 features so they can be exercised end to end.
// After the merge, move the marked feature widgets into the real screen and
// delete this file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../features/accounts/account_switcher.dart';
import '../features/charts/portfolio_value_chart_card.dart';
import '../features/holding_detail/holding_detail.dart';
import '../features/holding_detail/holding_detail_screen.dart';
import '../features/notifications/portfolio_notification.dart';
import '../features/portfolio_features.dart';
import '../features/share/portfolio_share.dart';
import '../features/shared/formatters.dart';
import 'demo_portfolio.dart';

class DemoOverviewScreen extends StatefulWidget {
  const DemoOverviewScreen({super.key});

  @override
  State<DemoOverviewScreen> createState() => _DemoOverviewScreenState();
}

class _DemoOverviewScreenState extends State<DemoOverviewScreen> {
  late final PortfolioFeatures _features = PortfolioFeatures.read(context);

  // Per-account cache so switching accounts is instant (Task 8: no full
  // screen reload/flash). The real app would read Task 3's local store here.
  final Map<String, DemoPortfolio> _cache = {};
  final Map<String, Future<void>> _inFlight = {};
  final Map<String, Object> _errors = {};
  String? _shownAccountId;

  @override
  void initState() {
    super.initState();
    _features.accounts.addListener(_onAccountsChanged);
    unawaited(_features.accounts.load());
  }

  @override
  void dispose() {
    _features.accounts.removeListener(_onAccountsChanged);
    super.dispose();
  }

  void _onAccountsChanged() {
    final accounts = _features.accounts;
    final selected = accounts.selectedAccountId;
    if (selected != null && selected != _shownAccountId) {
      _shownAccountId = selected;
      unawaited(_fetch(selected));
      // Warm the cache for the other accounts so a switch is instant.
      for (final a in accounts.accounts) {
        if (a.accountId != selected && !_cache.containsKey(a.accountId)) {
          unawaited(_fetch(a.accountId));
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _fetch(String accountId) {
    return _inFlight[accountId] ??= () async {
      try {
        final json = await _features.api.getPortfolioJson(accountId);
        _cache[accountId] = DemoPortfolio.fromJson(json);
        _errors.remove(accountId);
      } catch (e) {
        _errors[accountId] = e;
      } finally {
        _inFlight.remove(accountId);
        if (mounted) setState(() {});
      }
    }();
  }

  Future<void> _refresh() async {
    await _features.accounts.load();
    final id = _features.accounts.selectedAccountId;
    if (id != null) await _fetch(id);
  }

  Future<void> _simulatePush(PortfolioNotificationPayload payload,
      {Duration delay = Duration.zero}) async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await _features.notifications.requestPermission();
    if (!granted) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Notifications are disabled for this app.')));
      return;
    }
    if (delay > Duration.zero) {
      messenger.showSnackBar(SnackBar(
          content: Text('Notification in ${delay.inSeconds}s — background '
              'the app now to test that path.')));
      await Future<void>.delayed(delay);
    }
    await _features.notifications.showMockPush(payload);
  }

  @override
  Widget build(BuildContext context) {
    final accountId = _features.accounts.selectedAccountId;
    final portfolio = accountId == null ? null : _cache[accountId];
    final loading = accountId != null && _inFlight.containsKey(accountId);
    final error = accountId == null ? null : _errors[accountId];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Overview'),
        actions: [
          // ── Task 7 ──────────────────────────────────────────────────────
          SharePortfolioButton(
            snapshot: portfolio == null
                ? null
                : PortfolioShareSnapshot(
                    accountLabel: portfolio.label,
                    totalMarketValue: portfolio.totalMarketValue,
                    dayChangeAmount: portfolio.dayChangeAmount,
                    dayChangePercent: portfolio.dayChangePercent,
                    totalReturnSinceInception:
                        portfolio.totalReturnSinceInception,
                    asOf: portfolio.asOf,
                  ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Developer tools',
            onSelected: (v) => switch (v) {
              'push' => _simulatePush(MockNotifications.validPortfolio),
              'push-delay' => _simulatePush(MockNotifications.validPortfolio,
                  delay: const Duration(seconds: 5)),
              'push-unknown' =>
                _simulatePush(MockNotifications.unknownPortfolio),
              'lock' => _features.auth.lock(),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'push', child: Text('Simulate push → P-9002')),
              PopupMenuItem(
                  value: 'push-delay',
                  child: Text('Simulate push in 5 s → P-9002')),
              PopupMenuItem(
                  value: 'push-unknown',
                  child: Text('Simulate push → unknown portfolio')),
              PopupMenuItem(value: 'lock', child: Text('Lock app now')),
            ],
          ),
        ],
        bottom: loading && portfolio != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          key: const PageStorageKey('demo-overview-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              // ── Task 8 ────────────────────────────────────────────────────
              sliver: SliverToBoxAdapter(
                child: AccountSwitcher(controller: _features.accounts),
              ),
            ),
            if (portfolio == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: error != null && !loading
                      ? Text('Could not load portfolio.\n$error',
                          textAlign: TextAlign.center)
                      : const CircularProgressIndicator(),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                    child: _DemoSummaryCard(portfolio: portfolio)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                // ── Task 10 ─────────────────────────────────────────────────
                sliver: SliverToBoxAdapter(
                  child: PortfolioValueChartCard(
                    key: ValueKey('chart-${portfolio.accountId}'),
                    history: portfolio.history,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text('Holdings (${portfolio.holdings.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              if (portfolio.holdings.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No holdings to display')),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: portfolio.holdings.length,
                  itemBuilder: (context, i) =>
                      _DemoHoldingTile(holding: portfolio.holdings[i]),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DemoSummaryCard extends StatelessWidget {
  const _DemoSummaryCard({required this.portfolio});

  final DemoPortfolio portfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayColor = TrendStyle.color(context, portfolio.dayChangeAmount);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total market value', style: theme.textTheme.labelLarge),
            Text(Fmt.money(portfolio.totalMarketValue),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              'Today ${Fmt.signedMoney(portfolio.dayChangeAmount)} '
              '(${Fmt.signedPercentPoints(portfolio.dayChangePercent)})',
              style: theme.textTheme.bodyMedium?.copyWith(color: dayColor),
            ),
            Text(
              'Since inception ${Fmt.signedRatio(portfolio.totalReturnSinceInception)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: TrendStyle.color(
                      context, portfolio.totalReturnSinceInception)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoHoldingTile extends StatelessWidget {
  const _DemoHoldingTile({required this.holding});

  final DemoHolding holding;

  @override
  Widget build(BuildContext context) {
    final features = PortfolioFeatures.of(context);
    return ListTile(
      title: Text(holding.ticker),
      subtitle: Text(holding.name, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Fmt.money(holding.marketValue)),
          Text(Fmt.signedMoney(holding.gainLoss),
              style: TextStyle(
                  color: TrendStyle.color(context, holding.gainLoss))),
        ],
      ),
      // ── Task 9 ──────────────────────────────────────────────────────────
      onTap: () => Navigator.of(context).push(HoldingDetailScreen.route(
        summary: HoldingSummaryArgs(
          ticker: holding.ticker,
          name: holding.name,
          quantity: holding.quantity,
          price: holding.price,
          marketValue: holding.marketValue,
          gainLoss: holding.gainLoss,
          weightPercent: holding.weightPercent,
        ),
        loadDetail: features.api.getHoldingDetail,
      )),
    );
  }
}

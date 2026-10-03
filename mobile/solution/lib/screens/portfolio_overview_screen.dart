import 'dart:async';

import 'package:flutter/material.dart';

import '../models/portfolio.dart';
import '../services/connectivity_service.dart';
import '../services/portfolio_repository.dart';
import '../services/portfolio_store.dart';
import '../widgets/holding_tile.dart';
import '../widgets/offline_banner.dart';
import '../widgets/portfolio_summary_card.dart';

const String _defaultPortfolioId = 'P-9001';

/// The primary portfolio overview screen (Tasks 2–4).
///
/// Loads cached data from the local store first (instant on relaunch), then
/// refreshes from the network. While offline it shows a banner plus a
/// staleness indicator and automatically re-fetches when connectivity returns.
/// The repository, store and connectivity can each be injected for testing.
class PortfolioOverviewScreen extends StatefulWidget {
  const PortfolioOverviewScreen({
    super.key,
    this.repository,
    this.store,
    this.connectivity,
  });

  final PortfolioRepository? repository;
  final PortfolioStore? store;
  final ConnectivityService? connectivity;

  @override
  State<PortfolioOverviewScreen> createState() =>
      _PortfolioOverviewScreenState();
}

class _PortfolioOverviewScreenState extends State<PortfolioOverviewScreen> {
  late final PortfolioRepository _repository =
      widget.repository ?? HttpPortfolioRepository();
  late final PortfolioStore _store = widget.store ?? SqflitePortfolioStore();
  late final ConnectivityService _connectivity =
      widget.connectivity ?? PlusConnectivityService();

  Portfolio? _portfolio;
  DateTime? _dataFetchedAt;
  bool _fromCache = false;
  bool _offline = false;
  bool _loading = true;
  String? _error;
  bool _fetching = false;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _connectivitySub = _connectivity.onlineChanges.listen((online) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _onConnectivityChanged(online);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // 1. Show cached data immediately, if any (Task 3: cold-start read).
    final cached = await _readCacheSafely();
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _portfolio = cached.portfolio;
        _dataFetchedAt = cached.cachedAt;
        _fromCache = true;
        _loading = false;
      });
    }

    // 2. Determine connectivity and fetch fresh data when online.
    var online = true;
    try {
      online = await _connectivity.currentOnline;
    } catch (_) {
      online = true; // optimistic: attempt the fetch, let it fail if unreachable
    }
    if (!mounted) return;

    if (online) {
      await _refresh();
    } else {
      setState(() {
        _offline = true;
        _loading = false; // no network, possibly no cache -> first-load state
      });
    }
  }

  Future<CachedPortfolio?> _readCacheSafely() async {
    try {
      return await _store.read(_defaultPortfolioId);
    } catch (_) {
      return null; // a missing/corrupt store is treated as "no cache"
    }
  }

  void _onConnectivityChanged(bool online) {
    setState(() => _offline = !online);
    if (online) {
      _refresh(); // auto re-fetch and reconcile when connectivity returns
    } else if (_portfolio == null) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_fetching) return; // guard against overlapping requests (flapping)
    _fetching = true;
    try {
      final portfolio = await _repository.fetchPortfolio(_defaultPortfolioId);
      // Persist the fresh snapshot (best-effort; a write failure is not fatal).
      try {
        await _store.write(_defaultPortfolioId, portfolio);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _portfolio = portfolio;
        _dataFetchedAt = DateTime.now();
        _fromCache = false;
        _offline = false;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_portfolio == null) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh: $e')),
        );
      }
    } finally {
      _fetching = false;
    }
  }

  String? get _staleness {
    if (_dataFetchedAt == null) return null;
    if (!_offline && !_fromCache) return null;
    final diff = DateTime.now().difference(_dataFetchedAt!);
    if (diff.inMinutes < 1) return 'Prices updated just now';
    if (diff.inMinutes < 60) return 'Prices as of ${diff.inMinutes}m ago';
    return 'Prices as of ${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = _portfolio;

    if (_loading && portfolio == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (portfolio == null) {
      return _buildFirstLoadError(context);
    }

    final staleness = _staleness;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_offline) const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _header(context, portfolio),
                      ),
                    ),
                    if (staleness != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            staleness,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: PortfolioSummaryCard(portfolio: portfolio),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Holdings',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (portfolio.holdings.isEmpty)
                      const SliverToBoxAdapter(child: _EmptyHoldings())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverList.builder(
                          itemCount: portfolio.holdings.length,
                          itemBuilder: (context, index) {
                            final holding = portfolio.holdings[index];
                            return Column(
                              children: [
                                HoldingTile(holding: holding),
                                if (index < portfolio.holdings.length - 1)
                                  const Divider(height: 1),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstLoadError(BuildContext context) {
    final offline = _offline;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  offline ? Icons.cloud_off : Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  offline ? 'No connection' : 'Unable to load your portfolio.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  offline
                      ? 'Connect to the internet to load your portfolio.'
                      : (_error ?? 'Something went wrong.'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Portfolio portfolio) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ELECTRIC MIND',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Portfolio Overview',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (portfolio.label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            portfolio.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyHoldings extends StatelessWidget {
  const _EmptyHoldings();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No holdings to display',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/portfolio.dart';
import '../services/portfolio_repository.dart';
import '../widgets/holding_tile.dart';
import '../widgets/portfolio_summary_card.dart';

const String _defaultPortfolioId = 'P-9001';

/// The primary portfolio overview screen (Task 2).
///
/// Shows the portfolio summary plus a scrollable, lazily-built holdings list
/// with pull-to-refresh. A [repository] can be injected for testing; it
/// defaults to the HTTP-backed implementation.
class PortfolioOverviewScreen extends StatefulWidget {
  const PortfolioOverviewScreen({super.key, this.repository});

  final PortfolioRepository? repository;

  @override
  State<PortfolioOverviewScreen> createState() =>
      _PortfolioOverviewScreenState();
}

class _PortfolioOverviewScreenState extends State<PortfolioOverviewScreen> {
  late final PortfolioRepository _repository =
      widget.repository ?? HttpPortfolioRepository();

  Portfolio? _portfolio;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _portfolio == null;
      _error = null;
    });
    try {
      final portfolio = await _repository.fetchPortfolio(_defaultPortfolioId);
      if (!mounted) return;
      setState(() {
        _portfolio = portfolio;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_portfolio == null) _error = e.toString();
      });
      if (_portfolio != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh: $e')),
        );
      }
    }
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
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load your portfolio.'),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _header(context, portfolio),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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

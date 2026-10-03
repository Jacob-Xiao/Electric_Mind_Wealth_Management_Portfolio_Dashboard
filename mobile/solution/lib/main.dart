import 'package:flutter/material.dart';

import 'screens/portfolio_overview_screen.dart';
import 'services/connectivity_service.dart';
import 'services/portfolio_repository.dart';
import 'services/portfolio_store.dart';

void main() {
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({
    super.key,
    this.repository,
    this.store,
    this.connectivity,
  });

  /// Optional overrides, used to inject fakes in widget tests.
  final PortfolioRepository? repository;
  final PortfolioStore? store;
  final ConnectivityService? connectivity;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electric Mind Portfolio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4964D8)),
        useMaterial3: true,
      ),
      home: PortfolioOverviewScreen(
        repository: repository,
        store: store,
        connectivity: connectivity,
      ),
    );
  }
}

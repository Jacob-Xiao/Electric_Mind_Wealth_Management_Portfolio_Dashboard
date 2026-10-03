import 'package:flutter/material.dart';

import 'screens/portfolio_overview_screen.dart';
import 'services/portfolio_repository.dart';

void main() {
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key, this.repository});

  /// Optional repository override, used to inject a fake in widget tests.
  final PortfolioRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electric Mind Portfolio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4964D8)),
        useMaterial3: true,
      ),
      home: PortfolioOverviewScreen(repository: repository),
    );
  }
}

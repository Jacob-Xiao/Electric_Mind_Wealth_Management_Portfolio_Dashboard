// Standalone entrypoint for Tasks 5–10, kept separate from lib/main.dart so
// it doesn't collide with Tasks 1–4 work. Run with:
//
//   flutter run -t lib/main_tasks_5_10.dart
//
// See docs/TASKS_5-10.md for how to fold this into main.dart after the merge.

import 'package:flutter/material.dart';

import 'demo/demo_overview_screen.dart';
import 'features/auth/auth_gate.dart';
import 'features/notifications/deep_link_handler.dart';
import 'features/portfolio_features.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final features = await PortfolioFeatures.bootstrap();
  runApp(PortfolioFeaturesScope(
    features: features,
    child: const _FeaturesDemoApp(),
  ));
}

class _FeaturesDemoApp extends StatelessWidget {
  const _FeaturesDemoApp();

  @override
  Widget build(BuildContext context) {
    final features = PortfolioFeatures.of(context);
    return MaterialApp(
      title: 'Electric Mind Portfolio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4964D8)),
        useMaterial3: true,
      ),
      // Task 5: the gate sits above the Navigator, covering every route.
      builder: (context, child) =>
          AuthGate(controller: features.auth, child: child!),
      // Task 6: notification taps are applied once the user has unlocked.
      home: DeepLinkHandler(
        deepLinks: features.deepLinks,
        accounts: features.accounts,
        child: const DemoOverviewScreen(),
      ),
    );
  }
}

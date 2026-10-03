import 'package:flutter/widgets.dart';

import 'accounts/account_selection_controller.dart';
import 'auth/auth_controller.dart';
import 'auth/biometric_authenticator.dart';
import 'auth/secure_store.dart';
import 'notifications/deep_link_bus.dart';
import 'notifications/notification_service.dart';
import 'shared/feature_api_client.dart';

/// Creates and holds the long-lived objects behind Tasks 5–10.
///
/// Integration into the real app (after merging with Tasks 1–4):
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final features = await PortfolioFeatures.bootstrap();
///   runApp(PortfolioFeaturesScope(features: features, child: const PortfolioApp()));
/// }
///
/// // in PortfolioApp.build:
/// MaterialApp(
///   builder: (context, child) => AuthGate(
///     controller: PortfolioFeatures.of(context).auth, child: child!),
///   home: DeepLinkHandler(
///     deepLinks: features.deepLinks, accounts: features.accounts,
///     child: const PortfolioOverviewScreen()),
/// )
/// ```
class PortfolioFeatures {
  PortfolioFeatures({
    required this.api,
    required this.auth,
    required this.accounts,
    required this.deepLinks,
    required this.notifications,
  });

  final FeatureApiClient api;
  final AuthController auth;
  final AccountSelectionController accounts;
  final DeepLinkBus deepLinks;
  final PortfolioNotificationService notifications;

  /// Must run before `runApp` so a notification that cold-started the app is
  /// captured. Does not fetch any portfolio data (that waits for unlock).
  static Future<PortfolioFeatures> bootstrap({FeatureApiConfig? config}) async {
    final api =
        FeatureApiClient(config: config ?? FeatureApiConfig.fromEnvironment());
    final deepLinks = DeepLinkBus();
    final notifications = PortfolioNotificationService(deepLinks: deepLinks);
    await notifications.initialize();
    return PortfolioFeatures(
      api: api,
      auth: AuthController(
        store: PlatformSecureStore(),
        biometrics: LocalAuthBiometricAuthenticator(),
      ),
      accounts: AccountSelectionController(loader: api.getAccounts),
      deepLinks: deepLinks,
      notifications: notifications,
    );
  }

  static PortfolioFeatures of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PortfolioFeaturesScope>();
    assert(scope != null, 'No PortfolioFeaturesScope above this widget');
    return scope!.features;
  }

  /// Like [of] but without subscribing; safe to call from `initState`.
  static PortfolioFeatures read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<PortfolioFeaturesScope>();
    assert(scope != null, 'No PortfolioFeaturesScope above this widget');
    return scope!.features;
  }
}

class PortfolioFeaturesScope extends InheritedWidget {
  const PortfolioFeaturesScope({
    super.key,
    required this.features,
    required super.child,
  });

  final PortfolioFeatures features;

  @override
  bool updateShouldNotify(PortfolioFeaturesScope oldWidget) =>
      features != oldWidget.features;
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'deep_link_bus.dart';
import 'portfolio_notification.dart';

/// Task 6 — Local notifications standing in for server push.
///
/// Tap routing covers all three app states:
/// - **Cold start** (app fully closed): [initialize] reads
///   `getNotificationAppLaunchDetails()` and queues the payload.
/// - **Backgrounded / foreground**: the plugin's
///   `onDidReceiveNotificationResponse` callback queues it. MainActivity is
///   `singleTop`, so the existing Flutter engine and navigation stack are
///   reused; nothing restarts.
///
/// Queued payloads go to [DeepLinkBus]; the `DeepLinkHandler` widget acts on
/// them once the lock screen has been passed.
class PortfolioNotificationService {
  PortfolioNotificationService({
    required this.deepLinks,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'portfolio_alerts';
  static const _channelName = 'Portfolio alerts';
  static const _androidIcon = 'ic_stat_portfolio';

  final DeepLinkBus deepLinks;
  final FlutterLocalNotificationsPlugin _plugin;
  int _nextId = 1;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_androidIcon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _handleTap(response.payload),
      );
      _initialized = true;

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _handleTap(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      // Notifications are non-critical: never block app start-up on them.
      debugPrint('Notification init failed: $e');
    }
  }

  /// Android 13+ requires the POST_NOTIFICATIONS runtime permission; iOS
  /// requires an explicit request. Returns false if the user declined.
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    return false;
  }

  /// Shows [payload] as a local notification, as if pushed by a server.
  Future<void> showMockPush(PortfolioNotificationPayload payload) async {
    await initialize();
    await _plugin.show(
      id: _nextId++,
      title: payload.title,
      body: payload.body,
      payload: payload.encode(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Alerts about changes in your portfolios',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _handleTap(String? rawPayload) {
    final payload = PortfolioNotificationPayload.tryParse(rawPayload);
    if (payload == null) {
      debugPrint('Ignoring notification tap with unusable payload: $rawPayload');
      return;
    }
    deepLinks.push(payload);
  }
}

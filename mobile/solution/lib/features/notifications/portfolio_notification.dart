import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Push payload shape from mobile/API-CONTRACT.md (`NotificationPayload`):
/// `{ title, body, data: { portfolioId, type } }`.
@immutable
class PortfolioNotificationPayload {
  const PortfolioNotificationPayload({
    required this.title,
    required this.body,
    required this.portfolioId,
    required this.type,
  });

  final String title;
  final String body;
  final String portfolioId;
  final String type;

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'data': {'portfolioId': portfolioId, 'type': type},
      };

  String encode() => jsonEncode(toJson());

  /// Returns null (never throws) for anything that is not a usable payload,
  /// so a malformed notification can't crash the tap handler.
  static PortfolioNotificationPayload? tryParse(Object? raw) {
    try {
      final json = raw is String ? jsonDecode(raw) : raw;
      if (json is! Map) return null;
      final data = json['data'];
      if (data is! Map) return null;
      final portfolioId = data['portfolioId'];
      if (portfolioId is! String || portfolioId.trim().isEmpty) return null;
      return PortfolioNotificationPayload(
        title: json['title'] as String? ?? 'Portfolio Alert',
        body: json['body'] as String? ?? '',
        portfolioId: portfolioId.trim(),
        type: data['type'] as String? ?? 'portfolio_alert',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PortfolioNotificationPayload &&
      other.title == title &&
      other.body == body &&
      other.portfolioId == portfolioId &&
      other.type == type;

  @override
  int get hashCode => Object.hash(title, body, portfolioId, type);
}

/// Copies of mobile/fixtures/notification*.json, so the simulator works even
/// without the mock server.
class MockNotifications {
  MockNotifications._();

  static const validPortfolio = PortfolioNotificationPayload(
    title: 'Portfolio Alert',
    body: 'Your portfolio has been updated',
    portfolioId: 'P-9002',
    type: 'portfolio_alert',
  );

  static const unknownPortfolio = PortfolioNotificationPayload(
    title: 'Portfolio Alert',
    body: 'A portfolio is no longer available',
    portfolioId: 'P-UNKNOWN',
    type: 'portfolio_alert',
  );
}

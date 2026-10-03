import 'package:flutter/foundation.dart';

import 'portfolio_notification.dart';

/// Holds at most one pending "open this portfolio" request from a
/// notification tap until the UI is ready to act on it (i.e. after the user
/// has passed the Task 5 lock screen). A newer tap replaces an older one.
class DeepLinkBus extends ChangeNotifier {
  PortfolioNotificationPayload? _pending;

  PortfolioNotificationPayload? get pending => _pending;

  void push(PortfolioNotificationPayload payload) {
    _pending = payload;
    notifyListeners();
  }

  /// Returns and clears the pending request (so it is handled exactly once).
  PortfolioNotificationPayload? take() {
    final p = _pending;
    _pending = null;
    return p;
  }
}

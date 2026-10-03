import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device currently has a usable network connection.
///
/// Abstract so tests can inject a fake and dev builds can simulate connectivity
/// loss/return (Task 4).
abstract class ConnectivityService {
  /// Emits true when the device comes online and false when it goes offline.
  Stream<bool> get onlineChanges;

  /// The current connectivity state.
  Future<bool> get currentOnline;
}

/// [ConnectivityService] backed by the `connectivity_plus` plugin.
class PlusConnectivityService implements ConnectivityService {
  PlusConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none))
      .distinct();

  @override
  Future<bool> get currentOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

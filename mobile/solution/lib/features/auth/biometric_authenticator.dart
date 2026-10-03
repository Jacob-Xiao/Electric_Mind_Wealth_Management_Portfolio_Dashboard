import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricOutcome {
  success,

  /// User was not recognised (or tapped the negative button).
  failed,

  /// User dismissed the prompt or the system cancelled it.
  cancelled,

  /// No hardware / nothing enrolled / temporarily locked out — use the PIN.
  unavailable,
}

/// Wraps `local_auth` so failures map to a small set of outcomes and never
/// throw. Any unexpected platform error is treated as [unavailable], which
/// sends the user to the PIN path instead of skipping the gate.
abstract class BiometricAuthenticator {
  Future<bool> isAvailable();
  Future<BiometricOutcome> authenticate(String reason);
}

class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        // The app PIN is our fallback, so the system prompt is biometric-only.
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress =>
          BiometricOutcome.cancelled,
        _ => BiometricOutcome.unavailable,
      };
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return BiometricOutcome.unavailable;
    }
  }
}

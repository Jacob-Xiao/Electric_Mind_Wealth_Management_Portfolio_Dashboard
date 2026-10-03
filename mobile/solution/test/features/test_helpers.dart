import 'package:electric_mind_portfolio/features/auth/auth_controller.dart';
import 'package:electric_mind_portfolio/features/auth/biometric_authenticator.dart';
import 'package:electric_mind_portfolio/features/auth/pin_hasher.dart';
import 'package:electric_mind_portfolio/features/auth/secure_store.dart';

/// Skips PBKDF2 (and its isolate) so widget tests run under fake async.
class FastPinHasher extends PinHasher {
  const FastPinHasher();

  @override
  Future<String> hash(String pin) async => 'test\$$pin';

  @override
  Future<bool> verify(String pin, String stored) async => stored == 'test\$$pin';
}

class FakeBiometrics implements BiometricAuthenticator {
  FakeBiometrics({this.available = false, this.outcome = BiometricOutcome.failed});

  bool available;
  BiometricOutcome outcome;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricOutcome> authenticate(String reason) async {
    calls++;
    return outcome;
  }
}

AuthController buildAuth({
  InMemorySecureStore? store,
  FakeBiometrics? biometrics,
  DateTime Function()? clock,
  Duration relockAfter = const Duration(seconds: 30),
}) =>
    AuthController(
      store: store ?? InMemorySecureStore(),
      biometrics: biometrics ?? FakeBiometrics(),
      hasher: const FastPinHasher(),
      clock: clock,
      relockAfter: relockAfter,
    );

import 'package:electric_mind_portfolio/features/auth/auth_controller.dart';
import 'package:electric_mind_portfolio/features/auth/auth_gate.dart';
import 'package:electric_mind_portfolio/features/auth/biometric_authenticator.dart';
import 'package:electric_mind_portfolio/features/auth/pin_hasher.dart';
import 'package:electric_mind_portfolio/features/auth/secure_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('PinHasher', () {
    test('verifies the right PIN, rejects others, never stores the PIN',
        () async {
      const hasher = PinHasher(iterations: 1000);
      final stored = await hasher.hash('2468');
      expect(stored, isNot(contains('2468')));
      expect(stored, startsWith('pbkdf2-sha256\$1000\$'));
      expect(await hasher.verify('2468', stored), isTrue);
      expect(await hasher.verify('1357', stored), isFalse);
      expect(await hasher.verify('2468', 'garbage'), isFalse);
    });

    test('uses a random salt per hash', () async {
      const hasher = PinHasher(iterations: 10);
      expect(await hasher.hash('1111'), isNot(await hasher.hash('1111')));
    });
  });

  group('AuthController', () {
    test('first launch requires PIN setup, then stores token securely',
        () async {
      final store = InMemorySecureStore();
      final auth = buildAuth(store: store);
      await auth.initialize();
      expect(auth.status, AuthStatus.needsPinSetup);
      expect(await auth.readSessionToken(), isNull);

      expect(await auth.createPin('12'), isFalse, reason: 'too short');
      expect(await auth.createPin('1234'), isTrue);
      expect(auth.status, AuthStatus.unlocked);

      final token = await auth.readSessionToken();
      expect(token, startsWith('mock-session-'));
      expect(store.values.values, isNot(contains('1234')));
    });

    test('relaunch is locked; token survives and is hidden while locked',
        () async {
      final store = InMemorySecureStore();
      final first = buildAuth(store: store);
      await first.initialize();
      await first.createPin('1234');
      final token = await first.readSessionToken();

      final relaunched = buildAuth(store: store);
      await relaunched.initialize();
      expect(relaunched.status, AuthStatus.locked);
      expect(await relaunched.readSessionToken(), isNull);

      expect(await relaunched.unlockWithPin('1234'), isTrue);
      expect(await relaunched.readSessionToken(), token);
    });

    test('wrong PIN keeps the user locked out, then rate-limits', () async {
      var now = DateTime(2026, 1, 1, 12);
      final store = InMemorySecureStore();
      final setup = buildAuth(store: store);
      await setup.initialize();
      await setup.createPin('1234');

      final auth = buildAuth(store: store, clock: () => now);
      await auth.initialize();
      for (var i = 0; i < 5; i++) {
        expect(await auth.unlockWithPin('0000'), isFalse);
        expect(auth.status, AuthStatus.locked);
      }
      expect(auth.lockoutUntil, isNotNull);
      // Even the correct PIN is refused during lockout.
      expect(await auth.unlockWithPin('1234'), isFalse);
      expect(auth.status, AuthStatus.locked);

      now = now.add(const Duration(seconds: 31));
      expect(await auth.unlockWithPin('1234'), isTrue);
      expect(auth.failedAttempts, 0);
    });

    test('lockout persists across relaunch', () async {
      final now = DateTime.now();
      final store = InMemorySecureStore();
      final setup = buildAuth(store: store);
      await setup.initialize();
      await setup.createPin('1234');
      final auth = buildAuth(store: store, clock: () => now);
      await auth.initialize();
      for (var i = 0; i < 5; i++) {
        await auth.unlockWithPin('0000');
      }
      final relaunched = buildAuth(store: store, clock: () => now);
      await relaunched.initialize();
      expect(relaunched.lockoutUntil, isNotNull);
    });

    test('failed biometrics stay locked; PIN still works', () async {
      final store = InMemorySecureStore();
      final setup = buildAuth(store: store);
      await setup.initialize();
      await setup.createPin('1234');

      final bio = FakeBiometrics(available: true, outcome: BiometricOutcome.failed);
      final auth = buildAuth(store: store, biometrics: bio);
      await auth.initialize(); // auto-prompts biometrics
      await Future<void>.delayed(Duration.zero);
      expect(bio.calls, 1);
      expect(auth.status, AuthStatus.locked);
      expect(await auth.unlockWithPin('1234'), isTrue);
    });

    test('successful biometrics unlock', () async {
      final store = InMemorySecureStore();
      final setup = buildAuth(store: store);
      await setup.initialize();
      await setup.createPin('1234');

      final auth = buildAuth(
          store: store,
          biometrics: FakeBiometrics(
              available: true, outcome: BiometricOutcome.success));
      await auth.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.unlocked);
    });

    test('no biometric hardware: never prompts, PIN path only', () async {
      final store = InMemorySecureStore();
      final setup = buildAuth(store: store);
      await setup.initialize();
      await setup.createPin('1234');

      final bio = FakeBiometrics(available: false);
      final auth = buildAuth(store: store, biometrics: bio);
      await auth.initialize();
      await auth.unlockWithBiometrics();
      expect(bio.calls, 0);
      expect(auth.status, AuthStatus.locked);
      expect(await auth.unlockWithPin('1234'), isTrue);
    });

    test('biometrics becoming unavailable falls back to PIN', () async {
      final store = InMemorySecureStore();
      final setup = buildAuth(store: store);
      await setup.initialize();
      await setup.createPin('1234');
      final auth = buildAuth(
          store: store,
          biometrics: FakeBiometrics(
              available: true, outcome: BiometricOutcome.unavailable));
      await auth.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.locked);
      expect(auth.biometricAvailable, isFalse);
    });

    test('reset wipes PIN and token', () async {
      final store = InMemorySecureStore();
      final auth = buildAuth(store: store);
      await auth.initialize();
      await auth.createPin('1234');
      auth.lock(promptBiometrics: false);
      await auth.resetAndSignOut();
      expect(auth.status, AuthStatus.needsPinSetup);
      expect(store.values, isEmpty);
    });
  });

  group('AuthGate', () {
    Widget app(AuthController auth) => MaterialApp(
          builder: (context, child) => AuthGate(controller: auth, child: child!),
          home: const Scaffold(body: Text('SECRET PORTFOLIO')),
        );

    Future<void> enterPin(WidgetTester tester, String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.widgetWithText(TextButton, d));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('portfolio is not built until PIN setup completes',
        (tester) async {
      final auth = buildAuth();
      await tester.pumpWidget(app(auth));
      await tester.pumpAndSettle();

      expect(find.text('Create a 4-digit PIN'), findsOneWidget);
      expect(find.text('SECRET PORTFOLIO'), findsNothing);

      await enterPin(tester, '1234');
      expect(find.text('Confirm your PIN'), findsOneWidget);
      expect(find.text('SECRET PORTFOLIO'), findsNothing);

      await enterPin(tester, '1234');
      expect(find.text('SECRET PORTFOLIO'), findsOneWidget);
    });

    testWidgets('mismatched confirmation restarts setup', (tester) async {
      final auth = buildAuth();
      await tester.pumpWidget(app(auth));
      await tester.pumpAndSettle();
      await enterPin(tester, '1234');
      await enterPin(tester, '9999');
      expect(find.text("PINs didn't match. Try again."), findsOneWidget);
      expect(find.text('Create a 4-digit PIN'), findsOneWidget);
      expect(find.text('SECRET PORTFOLIO'), findsNothing);
    });

    testWidgets('wrong PIN keeps content hidden; right PIN reveals it',
        (tester) async {
      final store = InMemorySecureStore();
      final setup = buildAuth(store: store);
      await setup.initialize();
      await setup.createPin('1234');

      final auth = buildAuth(store: store);
      await tester.pumpWidget(app(auth));
      await tester.pumpAndSettle();
      expect(find.text('Enter your PIN'), findsOneWidget);
      // No biometric hardware: no biometric button, PIN pad only.
      expect(find.byIcon(Icons.fingerprint), findsNothing);

      await enterPin(tester, '0000');
      expect(find.textContaining('Incorrect PIN'), findsOneWidget);
      expect(find.text('SECRET PORTFOLIO'), findsNothing);

      await enterPin(tester, '1234');
      expect(find.text('SECRET PORTFOLIO'), findsOneWidget);
    });

    testWidgets('re-locking hides content but keeps its state',
        (tester) async {
      final auth = buildAuth();
      await tester.pumpWidget(app(auth));
      await tester.pumpAndSettle();
      await enterPin(tester, '1234');
      await enterPin(tester, '1234');
      expect(find.text('SECRET PORTFOLIO'), findsOneWidget);

      auth.lock(promptBiometrics: false);
      await tester.pumpAndSettle();
      expect(find.text('SECRET PORTFOLIO'), findsNothing); // offstage
      expect(find.text('SECRET PORTFOLIO', skipOffstage: false), findsOneWidget);
      expect(find.text('Enter your PIN'), findsOneWidget);

      await enterPin(tester, '1234');
      expect(find.text('SECRET PORTFOLIO'), findsOneWidget);
    });

    testWidgets('locks again after returning from background', (tester) async {
      final auth = buildAuth(relockAfter: Duration.zero);
      await tester.pumpWidget(app(auth));
      await tester.pumpAndSettle();
      await enterPin(tester, '1234');
      await enterPin(tester, '1234');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(auth.status, AuthStatus.locked);
      expect(find.text('SECRET PORTFOLIO'), findsNothing);
    });
  });
}

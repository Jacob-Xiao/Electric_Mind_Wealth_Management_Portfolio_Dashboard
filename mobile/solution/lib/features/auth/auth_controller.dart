import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'biometric_authenticator.dart';
import 'pin_hasher.dart';
import 'secure_store.dart';

enum AuthStatus {
  /// Reading secure storage / checking biometric hardware.
  initializing,

  /// First launch (or after reset): the user must create an app PIN.
  needsPinSetup,

  /// PIN exists; portfolio content must not be shown.
  locked,

  unlocked,
}

/// Task 5 — App lock state machine.
///
/// - Biometrics (Face ID / Touch ID / fingerprint) are tried first when the
///   device has them enrolled; otherwise, or when they fail/are cancelled,
///   the user enters the app PIN. A device without biometric hardware goes
///   straight to the PIN path — the gate is never skipped.
/// - The PIN is stored only as a salted PBKDF2 hash in secure storage.
/// - The mock session token is created on first successful unlock and kept
///   in secure storage (Keychain / Android Keystore-backed encryption).
/// - After [maxAttempts] wrong PINs, entry is blocked for [lockoutBase],
///   doubling on each further failure (persisted, so killing the app does
///   not reset it).
class AuthController extends ChangeNotifier {
  AuthController({
    required SecureKeyValueStore store,
    required BiometricAuthenticator biometrics,
    PinHasher hasher = const PinHasher(),
    DateTime Function()? clock,
    this.maxAttempts = 5,
    this.lockoutBase = const Duration(seconds: 30),
    this.relockAfter = const Duration(seconds: 30),
    this.autoPromptBiometrics = true,
  })  : _store = store,
        _biometrics = biometrics,
        _hasher = hasher,
        _clock = clock ?? DateTime.now;

  static const pinLength = 4;
  static const _kPinHash = 'em.auth.pin_hash';
  static const _kSessionToken = 'em.auth.session_token';
  static const _kFailedAttempts = 'em.auth.failed_attempts';
  static const _kLockoutUntil = 'em.auth.lockout_until';

  final SecureKeyValueStore _store;
  final BiometricAuthenticator _biometrics;
  final PinHasher _hasher;
  final DateTime Function() _clock;
  final int maxAttempts;
  final Duration lockoutBase;

  /// How long the app may sit in the background before it locks again on
  /// resume. `Duration.zero` locks on every resume.
  final Duration relockAfter;
  final bool autoPromptBiometrics;

  AuthStatus _status = AuthStatus.initializing;
  bool _biometricAvailable = false;
  bool _busy = false;
  String? _message;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  bool _biometricInFlight = false;

  AuthStatus get status => _status;
  bool get isUnlocked => _status == AuthStatus.unlocked;
  bool get biometricAvailable => _biometricAvailable;
  bool get busy => _busy;

  /// Last error/info for the lock screen (wrong PIN, lockout, etc.).
  String? get message => _message;
  int get failedAttempts => _failedAttempts;

  /// Non-null while PIN entry is temporarily blocked.
  DateTime? get lockoutUntil {
    final until = _lockoutUntil;
    return until != null && until.isAfter(_clock()) ? until : null;
  }

  Future<void>? _initFuture;

  /// Safe to call more than once; only the first call does the work.
  Future<void> initialize() => _initFuture ??= _initialize();

  Future<void> _initialize() async {
    try {
      final hash = await _store.read(_kPinHash);
      _failedAttempts =
          int.tryParse(await _store.read(_kFailedAttempts) ?? '') ?? 0;
      final until = int.tryParse(await _store.read(_kLockoutUntil) ?? '');
      _lockoutUntil =
          until == null ? null : DateTime.fromMillisecondsSinceEpoch(until);
      _biometricAvailable = await _biometrics.isAvailable();
      _status = hash == null ? AuthStatus.needsPinSetup : AuthStatus.locked;
    } catch (e) {
      // Secure storage unreadable (e.g. keystore reset). Stay locked and let
      // the user reset rather than falling through to the portfolio.
      debugPrint('Auth initialisation failed: $e');
      _status = AuthStatus.needsPinSetup;
      _message = 'Secure storage was reset. Please create a new PIN.';
    }
    notifyListeners();
    if (_status == AuthStatus.locked) unawaited(_maybeAutoPrompt());
  }

  /// First-run PIN creation. Counts as authentication for this session.
  Future<bool> createPin(String pin) async {
    if (_status != AuthStatus.needsPinSetup || !_isValidPin(pin)) return false;
    _setBusy(true);
    try {
      await _store.write(_kPinHash, await _hasher.hash(pin));
      await _resetFailures();
      await _completeUnlock();
      return true;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    if (_status != AuthStatus.locked || _busy) return false;
    final blockedUntil = lockoutUntil;
    if (blockedUntil != null) {
      _message = 'Too many attempts. Try again shortly.';
      notifyListeners();
      return false;
    }
    _setBusy(true);
    try {
      final hash = await _store.read(_kPinHash);
      final ok = hash != null && await _hasher.verify(pin, hash);
      if (ok) {
        await _resetFailures();
        await _completeUnlock();
        return true;
      }
      await _registerFailure();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> unlockWithBiometrics() async {
    if (_status != AuthStatus.locked || !_biometricAvailable) return;
    if (_biometricInFlight) return;
    _biometricInFlight = true;
    try {
      final outcome =
          await _biometrics.authenticate('Unlock to view your portfolio');
      if (_status != AuthStatus.locked) return;
      switch (outcome) {
        case BiometricOutcome.success:
          await _resetFailures();
          await _completeUnlock();
        case BiometricOutcome.failed:
          _message = 'Biometric check failed. Enter your PIN.';
        case BiometricOutcome.cancelled:
          _message = null;
        case BiometricOutcome.unavailable:
          _biometricAvailable = false;
          _message = 'Biometrics unavailable. Enter your PIN.';
      }
      notifyListeners();
    } finally {
      _biometricInFlight = false;
    }
  }

  /// Hides the portfolio again (e.g. after the app was backgrounded).
  void lock({bool promptBiometrics = true}) {
    if (_status != AuthStatus.unlocked) return;
    _status = AuthStatus.locked;
    _message = null;
    notifyListeners();
    if (promptBiometrics) unawaited(_maybeAutoPrompt());
  }

  /// "Forgot PIN": wipes the PIN and the session token (i.e. signs out) and
  /// returns to PIN setup. Portfolio data is not shown until a new PIN is set.
  Future<void> resetAndSignOut() async {
    _setBusy(true);
    try {
      await _store.delete(_kPinHash);
      await _store.delete(_kSessionToken);
      await _resetFailures();
      _status = AuthStatus.needsPinSetup;
      _message = null;
    } finally {
      _setBusy(false);
    }
  }

  /// The mock session token for API calls. Returns null while locked, so
  /// nothing can use the session without passing the gate first.
  Future<String?> readSessionToken() async {
    if (!isUnlocked) return null;
    return _store.read(_kSessionToken);
  }

  Future<void> _maybeAutoPrompt() async {
    if (autoPromptBiometrics && _biometricAvailable) {
      await unlockWithBiometrics();
    }
  }

  Future<void> _completeUnlock() async {
    final existing = await _store.read(_kSessionToken);
    if (existing == null || existing.isEmpty) {
      await _store.write(_kSessionToken, _newMockToken());
    }
    _status = AuthStatus.unlocked;
    _message = null;
    notifyListeners();
  }

  Future<void> _registerFailure() async {
    _failedAttempts++;
    await _store.write(_kFailedAttempts, '$_failedAttempts');
    if (_failedAttempts >= maxAttempts) {
      final doublings = min(_failedAttempts - maxAttempts, 5);
      final until = _clock().add(lockoutBase * (1 << doublings));
      _lockoutUntil = until;
      await _store.write(
          _kLockoutUntil, '${until.millisecondsSinceEpoch}');
      _message = 'Too many attempts. Try again shortly.';
    } else {
      final left = maxAttempts - _failedAttempts;
      _message = 'Incorrect PIN. $left attempt${left == 1 ? '' : 's'} left.';
    }
    notifyListeners();
  }

  Future<void> _resetFailures() async {
    _failedAttempts = 0;
    _lockoutUntil = null;
    await _store.delete(_kFailedAttempts);
    await _store.delete(_kLockoutUntil);
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  static bool _isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  static String _newMockToken() {
    final random = Random.secure();
    final hex = List<String>.generate(
        32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    return 'mock-session-${hex.join()}';
  }
}

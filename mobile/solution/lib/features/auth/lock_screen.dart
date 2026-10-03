import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_controller.dart';

/// PIN pad + biometric button. Handles both first-run PIN creation (enter,
/// then confirm) and unlocking.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _entered = '';
  String? _firstPin; // Set during setup, while confirming.
  String? _localError;
  bool _confirmingReset = false;
  Timer? _ticker;

  AuthController get _auth => widget.controller;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    _syncLockoutTicker();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _ticker?.cancel();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_auth.status == AuthStatus.needsPinSetup && _auth.busy == false) {
      _confirmingReset = false;
    }
    _syncLockoutTicker();
    setState(() {});
  }

  void _syncLockoutTicker() {
    if (_auth.lockoutUntil != null) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_auth.lockoutUntil == null) {
          _ticker?.cancel();
          _ticker = null;
        }
        setState(() {});
      });
    }
  }

  bool get _isSetup => _auth.status == AuthStatus.needsPinSetup;

  bool get _inputDisabled =>
      _auth.busy ||
      _auth.status == AuthStatus.initializing ||
      (!_isSetup && _auth.lockoutUntil != null);

  void _onDigit(String d) {
    if (_inputDisabled || _entered.length >= AuthController.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entered += d;
      _localError = null;
    });
    if (_entered.length == AuthController.pinLength) _submit();
  }

  void _onBackspace() {
    if (_entered.isEmpty || _inputDisabled) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    final pin = _entered;
    if (_isSetup) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = pin;
          _entered = '';
        });
        return;
      }
      if (_firstPin != pin) {
        HapticFeedback.heavyImpact();
        setState(() {
          _firstPin = null;
          _entered = '';
          _localError = "PINs didn't match. Try again.";
        });
        return;
      }
      await _auth.createPin(pin);
    } else {
      final ok = await _auth.unlockWithPin(pin);
      if (!ok) HapticFeedback.heavyImpact();
    }
    if (mounted) {
      setState(() {
        _entered = '';
        _firstPin = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _auth.status;

    if (status == AuthStatus.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = _isSetup
        ? (_firstPin == null ? 'Create a 4-digit PIN' : 'Confirm your PIN')
        : 'Enter your PIN';
    final subtitle = _isSetup
        ? 'Your PIN protects access to your portfolio on this device.'
        : (_auth.biometricAvailable
            ? 'Or use biometrics to unlock.'
            : 'Unlock to view your portfolio.');

    final lockout = _auth.lockoutUntil;
    final String? error = lockout != null && !_isSetup
        ? 'Too many attempts. Try again in '
            '${lockout.difference(DateTime.now()).inSeconds + 1}s.'
        : (_localError ?? _auth.message);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('ELECTRIC MIND',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 16),
                    Text(title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    _PinDots(filled: _entered.length, busy: _auth.busy),
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: error == null
                            ? null
                            : Text(error,
                                key: const Key('lock-error'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error)),
                      ),
                    ),
                    _Keypad(
                      enabled: !_inputDisabled,
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                      onBiometric: !_isSetup && _auth.biometricAvailable
                          ? _auth.unlockWithBiometrics
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (!_isSetup) _buildReset(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReset(ThemeData theme) {
    if (!_confirmingReset) {
      return TextButton(
        onPressed: () => setState(() => _confirmingReset = true),
        child: const Text('Forgot PIN?'),
      );
    }
    return Column(
      children: [
        Text('Resetting signs you out of this device.',
            style: theme.textTheme.bodySmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => _confirmingReset = false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _auth.resetAndSignOut,
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error),
              child: const Text('Reset & sign out'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.busy});

  final int filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    if (busy) {
      return const SizedBox(
        height: 16,
        child: Center(
          child: SizedBox.square(
              dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return Semantics(
      label: '$filled of ${AuthController.pinLength} digits entered',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < AuthController.pinLength; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    Widget key(String d) => _KeyButton(
          label: d,
          onPressed: enabled ? () => onDigit(d) : null,
        );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final d in row) key(d)],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _KeyButton(
                icon: Icons.fingerprint,
                tooltip: 'Use biometrics',
                onPressed: onBiometric,
                hidden: onBiometric == null,
              ),
              key('0'),
              _KeyButton(
                icon: Icons.backspace_outlined,
                tooltip: 'Delete',
                onPressed: enabled ? onBackspace : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.label,
    this.icon,
    this.tooltip,
    required this.onPressed,
    this.hidden = false,
  });

  final String? label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    if (hidden) return const SizedBox(width: size, height: size);
    final theme = Theme.of(context);
    final child = label != null
        ? Text(label!,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w500))
        : Icon(icon, size: 28);
    final button = Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox.square(
        dimension: size - 8,
        child: TextButton(
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            foregroundColor: theme.colorScheme.onSurface,
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

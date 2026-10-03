import 'package:flutter/material.dart';

import 'auth_controller.dart';
import 'lock_screen.dart';

/// Task 5 — Blocks the whole app until the user authenticates.
///
/// Install it above the Navigator so it also covers pushed routes:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => AuthGate(controller: auth, child: child!),
///   home: ...,
/// )
/// ```
///
/// Locking policy (documented choice): the app locks on every cold launch, and
/// again when it returns from the background after [AuthController.relockAfter]
/// (30 s by default).
///
/// Until the first successful unlock of a process, [child] is not built at
/// all, so no portfolio screen is created and nothing is fetched. After a
/// re-lock, [child] stays mounted but invisible, without semantics or
/// animations, so navigation state survives and nothing restarts.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.controller, required this.child});

  final AuthController controller;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _everUnlocked = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After the first frame, so the biometric prompt has an Activity/window.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.controller.initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            DateTime.now().difference(since) >= widget.controller.relockAfter) {
          widget.controller.lock();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final status = widget.controller.status;
        final unlocked = status == AuthStatus.unlocked;
        if (unlocked) _everUnlocked = true;
        // After "forgot PIN" (sign-out) drop the old session's UI entirely.
        if (status == AuthStatus.needsPinSetup) _everUnlocked = false;

        if (!_everUnlocked) {
          return _LockLayer(controller: widget.controller);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Visibility(
              visible: unlocked,
              maintainState: true,
              child: TickerMode(
                enabled: unlocked,
                child: ExcludeSemantics(
                  excluding: !unlocked,
                  child: widget.child,
                ),
              ),
            ),
            if (!unlocked) _LockLayer(controller: widget.controller),
          ],
        );
      },
    );
  }
}

/// The gate sits above the app's Navigator/Overlay, so give the lock screen
/// its own Overlay (needed by tooltips, ink splashes, etc.).
class _LockLayer extends StatefulWidget {
  const _LockLayer({required this.controller});

  final AuthController controller;

  @override
  State<_LockLayer> createState() => _LockLayerState();
}

class _LockLayerState extends State<_LockLayer> {
  late final OverlayEntry _entry =
      OverlayEntry(builder: (_) => LockScreen(controller: widget.controller));

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}

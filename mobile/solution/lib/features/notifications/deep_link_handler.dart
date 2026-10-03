import 'package:flutter/material.dart';

import '../accounts/account_selection_controller.dart';
import 'deep_link_bus.dart';

/// Task 6 — Applies notification taps to the UI.
///
/// Wrap the Portfolio Overview screen (the Navigator's first route) with it.
/// Because it lives under `AuthGate`, it is only built after the user unlocks,
/// so a cold-start tap waits behind the lock screen instead of bypassing it.
///
/// On a tap it:
/// 1. pops back to the overview (closing any detail screen or bottom sheet),
/// 2. selects `data.portfolioId` via [AccountSelectionController] — or the
///    default account if that ID doesn't exist — and
/// 3. tells the user what happened with a SnackBar.
class DeepLinkHandler extends StatefulWidget {
  const DeepLinkHandler({
    super.key,
    required this.deepLinks,
    required this.accounts,
    required this.child,
  });

  final DeepLinkBus deepLinks;
  final AccountSelectionController accounts;
  final Widget child;

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    widget.deepLinks.addListener(_consume);
    // A tap that launched the app is already queued; handle it after the
    // first frame, once Navigator and ScaffoldMessenger are available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _consume());
  }

  @override
  void didUpdateWidget(DeepLinkHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deepLinks != widget.deepLinks) {
      oldWidget.deepLinks.removeListener(_consume);
      widget.deepLinks.addListener(_consume);
    }
  }

  @override
  void dispose() {
    widget.deepLinks.removeListener(_consume);
    super.dispose();
  }

  Future<void> _consume() async {
    if (!mounted) return;
    final payload = widget.deepLinks.take();
    if (payload == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    navigator.popUntil((route) => route.isFirst);

    final result = await widget.accounts.requestAccount(payload.portfolioId);
    if (!mounted) return;

    final selected = result.selected;
    final String text;
    if (selected == null) {
      text = "Couldn't open portfolio ${payload.portfolioId} right now.";
    } else if (result.fellBack) {
      text = "Portfolio ${payload.portfolioId} isn't available. "
          'Showing ${selected.label} instead.';
    } else {
      text = 'Opened ${selected.label}';
    }
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

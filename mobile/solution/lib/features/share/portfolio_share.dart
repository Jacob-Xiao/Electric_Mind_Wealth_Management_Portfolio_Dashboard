import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../shared/formatters.dart';

/// The portfolio summary fields that may be shared. Deliberately excludes
/// holdings, account/client IDs and anything else not on the summary card.
class PortfolioShareSnapshot {
  const PortfolioShareSnapshot({
    required this.totalMarketValue,
    required this.dayChangeAmount,
    required this.dayChangePercent,
    required this.totalReturnSinceInception,
    this.accountLabel,
    this.asOf,
    this.currency = 'CAD',
  });

  final double totalMarketValue;
  final double dayChangeAmount;

  /// Percentage points: 0.32 means 0.32%.
  final double dayChangePercent;

  /// Ratio: 0.187 means 18.7%.
  final double totalReturnSinceInception;
  final String? accountLabel;
  final DateTime? asOf;
  final String currency;
}

/// Task 7 — Builds the plain-text summary handed to the share sheet.
///
/// Example:
/// ```
/// My Taxable Brokerage portfolio: $482,350.12 CAD
/// Today: up $1,520.44 (+0.32%)
/// Total return since inception: +18.70%
/// As of Oct 3, 2026 1:54 PM
/// ```
String buildPortfolioShareText(PortfolioShareSnapshot s) {
  final who = s.accountLabel == null || s.accountLabel!.trim().isEmpty
      ? 'My portfolio'
      : 'My ${s.accountLabel} portfolio';
  final today = switch (trendOf(s.dayChangeAmount)) {
    Trend.up =>
      'up ${Fmt.money(s.dayChangeAmount)} (${Fmt.signedPercentPoints(s.dayChangePercent)})',
    Trend.down =>
      'down ${Fmt.money(s.dayChangeAmount.abs())} (${Fmt.signedPercentPoints(s.dayChangePercent)})',
    Trend.flat => 'unchanged (0.00%)',
  };
  return [
    '$who: ${Fmt.money(s.totalMarketValue)} ${s.currency}',
    'Today: $today',
    'Total return since inception: ${Fmt.signedRatio(s.totalReturnSinceInception)}',
    if (s.asOf != null) 'As of ${Fmt.dateTime(s.asOf!)}',
  ].join('\n');
}

typedef ShareLauncher = Future<ShareResult> Function(ShareParams params);

/// Share icon button for the Core Portfolio Screen app bar.
///
/// Opens the OS share sheet with [buildPortfolioShareText]. Dismissing the
/// sheet is a normal outcome (no error shown); repeated taps while the sheet
/// is opening are ignored; platform errors show a SnackBar instead of
/// crashing. Disabled when [snapshot] is null (no data loaded yet).
class SharePortfolioButton extends StatefulWidget {
  const SharePortfolioButton({
    super.key,
    required this.snapshot,
    this.launcher,
  });

  final PortfolioShareSnapshot? snapshot;

  /// Injectable for tests; defaults to [SharePlus.instance.share].
  final ShareLauncher? launcher;

  @override
  State<SharePortfolioButton> createState() => _SharePortfolioButtonState();
}

class _SharePortfolioButtonState extends State<SharePortfolioButton> {
  bool _sharing = false;

  Future<void> _share() async {
    final snapshot = widget.snapshot;
    if (snapshot == null || _sharing) return;
    setState(() => _sharing = true);

    // iPad/macOS anchor the share popover to the button.
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final launcher = widget.launcher ?? SharePlus.instance.share;
      await launcher(ShareParams(
        text: buildPortfolioShareText(snapshot),
        subject: 'Portfolio snapshot',
        title: 'Share portfolio summary',
        sharePositionOrigin: origin,
      ));
      // ShareResultStatus.dismissed needs no handling: nothing was shared.
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not open the share sheet.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Share portfolio summary',
      icon: Icon(Icons.adaptive.share),
      onPressed: widget.snapshot == null || _sharing ? null : _share,
    );
  }
}

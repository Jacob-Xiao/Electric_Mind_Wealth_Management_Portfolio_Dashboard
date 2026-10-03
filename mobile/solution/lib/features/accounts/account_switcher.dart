import 'package:flutter/material.dart';

import '../shared/formatters.dart';
import 'account.dart';
import 'account_selection_controller.dart';

/// Task 8 — Account switcher header.
///
/// Shows the selected account's name and value. With 2+ accounts it is a
/// tappable pill that opens a native modal bottom sheet listing every account
/// with the current one checked. With exactly one account it renders as a
/// plain, non-interactive label (no chevron, no empty sheet).
class AccountSwitcher extends StatelessWidget {
  const AccountSwitcher({super.key, required this.controller});

  final AccountSelectionController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final selected = controller.selectedAccount;

        if (selected == null) {
          if (controller.isLoading) {
            return const SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (controller.error != null) {
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controller.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Could not load accounts. Retry'),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final interactive = controller.hasMultipleAccounts;
        final content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  selected.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (interactive) ...[
                const SizedBox(width: 4),
                Icon(Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        );

        return Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            button: interactive,
            label: interactive
                ? 'Account: ${selected.label}. Double tap to switch account.'
                : 'Account: ${selected.label}',
            excludeSemantics: true,
            child: Material(
              color: theme.colorScheme.secondaryContainer
                  .withValues(alpha: interactive ? 1 : 0.5),
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: interactive
                  ? InkWell(
                      onTap: () => showAccountPickerSheet(context, controller),
                      child: content,
                    )
                  : content,
            ),
          ),
        );
      },
    );
  }
}

/// Opens the account picker as a modal bottom sheet (drag handle, swipe down
/// to dismiss). Selecting a row switches account and closes the sheet.
Future<void> showAccountPickerSheet(
  BuildContext context,
  AccountSelectionController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => ListenableBuilder(
      listenable: controller,
      builder: (sheetContext, _) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text('Switch account',
                    style: theme.textTheme.titleMedium),
              ),
              for (final account in controller.accounts)
                _AccountTile(
                  account: account,
                  selected: account.accountId == controller.selectedAccountId,
                  onTap: () {
                    controller.select(account.accountId);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final Account account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      selected: selected,
      selectedTileColor:
          theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      leading: Icon(selected
          ? Icons.radio_button_checked
          : Icons.radio_button_unchecked),
      title: Text(account.label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      subtitle: Text(account.accountId),
      trailing: Text(Fmt.money(account.totalMarketValue),
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

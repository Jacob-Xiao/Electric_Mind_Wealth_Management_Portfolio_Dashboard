import 'dart:async';

import 'package:flutter/foundation.dart';

import 'account.dart';

/// Result of asking for a specific account (e.g. from a notification).
class AccountRequestResult {
  const AccountRequestResult({
    required this.requestedId,
    required this.selected,
  });

  final String requestedId;

  /// The account now selected; null if no accounts could be loaded.
  final Account? selected;

  bool get fellBack => selected?.accountId != requestedId;
}

/// Task 8 — Owns the account list and which account is selected.
///
/// The overview screen (Task 2) should listen to [selectedAccountId] and
/// load that portfolio. Task 6's deep-link handling calls [requestAccount].
class AccountSelectionController extends ChangeNotifier {
  AccountSelectionController({required Future<List<Account>> Function() loader})
      : _loader = loader;

  final Future<List<Account>> Function() _loader;

  List<Account> _accounts = const [];
  String? _selectedAccountId;
  bool _loading = false;
  Object? _error;
  Future<void>? _inFlight;
  String? _pendingRequestId;
  Completer<AccountRequestResult>? _pendingRequest;

  List<Account> get accounts => _accounts;
  String? get selectedAccountId => _selectedAccountId;
  bool get isLoading => _loading;
  Object? get error => _error;
  bool get hasMultipleAccounts => _accounts.length > 1;

  Account? get selectedAccount {
    for (final a in _accounts) {
      if (a.accountId == _selectedAccountId) return a;
    }
    return null;
  }

  /// Loads (or reloads) the account list. Concurrent calls share one request.
  Future<void> load() => _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      setAccounts(await _loader());
    } catch (e) {
      _error = e;
      _loading = false;
      // Don't leave a deep-link request hanging; report that nothing could
      // be selected so the caller can tell the user.
      final pending = _pendingRequest;
      if (pending != null) {
        pending.complete(AccountRequestResult(
          requestedId: _pendingRequestId!,
          selected: selectedAccount,
        ));
        _pendingRequest = null;
        _pendingRequestId = null;
      }
      notifyListeners();
    }
  }

  /// Replaces the account list (e.g. from a cache) and keeps the current
  /// selection if it still exists, otherwise falls back to the first account.
  void setAccounts(List<Account> accounts) {
    _accounts = List.unmodifiable(accounts);
    _loading = false;
    _error = null;
    if (_pendingRequestId != null) {
      _resolvePending();
    } else if (!_contains(_selectedAccountId)) {
      _selectedAccountId = _accounts.isEmpty ? null : _accounts.first.accountId;
    }
    notifyListeners();
  }

  void select(String accountId) {
    if (accountId == _selectedAccountId || !_contains(accountId)) return;
    _selectedAccountId = accountId;
    notifyListeners();
  }

  /// Selects [accountId] if it exists, otherwise the default (first) account.
  ///
  /// If accounts have not loaded yet, the request waits for the next
  /// successful load, so a cold-start notification tap still lands on the
  /// right account.
  Future<AccountRequestResult> requestAccount(String accountId) {
    _pendingRequest?.complete(AccountRequestResult(
      requestedId: _pendingRequestId!,
      selected: selectedAccount,
    ));
    _pendingRequestId = accountId;
    final completer = _pendingRequest = Completer<AccountRequestResult>();
    if (_accounts.isNotEmpty) {
      _resolvePending();
      notifyListeners();
    } else if (_inFlight == null) {
      unawaited(load());
    }
    return completer.future;
  }

  void _resolvePending() {
    final requested = _pendingRequestId!;
    _selectedAccountId = _contains(requested)
        ? requested
        : (_accounts.isEmpty ? null : _accounts.first.accountId);
    final completer = _pendingRequest!;
    _pendingRequestId = null;
    _pendingRequest = null;
    completer.complete(
      AccountRequestResult(requestedId: requested, selected: selectedAccount),
    );
  }

  bool _contains(String? id) =>
      id != null && _accounts.any((a) => a.accountId == id);
}

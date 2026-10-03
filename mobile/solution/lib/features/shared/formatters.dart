import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatting helpers shared by the Task 5–10 features.
///
/// Units follow mobile/API-CONTRACT.md: money is CAD, `dayChangePercent` is in
/// percentage points (2.4 = 2.4%), and `totalReturnSinceInception` /
/// `dividendYield` are ratios (0.187 = 18.7%).
class Fmt {
  Fmt._();

  static final NumberFormat _money =
      NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
  static final NumberFormat _compactMoney =
      NumberFormat.compactCurrency(locale: 'en_US', symbol: r'$');
  static final NumberFormat _quantity = NumberFormat.decimalPattern('en_US');
  static final DateFormat _date = DateFormat.yMMMd('en_US');
  static final DateFormat _dateTime = DateFormat('MMM d, y h:mm a', 'en_US');

  static String money(num value) => _money.format(value);

  /// `$1,520.44` with an explicit sign: `+$1,520.44` / `−$410.50`.
  static String signedMoney(num value) {
    if (value == 0) return _money.format(0);
    return '${value > 0 ? '+' : '−'}${_money.format(value.abs())}';
  }

  static String compactMoney(num value) => _compactMoney.format(value);

  static String quantity(num value) => _quantity.format(value);

  /// Formats a value already expressed in percentage points (2.4 → "+2.40%").
  static String signedPercentPoints(num points, {int decimals = 2}) {
    if (points == 0) return '${0.toStringAsFixed(decimals)}%';
    final sign = points > 0 ? '+' : '−';
    return '$sign${points.abs().toStringAsFixed(decimals)}%';
  }

  /// Formats a ratio (0.187 → "+18.70%").
  static String signedRatio(num ratio, {int decimals = 2}) =>
      signedPercentPoints(ratio * 100, decimals: decimals);

  /// Formats an unsigned ratio (0.005 → "0.50%").
  static String ratio(num ratio, {int decimals = 2}) =>
      '${(ratio * 100).toStringAsFixed(decimals)}%';

  static String date(DateTime date) => _date.format(date);

  static String dateTime(DateTime dateTime) =>
      _dateTime.format(dateTime.toLocal());

  /// Parses `YYYY-MM-DD` as a UTC calendar date. Returns null if malformed.
  static DateTime? parseIsoDate(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
}

/// Direction of a value change. Zero is neutral, never positive or negative.
enum Trend { up, down, flat }

Trend trendOf(num value) =>
    value > 0 ? Trend.up : (value < 0 ? Trend.down : Trend.flat);

/// Colours and icons for gains/losses, consistent across features.
class TrendStyle {
  TrendStyle._();

  static Color color(BuildContext context, num value) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (trendOf(value)) {
      Trend.up => dark ? const Color(0xFF5BD68A) : const Color(0xFF1B7F3B),
      Trend.down => dark ? const Color(0xFFFF8A80) : const Color(0xFFC62828),
      Trend.flat => scheme.onSurfaceVariant,
    };
  }

  static IconData icon(num value) => switch (trendOf(value)) {
        Trend.up => Icons.arrow_drop_up,
        Trend.down => Icons.arrow_drop_down,
        Trend.flat => Icons.remove,
      };
}

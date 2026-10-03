/// Number/currency formatting helpers. Money is CAD.
library;

/// Formats a monetary amount with thousands separators and two decimals,
/// e.g. 482350.12 -> "$482,350.12".
String formatCurrency(double value) =>
    '\$${_group(value.abs().toStringAsFixed(2))}';

/// Formats a signed monetary amount, e.g. -410.5 -> "-$410.50".
String formatSignedCurrency(double value) {
  final sign = _sign(value);
  return '$sign\$${_group(value.abs().toStringAsFixed(2))}';
}

/// Formats a percentage-point value as-is, e.g. 0.32 -> "+0.32%".
String formatPercentPoints(double value) =>
    '${_sign(value)}${value.abs().toStringAsFixed(2)}%';

/// Formats a ratio as a percentage, e.g. 0.187 -> "+18.7%".
String formatPercentRatio(double value) =>
    '${_sign(value)}${(value.abs() * 100).toStringAsFixed(1)}%';

String _sign(double value) => value > 0 ? '+' : (value < 0 ? '-' : '');

String _group(String value) {
  final dot = value.indexOf('.');
  final intPart = dot == -1 ? value : value.substring(0, dot);
  final frac = dot == -1 ? '' : value.substring(dot);
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  return '$buffer$frac';
}

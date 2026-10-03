import 'package:flutter/material.dart';

/// Gain color (positive change), green in the North-American convention.
const Color kGainColor = Color(0xFF1B7F3B);

/// Loss color (negative change).
const Color kLossColor = Color(0xFFC0392B);

/// Resolves a semantic color for a signed value: green for positive, red for
/// negative, and a neutral on-surface tone for exactly zero.
Color valueColor(BuildContext context, double value) {
  if (value > 0) return kGainColor;
  if (value < 0) return kLossColor;
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

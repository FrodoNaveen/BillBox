import 'package:flutter/material.dart';

/// The BillBox palette, taken from the UI design.
///
/// Kept as plain constants so the colour scheme in [AppTheme] and the few
/// places that need a raw value (the expiry badges, the scan screen) agree.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF006A6B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF9CF1F2);
  static const Color onPrimaryContainer = Color(0xFF002020);

  static const Color secondary = Color(0xFF4A6364);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCCE8E7);
  static const Color onSecondaryContainer = Color(0xFF051F20);

  /// Used for "expiring within a month" states.
  static const Color tertiary = Color(0xFF8A5100);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFDDB3);
  static const Color onTertiaryContainer = Color(0xFF4A3000);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF6D0008);

  static const Color surface = Color(0xFFF5FAFA);
  static const Color onSurface = Color(0xFF161D1D);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE7EFEF);
  static const Color onSurfaceVariant = Color(0xFF3F4949);
  static const Color outline = Color(0xFF6F7979);
  static const Color outlineVariant = Color(0xFFBFC8C8);

  /// Hairline used between rows inside a card.
  static const Color divider = Color(0xFFEDF1F1);

  /// Border around the white cards on the dashboard and lists.
  static const Color cardBorder = Color(0xFFDCE4E4);
}

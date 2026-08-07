import 'package:flutter/material.dart';

/// Palette and metrics shared by the storefront home (blue header, pill search,
/// department chips, product rail) and the bottom bar that goes with it.
///
/// Kept in one place so the header and the nav cannot drift apart, and so the
/// blue is defined once instead of being re-typed in five widgets.
class StorefrontTokens {
  const StorefrontTokens._();

  /// The header blue. Deliberately constant across light and dark: it is the
  /// brand surface, not a themed one, exactly like the store apps it mirrors.
  static const Color blue = Color(0xFF0071DC);
  static const Color blueDeep = Color(0xFF004F9A);
  static const Color yellow = Color(0xFFFFC220);

  static const double pillRadius = 26;
  static const double cardRadius = 16;

  /// Search field / chip fill. White on the blue header, a soft tint on the page.
  static Color chipFill(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFFF2F7FC);

  static Color chipText(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF2E2F32);

  /// Body copy on a card — near-black in light, near-white in dark.
  static Color bodyInk(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.color ?? const Color(0xFF2E2F32);

  /// Unselected tab tint. Near-black rather than a muted hint colour: on the
  /// storefront bar the inactive tabs read as solid, not as disabled.
  static Color navInk(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.85)
      : const Color(0xFF2E2F32);

  static Color hairline(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.12)
      : const Color(0xFFE4E7EC);
}

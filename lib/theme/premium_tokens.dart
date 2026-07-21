import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared visual language for the redesigned screens: gradients, elevation,
/// motion timing and radii built ON TOP of the app's existing theme
/// (Theme.of(context).primaryColor, Dimensions, robotoX styles) rather than
/// hardcoded values — so brand color, light/dark mode and text scale all
/// keep working exactly as they do everywhere else in the app.
class PremiumTokens {
  PremiumTokens._();

  // Motion — consistent, snappy, never sluggish.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeSpring = Curves.easeOutBack;
  static const Curve pageCurve = Curves.easeOutQuint;

  // Radii — one extra step above Dimensions.radiusExtraLarge for hero surfaces.
  static const double radiusPill = 100;
  static const double radiusHero = 28;
  static const double radiusCard = 22;
  static const double radiusChip = 14;

  /// Primary brand gradient — a subtle depth gradient, not a rainbow. Reads as
  /// premium because the two stops are close in hue, not because they clash.
  static LinearGradient brandGradient(BuildContext context) {
    final Color base = Theme.of(context).primaryColor;
    return LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [base, HSLColor.fromColor(base).withLightness(
        (HSLColor.fromColor(base).lightness * 0.72).clamp(0.0, 1.0),
      ).toColor()],
    );
  }

  /// Faint tinted surface used behind icons/badges — never full-opacity color.
  static Color tint(BuildContext context, {double opacity = 0.08}) =>
      Theme.of(context).primaryColor.withValues(alpha: opacity);

  /// Soft, long, low-opacity shadow — the "premium" shadow signature (Stripe/Airbnb
  /// style: big blur, tiny spread, near-invisible until you compare side by side).
  static List<BoxShadow> softShadow(BuildContext context, {double strength = 1}) {
    final bool dark = Get.isDarkMode;
    return [
      BoxShadow(
        color: (dark ? Colors.black : Theme.of(context).primaryColor.withValues(alpha: 0.16))
            .withValues(alpha: (dark ? 0.35 : 0.10) * strength),
        blurRadius: 24 * strength,
        offset: Offset(0, 10 * strength),
        spreadRadius: -6 * strength,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: (dark ? 0.25 : 0.04) * strength),
        blurRadius: 6 * strength,
        offset: Offset(0, 2 * strength),
      ),
    ];
  }

  /// Elevated shadow for floating/sticky surfaces (bottom bars, FABs).
  static List<BoxShadow> floatingShadow(BuildContext context) {
    final bool dark = Get.isDarkMode;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.4 : 0.08),
        blurRadius: 20, offset: const Offset(0, -4),
      ),
    ];
  }

  static Color glassSurface(BuildContext context) => Get.isDarkMode
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.55);

  static Color glassBorder(BuildContext context) => Get.isDarkMode
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.70);
}

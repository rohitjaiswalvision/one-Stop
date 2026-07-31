import 'package:get/get.dart';

class Dimensions {
  /// Design baseline: every scaled value is authored against a 375dp-wide phone.
  static const double _baseline = 375;

  // Captured once at startup. Get.context can be null if something touches Dimensions before
  // the first frame, in which case the baseline leaves every value at its authored size.
  static final double _screenWidth = Get.context?.width ?? _baseline;

  /// Scaling is keyed off the *shortest* edge, not the width, so a device does not resize
  /// its whole type ramp when it rotates. Reading width here meant an app launched in
  /// landscape got a different — and on phones, wrong — scale than the same device launched
  /// in portrait. Desktop is still detected by width, since a wide window is what makes a
  /// desktop layout, whatever the aspect ratio.
  static final double _shortestSide = Get.context?.mediaQuerySize.shortestSide ?? _baseline;

  static final bool _isDesktopWidth = _screenWidth >= 1300;

  /// Proportional text scale relative to the 375dp baseline so type adapts to every phone
  /// size. Clamped so a 375dp phone is identical to before, small phones shrink slightly
  /// (avoids overflow) and large phones grow slightly (fills the extra space). Desktop
  /// (>=1300) keeps its own fixed sizes.
  static final double _fontScale = _isDesktopWidth ? 1.0 : (_shortestSide / _baseline).clamp(0.85, 1.15);

  /// Same curve as [_fontScale], applied to lengths rather than type.
  ///
  /// The app carries roughly 2400 hardcoded `height:` / `width:` literals authored against a
  /// 375dp phone. Left raw they crowd a 320dp screen — a 56dp row plus 15dp padding plus
  /// grown type is what pushes a Column past the edge — and look lost on a tablet. Wrapping
  /// one in [scale] ties it to the same device curve the type already follows, so the
  /// proportions a screen was designed with hold at every size.
  ///
  /// Not for everything: hairlines, borders and small radii should stay literal, and a value
  /// that has to line up with a sibling must scale on both sides or neither.
  static double scale(double value) => value * _fontScale;

  /// Scales only upward from the baseline, never below it. For touch targets and anything
  /// else with a floor it must not drop under on a small phone.
  static double scaleUp(double value) => value * (_fontScale < 1 ? 1 : _fontScale);

  /// Smallest comfortable tap target. Anything interactive should be at least this on its
  /// short axis; below it, taps start landing on the neighbour.
  static double get minTapTarget => scaleUp(48);

  static double fontSizeOverSmall = (_isDesktopWidth ? 10 : 8) * _fontScale;
  static double fontSizeExtraSmall = (_isDesktopWidth ? 12 : 10) * _fontScale;
  static double fontSizeSmall = (_isDesktopWidth ? 14 : 12) * _fontScale;
  static double fontSizeDefault = (_isDesktopWidth ? 16 : 14) * _fontScale;
  static double fontSizeLarge = (_isDesktopWidth ? 18 : 16) * _fontScale;
  static double fontSizeExtraLarge = (_isDesktopWidth ? 20 : 18) * _fontScale;
  static double fontSizeOverLarge = (_isDesktopWidth ? 26 : 24) * _fontScale;

  static const double paddingSizeExtraSmall = 5.0;
  static const double paddingSizeSmall = 10.0;
  static const double paddingSizeDefault = 15.0;
  static const double paddingSizeLarge = 20.0;
  static const double paddingSizeExtraLarge = 25.0;
  static const double paddingSizeExtremeLarge = 30.0;
  static const double paddingSizeExtraOverLarge = 35.0;

  static const double radiusSmall = 5.0;
  static const double radiusMedium = 8.0;
  static const double radiusDefault = 10.0;
  static const double radiusLarge = 15.0;
  static const double radiusExtraLarge = 20.0;

  static const double webMaxWidth = 1170;
  static const int messageInputLength = 1000;

  static const double pickMapIconSize = 100.0;
}

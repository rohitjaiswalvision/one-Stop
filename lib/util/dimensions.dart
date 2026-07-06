import 'package:get/get.dart';

class Dimensions {
  // Device width, captured once (a phone doesn't change width at runtime).
  static final double _screenWidth = Get.context!.width;

  /// Proportional text scale relative to a 375dp design baseline so type adapts
  /// to every phone size. Clamped so a 375dp phone is identical to before, small
  /// phones shrink slightly (avoids overflow) and large phones grow slightly
  /// (fills the extra space). Desktop (>=1300) keeps its own fixed sizes.
  static final double _fontScale = _screenWidth >= 1300 ? 1.0 : (_screenWidth / 375).clamp(0.85, 1.15);

  static double fontSizeOverSmall = (_screenWidth >= 1300 ? 10 : 8) * _fontScale;
  static double fontSizeExtraSmall = (_screenWidth >= 1300 ? 12 : 10) * _fontScale;
  static double fontSizeSmall = (_screenWidth >= 1300 ? 14 : 12) * _fontScale;
  static double fontSizeDefault = (_screenWidth >= 1300 ? 16 : 14) * _fontScale;
  static double fontSizeLarge = (_screenWidth >= 1300 ? 18 : 16) * _fontScale;
  static double fontSizeExtraLarge = (_screenWidth >= 1300 ? 20 : 18) * _fontScale;
  static double fontSizeOverLarge = (_screenWidth >= 1300 ? 26 : 24) * _fontScale;

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

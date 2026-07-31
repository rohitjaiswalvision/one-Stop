import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Layout decisions go through this helper.
///
/// Two different questions get asked of a screen, and they are not the same question:
///
/// * **How much room is there right now?** — the window size class ([windowSize] and the
///   [isCompact] / [isMedium] / [isExpanded] / [isLarge] shorthands). Width-based, so it
///   changes when a phone rotates or a browser window is dragged. Use it to pick column
///   counts, to decide whether a rail sits beside the content or under it, to size dialogs.
/// * **What kind of device is this?** — [isPhoneDevice] / [isTabletDevice]. Keyed off the
///   shortest side, so rotating a phone does not turn it into a tablet. Use it for choices
///   that must survive rotation, such as base type and icon scale.
///
/// [isMobile], [isTab], [isDesktop], [isWeb] and [isMobilePhone] are left exactly as they
/// were: roughly 700 call sites and the whole `web_*` screen family depend on their current
/// behaviour. New work should reach for the members below rather than redefine those.
class ResponsiveHelper {

  /// Window size class boundaries in logical pixels, following the Material 3 breakpoints.
  ///
  /// Deliberately not the legacy 650/1300 pair used by [isTab] and [isDesktop]: 600 and 840
  /// are where phone-portrait, phone-landscape/small-tablet and large-tablet layouts
  /// actually diverge. [largeMinWidth] does match the legacy desktop threshold, so the two
  /// systems at least agree on what counts as a desktop-sized window.
  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 840;
  static const double largeMinWidth = 1300;

  /// A viewport shorter than this cannot hold a full-height header plus its content —
  /// landscape phones live here, and it is where fixed-height columns overflow.
  static const double shortViewportMaxHeight = 600;

  /// Widest a centred content column is allowed to get, so lines do not run edge to edge on
  /// a 10-inch tablet or a maximised browser window.
  static const double desktopContentMaxWidth = 1170;
  static const double tabletContentMaxWidth = 840;

  static bool isMobilePhone() {
    if (!kIsWeb) {
      return true;
    }else {
      return false;
    }
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isMobile(BuildContext? context) {
    final size = MediaQuery.of(context!).size.width;
    if (size < 650 || !kIsWeb) {
      return true;
    } else {
      return false;
    }
  }

  static bool isTab(BuildContext? context) {
    final size = MediaQuery.of(context!).size.width;
    if (size < 1300 && size >= 650) {
      return true;
    } else {
      return false;
    }
  }

  static bool isDesktop(BuildContext? context) {
    final size = MediaQuery.of(context!).size.width;
    if (size >= 1300) {
      return true;
    } else {
      return false;
    }
  }

  // ---------------------------------------------------------------------------------------
  // Window size class — how much room there is right now. Changes on rotation and resize.
  // ---------------------------------------------------------------------------------------

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// The shorter of the two edges. Rotation-stable, which is what makes it a usable proxy
  /// for the physical size of the device rather than the shape of the current window.
  static double shortestSide(BuildContext context) => MediaQuery.sizeOf(context).shortestSide;

  static WindowSize windowSize(BuildContext context) {
    final double w = width(context);
    if (w >= largeMinWidth) return WindowSize.large;
    if (w >= expandedMinWidth) return WindowSize.expanded;
    if (w >= mediumMinWidth) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// Phone portrait, and anything else under 600dp wide.
  static bool isCompact(BuildContext context) => windowSize(context) == WindowSize.compact;

  /// Phone landscape and small tablets: 600–839dp.
  static bool isMedium(BuildContext context) => windowSize(context) == WindowSize.medium;

  /// Large tablets and mid-size browser windows: 840–1299dp.
  static bool isExpanded(BuildContext context) => windowSize(context) == WindowSize.expanded;

  /// Desktop-sized windows: 1300dp and up. Same threshold as [isDesktop].
  static bool isLarge(BuildContext context) => windowSize(context) == WindowSize.large;

  /// At least tablet-width *right now*. True for a landscape phone, which is usually the
  /// right call for column counts — for anything that must not flip on rotation, use
  /// [isTabletDevice].
  static bool isAtLeastMedium(BuildContext context) => width(context) >= mediumMinWidth;

  // ---------------------------------------------------------------------------------------
  // Device class — survives rotation.
  // ---------------------------------------------------------------------------------------

  /// A native tablet or foldable: 600dp or more on its shortest edge. False on web, where
  /// window size says nothing about the device and the `web_*` layouts already apply.
  static bool isTabletDevice(BuildContext context) => !kIsWeb && shortestSide(context) >= mediumMinWidth;

  static bool isPhoneDevice(BuildContext context) => !kIsWeb && shortestSide(context) < mediumMinWidth;

  static bool isLandscape(BuildContext context) => MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Too short to lay content out vertically without scrolling — landscape phones, and a
  /// portrait phone with the keyboard up. Screens with a fixed-height header or a
  /// non-scrolling [Column] have to collapse or scroll here.
  static bool isShortViewport(BuildContext context) => height(context) < shortViewportMaxHeight;

  /// True while the soft keyboard is covering part of the screen.
  static bool isKeyboardOpen(BuildContext context) => MediaQuery.viewInsetsOf(context).bottom > 0;

  // ---------------------------------------------------------------------------------------
  // Layout maths.
  // ---------------------------------------------------------------------------------------

  /// Width a centred content column should be capped at. Unbounded on a phone, held back on
  /// tablets and desktops.
  static double contentMaxWidth(BuildContext context) {
    switch (windowSize(context)) {
      case WindowSize.compact:
        return double.infinity;
      case WindowSize.medium:
      case WindowSize.expanded:
        return tabletContentMaxWidth;
      case WindowSize.large:
        return desktopContentMaxWidth;
    }
  }

  /// Column count for a grid, per window size. Callers pass what each class should use so
  /// the decision stays visible where the grid is built instead of hidden in here.
  static int gridColumns(BuildContext context, {int compact = 1, int? medium, int? expanded, int? large}) {
    switch (windowSize(context)) {
      case WindowSize.compact:
        return compact;
      case WindowSize.medium:
        return medium ?? compact * 2;
      case WindowSize.expanded:
        return expanded ?? medium ?? compact * 2;
      case WindowSize.large:
        return large ?? expanded ?? medium ?? compact * 3;
    }
  }

  /// Picks the value matching the current window size, falling back down the chain to the
  /// next smaller one supplied. Reads better than nested ternaries at call sites that vary
  /// a single number across breakpoints.
  static T value<T>(BuildContext context, {required T compact, T? medium, T? expanded, T? large}) {
    switch (windowSize(context)) {
      case WindowSize.compact:
        return compact;
      case WindowSize.medium:
        return medium ?? compact;
      case WindowSize.expanded:
        return expanded ?? medium ?? compact;
      case WindowSize.large:
        return large ?? expanded ?? medium ?? compact;
    }
  }
}

/// Material 3 window size classes. See [ResponsiveHelper.windowSize].
enum WindowSize { compact, medium, expanded, large }
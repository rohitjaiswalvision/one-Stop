import 'package:flutter/material.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';

/// Centres its child and caps how wide it is allowed to grow.
///
/// The app already centres content at `Dimensions.webMaxWidth` in around 200 places, which
/// handles a maximised browser but does nothing for a native tablet: `SizedBox(width: 1170)`
/// inside an 800dp-wide window is simply 800dp, so a phone layout ends up stretched across
/// a 10-inch screen with rows of text running the full width.
///
/// This caps per window size instead — unbounded on a phone, 840dp on tablets, 1170dp on
/// desktop (see [ResponsiveHelper.contentMaxWidth]) — so the same subtree reads correctly at
/// every size without the caller repeating the breakpoints.
///
/// Give it a [maxWidth] to override the default cap for one call site. It intentionally does
/// not add padding: horizontal insets stay with the content, where they can differ per row.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth, this.alignment = Alignment.topCenter});

  final Widget child;

  /// Overrides the per-window-size cap. Useful for a narrow form on a wide screen.
  final double? maxWidth;

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? ResponsiveHelper.contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}

/// A [ResponsiveCenter] for a sliver-based scroll view.
///
/// [CustomScrollView] slivers cannot be wrapped in a box widget, so the home feed and the
/// other sliver screens need this form to get the same cap.
class SliverResponsiveCenter extends StatelessWidget {
  const SliverResponsiveCenter({super.key, required this.sliver, this.maxWidth});

  final Widget sliver;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final double cap = maxWidth ?? ResponsiveHelper.contentMaxWidth(context);
    if (cap == double.infinity) {
      return sliver;
    }
    final double padding = ((ResponsiveHelper.width(context) - cap) / 2).clamp(0, double.infinity);
    return SliverPadding(padding: EdgeInsets.symmetric(horizontal: padding), sliver: sliver);
  }
}

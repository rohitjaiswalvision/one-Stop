import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// The base premium surface: rounded, soft-shadowed, theme-aware card used for
/// every grouped content block (list rows, summary panels, form sections).
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool elevated;
  const PremiumCard({
    super.key, required this.child,
    this.padding = const EdgeInsets.all(Dimensions.paddingSizeLarge),
    this.margin, this.radius = PremiumTokens.radiusCard, this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated ? PremiumTokens.softShadow(context) : null,
        border: elevated ? null : Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

/// Frosted-glass surface for content sitting on top of imagery (hero headers,
/// map overlays). Used sparingly per the brief — glassmorphism only where it
/// earns its keep, not as a blanket style.
class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const PremiumGlassCard({
    super.key, required this.child,
    this.padding = const EdgeInsets.all(Dimensions.paddingSizeDefault),
    this.radius = PremiumTokens.radiusCard,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: PremiumTokens.glassSurface(context),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: PremiumTokens.glassBorder(context)),
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Primary CTA: brand-gradient fill, press-scale feedback, optional loading spinner.
/// Height/width sized to be the single confident action on a screen — never
/// competing with a secondary button of the same weight.
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;
  const PremiumButton({
    super.key, required this.text, this.onPressed, this.isLoading = false,
    this.icon, this.height = 56, this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    return PressableScale(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: PremiumTokens.fast,
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
          gradient: disabled ? null : PremiumTokens.brandGradient(context),
          color: disabled ? Theme.of(context).disabledColor.withValues(alpha: 0.25) : null,
          boxShadow: disabled ? null : PremiumTokens.softShadow(context, strength: 0.8),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                ],
                Text(text, style: robotoSemiBold.copyWith(
                  color: Colors.white, fontSize: Dimensions.fontSizeLarge, letterSpacing: 0.2,
                )),
              ]),
      ),
    );
  }
}

/// Secondary action — outline only, never fights the primary button for attention.
class PremiumOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  const PremiumOutlineButton({super.key, required this.text, this.onPressed, this.icon, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.35), width: 1.4),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
            const SizedBox(width: Dimensions.paddingSizeSmall),
          ],
          Text(text, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ]),
      ),
    );
  }
}

/// Small pill icon button — favourite, share, back-on-image, cart-step controls.
class PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? iconColor;
  final double size;
  const PremiumIconButton({
    super.key, required this.icon, this.onTap, this.background, this.iconColor, this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: size, width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? PremiumTokens.glassSurface(context),
          border: Border.all(color: PremiumTokens.glassBorder(context)),
          boxShadow: PremiumTokens.softShadow(context, strength: 0.5),
        ),
        child: Icon(icon, size: size * 0.46, color: iconColor ?? Theme.of(context).textTheme.bodyLarge!.color),
      ),
    );
  }
}

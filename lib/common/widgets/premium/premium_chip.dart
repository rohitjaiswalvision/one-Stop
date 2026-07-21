import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Pill filter/category chip with a selected (filled, brand-gradient) and
/// unselected (tinted outline) state — used across Search filters, Store
/// category rows and the order-type / payment-type selectors.
class PremiumChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  const PremiumChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PremiumTokens.fast,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
          gradient: selected ? PremiumTokens.brandGradient(context) : null,
          color: selected ? null : PremiumTokens.tint(context, opacity: 0.06),
          border: selected ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color),
            const SizedBox(width: 6),
          ],
          Text(label, style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color,
          )),
        ]),
      ),
    );
  }
}

/// Small status label (order/booking state) — tinted background, colored text,
/// no border. Color is passed in so callers can keep using the app's existing
/// status→color maps (buttonBackgroundColorMap / buttonTextColorMap).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(PremiumTokens.radiusChip),
      ),
      child: Text(label, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color)),
    );
  }
}

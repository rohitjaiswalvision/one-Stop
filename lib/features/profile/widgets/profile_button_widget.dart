import 'package:flutter/cupertino.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';

/// One settings/profile row: tinted icon badge, title, and a trailing control
/// (switch, language pill, or a plain chevron for a plain navigation row).
class ProfileButtonWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final bool? isButtonActive;
  final Function onTap;
  final Color? color;
  final String? iconImage;
  final String? languageName;
  const ProfileButtonWidget({super.key, this.icon, required this.title, required this.onTap, this.isButtonActive, this.color, this.iconImage, this.languageName});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap as void Function()?,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(PremiumTokens.radiusCard),
          boxShadow: PremiumTokens.softShadow(context, strength: 0.5),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.10),
            ),
            child: iconImage != null ? Image.asset(iconImage!, height: 18, width: 20)
                : Icon(icon, size: 20, color: color ?? Theme.of(context).primaryColor),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Text(title, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault))),

          isButtonActive != null ? Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: isButtonActive!,
              activeTrackColor: Theme.of(context).primaryColor,
              onChanged: (bool? value) => onTap(),
              inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
          ) : languageName != null ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
              color: PremiumTokens.tint(context, opacity: 0.08),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
            child: Row(
              children: [
                Text(languageName!, style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor,
                )),
                const SizedBox(width: 4),

                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Theme.of(context).primaryColor),
              ],
            ),
          ) : Icon(Icons.chevron_right_rounded, size: 22, color: Theme.of(context).disabledColor),
        ]),
      ),
    );
  }
}

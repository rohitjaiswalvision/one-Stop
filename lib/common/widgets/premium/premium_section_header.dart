import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// "Section title" + optional "See all" — the recurring rhythm marker between
/// content blocks on Home, Store Details, Search and similar feed screens.
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;
  const PremiumSectionHeader({
    super.key, required this.title, this.subtitle, this.onSeeAll,
    this.padding = const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, letterSpacing: -0.2)),
          if (subtitle != null) Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!, style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
            )),
          ),
        ])),
        if (onSeeAll != null) InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onSeeAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('see_all'.tr, style: robotoSemiBold.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor,
              )),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Theme.of(context).primaryColor),
            ]),
          ),
        ),
      ]),
    );
  }
}

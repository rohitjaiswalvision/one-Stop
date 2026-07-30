import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

void showCartSnackBar({VoidCallback? onAddMore}) {
  ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
  ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
    dismissDirection: DismissDirection.horizontal,
    margin: EdgeInsets.only(
      right: ResponsiveHelper.isDesktop(Get.context) ? Get.context!.width * 0.7 : Dimensions.paddingSizeSmall,
      top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall,
    ),
    duration: const Duration(seconds: 3),
    backgroundColor: Colors.green.shade700,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
    content: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'item_added_to_cart'.tr,
            style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onAddMore != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
              onAddMore();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.green.shade800),
                  const SizedBox(width: 2),
                  Text(
                    'add_more'.tr,
                    style: robotoBold.copyWith(color: Colors.green.shade800, fontSize: Dimensions.fontSizeExtraSmall),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
            Get.toNamed(RouteHelper.getCartRoute());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              'view_cart'.tr,
              style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall, decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    ),
  ));
}
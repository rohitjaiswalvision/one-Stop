import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/storefront/storefront_product_card.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// "Reorder your essentials" — a horizontal rail of buyable tiles with a link out
/// to the full list.
///
/// Prefers what the customer has bought before (recommended, which the backend
/// builds from order history) and falls back to what is popular, so the rail is
/// never empty for someone on their first visit.
class StorefrontReorderView extends StatelessWidget {
  const StorefrontReorderView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemController>(builder: (itemController) {
      final List<Item> items = itemController.recommendedItemList?.isNotEmpty == true
          ? itemController.recommendedItemList!
          : (itemController.popularItemList ?? []);
      if(items.isEmpty) return const SizedBox();

      final int visible = items.length > 12 ? 12 : items.length;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
          ),
          child: Row(children: [

            Expanded(child: Text(
              'reorder_your_essentials'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            )),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            InkWell(
              onTap: () => Get.toNamed(RouteHelper.getCategoryRoute()),
              child: Text('shop_my_items'.tr, style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                decoration: TextDecoration.underline,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )),
            ),
          ]),
        ),

        SizedBox(
          height: StorefrontProductCard.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: visible,
            separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) => StorefrontProductCard(
              item: items[index],
              // Mirrors how the rails mark paid placement: the lead tile only.
              isSponsored: index == 0,
            ),
          ),
        ),
      ]);
    });
  }
}

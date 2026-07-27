import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/card_design/item_card.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// "Item that you'll love": a horizontal, scrollable rail of the standard small
/// item cards — same shape as the Most Popular and Similar Products rails —
/// replacing the old Tinder swiper (shop) / rotating full-width carousel.
class ItemThatYouLoveView extends StatelessWidget {
  final bool forShop;
  const ItemThatYouLoveView({super.key, required this.forShop});

  @override
  Widget build(BuildContext context) {
    final bool isFood = Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.food;
    final bool isShop = Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.ecommerce;

    return GetBuilder<ItemController>(builder: (itemController) {
      List<Item>? recommendItems = itemController.recommendedItemList;

      return recommendItems != null ? recommendItems.isNotEmpty ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
          child: Align(
            alignment: forShop ? Alignment.center : Alignment.centerLeft,
            child: Text('item_that_you_love'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ),
        ),

        SizedBox(
          height: 285,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            itemCount: recommendItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
                child: ItemCard(
                  item: recommendItems[index],
                  isFood: isFood, isShop: isShop,
                ),
              );
            },
          ),
        ),

      ]) : const SizedBox() : ItemThatYouLoveShimmerView(forShop: forShop);
    });
  }
}

class ItemThatYouLoveShimmerView extends StatelessWidget {
  final bool forShop;
  const ItemThatYouLoveShimmerView({super.key, required this.forShop});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
        child: Align(
          alignment: forShop ? Alignment.center : Alignment.centerLeft,
          child: Text('item_that_you_love'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),
      ),

      SizedBox(
        height: 285,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
              child: Shimmer(
                duration: const Duration(seconds: 2),
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  ),
                ),
              ),
            );
          },
        ),
      ),

    ]);
  }
}

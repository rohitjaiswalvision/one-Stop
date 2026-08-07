import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/home/widgets/storefront/storefront_tokens.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// One tile of a storefront rail: wishlist heart, product shot, an action pill,
/// the price with raised cents, two lines of title and a fulfilment badge.
///
/// Sized rather than flexible — the rails are horizontal, so every tile has to
/// declare its own width and the row has to agree on a height.
class StorefrontProductCard extends StatelessWidget {
  final Item item;
  final bool isSponsored;
  static const double width = 158;
  static const double height = 330;

  const StorefrontProductCard({super.key, required this.item, this.isSponsored = false});

  @override
  Widget build(BuildContext context) {
    // A configurable item (variations/add-ons) opens its sheet to be configured;
    // a plain one is a straight add. The label has to say which is coming.
    final bool hasChoices = (item.variations?.isNotEmpty ?? false)
        || (item.foodVariations?.isNotEmpty ?? false)
        || (item.addOns?.isNotEmpty ?? false);

    return InkWell(
      onTap: () => Get.find<ItemController>().navigateToItemPage(item, context),
      borderRadius: BorderRadius.circular(StorefrontTokens.cardRadius),
      child: SizedBox(
        width: width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          SizedBox(
            height: 150,
            child: Stack(children: [

              Center(child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: CustomImage(image: item.imageFullUrl ?? '', height: 140, width: width, fit: BoxFit.contain),
              )),

              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                    return CustomFavouriteWidget(
                      isWished: favouriteController.wishItemIdList.contains(item.id),
                      item: item, size: 20,
                    );
                  }),
                ),
              ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          _actionPill(context, hasChoices: hasChoices),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          if(isSponsored) Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('sponsored'.tr, style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor,
            )),
          ),

          _price(context),
          const SizedBox(height: 2),

          Text(
            item.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: StorefrontTokens.bodyInk(context)),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          _fulfilmentBadge(context),
        ]),
      ),
    );
  }

  Widget _actionPill(BuildContext context, {required bool hasChoices}) {
    return InkWell(
      onTap: () => Get.find<ItemController>().navigateToItemPage(item, context),
      borderRadius: BorderRadius.circular(StorefrontTokens.pillRadius),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(StorefrontTokens.pillRadius),
          border: Border.all(color: StorefrontTokens.bodyInk(context).withValues(alpha: 0.55)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [

          if(!hasChoices) ...[
            Icon(Icons.add, size: 18, color: StorefrontTokens.bodyInk(context)),
            const SizedBox(width: 2),
          ],

          Text(
            hasChoices ? 'options'.tr : 'add'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: StorefrontTokens.bodyInk(context)),
          ),
        ]),
      ),
    );
  }

  /// "$19⁹⁷" — the cents ride high and small, the way shelf tickets print them.
  /// Falls back to the plain formatted string for currencies the split misses.
  Widget _price(BuildContext context) {
    final String formatted = PriceConverter.convertPrice(
      item.price, discount: item.discount, discountType: item.discountType,
    );
    final RegExpMatch? match = RegExp(r'^(.*[.,])(\d{2})(\D*)$').firstMatch(formatted);

    final TextStyle main = robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: StorefrontTokens.bodyInk(context));

    if(match == null) {
      return Text(formatted, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: main);
    }

    // Drop the separator with the whole part: "$19." reads as "$19" once the
    // cents are lifted out of the baseline.
    final String whole = match.group(1)!.substring(0, match.group(1)!.length - 1);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, textDirection: TextDirection.ltr, children: [
      Flexible(child: Text(whole, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: main)),
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${match.group(2)}${match.group(3)}', textDirection: TextDirection.ltr,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: StorefrontTokens.bodyInk(context)),
        ),
      ),
    ]);
  }

  Widget _fulfilmentBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 3),
      decoration: BoxDecoration(
        color: StorefrontTokens.blue,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.bolt, size: 13, color: StorefrontTokens.yellow),
        const SizedBox(width: 2),

        Flexible(child: Text(
          'get_it_fast'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoMedium.copyWith(fontSize: 10, color: Colors.white),
        )),
      ]),
    );
  }
}

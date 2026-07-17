import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/category/widgets/service_detail_bottom_sheet.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/html_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/square_feet_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// The service module's "Select a service" list — shared by the category landing
/// page and the provider (store) detail page. Handles its own loading shimmer
/// (items null) and empty state (items empty).
class ServiceItemsListView extends StatelessWidget {
  final List<Item>? items;
  final EdgeInsetsGeometry padding;
  const ServiceItemsListView({
    super.key, required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
  });

  @override
  Widget build(BuildContext context) {
    if (items == null) {
      return ServiceCardShimmer(padding: padding);
    }
    if (items!.isEmpty) {
      return NoDataScreen(text: 'no_services_in_this_category'.tr);
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: items!.length,
      separatorBuilder: (_, _) => Divider(
        height: Dimensions.paddingSizeLarge * 2,
        color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
      ),
      itemBuilder: (BuildContext context, int index) => Container(),
    );
  }
}

/// One "Select a service" row: name, starting price, short description and
/// View details on the left; image with the Add button pinned under it on the right.
// class ServiceSubCategoryCard extends StatelessWidget {
//   final Item item;
//   const ServiceSubCategoryCard({super.key, required this.item});

//   @override
//   Widget build(BuildContext context) {
//     final String description = HtmlHelper.toPlainText(item.description);

//     // The whole row opens the detail sheet — same as View details — so tapping a
//     // service behaves the same wherever the card appears.
//     return InkWell(
//       borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//       onTap: () => ServiceDetailBottomSheet.show(item),
//       child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

//       Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(
//           item.name ?? '',
//           style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
//           maxLines: 2, overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: Dimensions.paddingSizeExtraSmall),

//         Text(
//           '${'starts_at'.tr} ${PriceConverter.convertPrice(item.price)}${SquareFeetHelper.perUnitSuffix(item)}',
//           style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
//         ),

//         if (description.isNotEmpty) Padding(
//           padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
//           child: Text(
//             description,
//             style: robotoRegular.copyWith(
//               fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
//             ),
//             maxLines: 3, overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         const SizedBox(height: Dimensions.paddingSizeSmall),

//         InkWell(
//           onTap: () => ServiceDetailBottomSheet.show(item),
//           child: Text('view_details'.tr, style: robotoMedium.copyWith(
//             fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor,
//           )),
//         ),
//       ])),
//       const SizedBox(width: Dimensions.paddingSizeDefault),

//       SizedBox(width: 110, child: Column(children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
//           child: CustomImage(image: '${item.imageFullUrl}', height: 90, width: 110, fit: BoxFit.cover),
//         ),

//         Transform.translate(
//           offset: const Offset(0, -16),
//           child: SizedBox(height: 32, width: 76, child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).cardColor,
//               foregroundColor: Theme.of(context).primaryColor,
//               side: BorderSide(color: Theme.of(context).primaryColor),
//               padding: EdgeInsets.zero,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
//             ),
//             onPressed: () => Get.find<ItemController>().itemDirectlyAddToCart(item, context),
//             child: Text('add'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
//           )),
//         ),
//       ])),
//       ]),
//     );
//   }
// }

class ServiceCardShimmer extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const ServiceCardShimmer({
    super.key, this.padding = const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: 5,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
        child: Shimmer(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 16, width: 180, color: Theme.of(context).shadowColor),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Container(height: 12, width: 100, color: Theme.of(context).shadowColor),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Container(height: 30, width: double.infinity, color: Theme.of(context).shadowColor),
          ])),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Container(
            height: 90, width: 110,
            decoration: BoxDecoration(
              color: Theme.of(context).shadowColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
        ])),
      ),
    );
  }
}

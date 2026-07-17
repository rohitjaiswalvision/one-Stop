import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/service_catalog_model.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/html_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/square_feet_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// "View details" of one bookable service, as a bottom sheet instead of the full
/// item-details page: image gallery, price, duration and where it can be performed,
/// then the long description and the provider's requirements, and one Add action.
///
/// Opens with the data already on the list card and enriches it from the catalog
/// detail endpoint (`/services/catalog/sub-categories/{id}`) once that responds —
/// so the sheet is instant, never blocked on the network.
class ServiceDetailBottomSheet extends StatefulWidget {
  final Item item;
  const ServiceDetailBottomSheet({super.key, required this.item});

  static void show(Item item) {
    final Widget sheet = ServiceDetailBottomSheet(item: item);
    if (ResponsiveHelper.isMobile(Get.context)) {
      Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    } else {
      Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    }
  }

  @override
  State<ServiceDetailBottomSheet> createState() => _ServiceDetailBottomSheetState();
}

class _ServiceDetailBottomSheetState extends State<ServiceDetailBottomSheet> {
  CatalogSubCategoryModel? _detail;

  @override
  void initState() {
    super.initState();

    if (widget.item.id != null) {
      Get.find<ServiceCategoryController>().categoryServiceInterface
          .getCatalogSubCategoryDetail(widget.item.id!)
          .then((CatalogSubCategoryModel? detail) {
        if (mounted && detail != null) {
          setState(() => _detail = detail);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Item item = widget.item;
    final String about = HtmlHelper.toPlainText(
      (_detail?.itemDescription?.isNotEmpty ?? false) ? _detail!.itemDescription : item.description,
    );
    final String requirements = HtmlHelper.toPlainText(_detail?.requirements);
    final List<String> images = _detail?.imagesFullUrl
        ?? (item.imageFullUrl != null ? <String>[item.imageFullUrl!] : <String>[]);
    final String? duration = _detail?.serviceDuration;
    final bool homeService = _detail?.homeService ?? item.homeService ?? false;
    final bool atStore = _detail?.atStore ?? item.atStore ?? false;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85, maxWidth: 550),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Container(
          height: 4, width: 40,
          margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        Flexible(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

            if (images.isNotEmpty) SizedBox(height: 160, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: images.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeSmall),
              itemBuilder: (BuildContext context, int index) => ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: CustomImage(
                  image: images[index],
                  height: 160, width: images.length == 1 ? 500 : 220, fit: BoxFit.cover,
                ),
              ),
            )),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text(
              item.name ?? '',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Text(
              '${'starts_at'.tr} ${PriceConverter.convertPrice(item.price)}${SquareFeetHelper.perUnitSuffix(item)}',
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Wrap(spacing: Dimensions.paddingSizeSmall, runSpacing: Dimensions.paddingSizeExtraSmall, children: [
              if (duration != null && duration.isNotEmpty)
                _chip(context, Icons.schedule, duration),
              if (homeService) _chip(context, Icons.home_outlined, 'home_service'.tr),
              if (atStore) _chip(context, Icons.storefront_outlined, 'at_store'.tr),
            ]),

            if (about.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text('about_this_service'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(about, style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color,
              )),
            ],

            if (requirements.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text('requirements'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(requirements, style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color,
              )),
            ],
          ]),
        )),

        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
          ),
          child: CustomButton(
            buttonText: 'add'.tr,
            onPressed: () {
              // Close first: the add flow opens its own sheets (area entry / work note).
              Get.back();
              Get.find<ItemController>().itemDirectlyAddToCart(widget.item, Get.context!);
            },
          ),
        )),
      ]),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Theme.of(context).primaryColor),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text(label, style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
        )),
      ]),
    );
  }
}

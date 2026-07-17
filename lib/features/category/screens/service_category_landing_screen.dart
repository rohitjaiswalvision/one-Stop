import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/widgets/service_detail_bottom_sheet.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/widgets/bottom_cart_widget.dart';
import 'package:sixam_mart/helper/html_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/square_feet_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// Landing page of one catalog category (services → categories sheet → *here*).
///
/// Header carries the category name and a rating line derived from the services
/// actually loaded; below it, the "Select a service" list — one card per bookable
/// sub-category with its starting price, a short description, View details, and Add.
class ServiceCategoryLandingScreen extends StatefulWidget {
  final String? categoryId;
  final String? serviceId;
  final String categoryName;
  const ServiceCategoryLandingScreen({
    super.key, required this.categoryId, required this.serviceId, required this.categoryName,
  });

  @override
  State<ServiceCategoryLandingScreen> createState() => _ServiceCategoryLandingScreenState();
}

class _ServiceCategoryLandingScreenState extends State<ServiceCategoryLandingScreen> {
  final ScrollController _scrollController = ScrollController();

  int get _sectionId => int.tryParse(widget.categoryId ?? '') ?? -1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ServiceCategoryController>().initCatalogCategory(
        serviceId: widget.serviceId ?? '', categoryId: widget.categoryId ?? '',
        categoryName: widget.categoryName,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        Get.find<ServiceCategoryController>().loadMore(_sectionId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<ServiceCategoryController>(builder: (ServiceCategoryController controller) {
      final List<Item>? items = controller.itemsOf(_sectionId);

      return Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: isDesktop ? const WebMenuBar() : AppBar(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Theme.of(context).cardColor,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).textTheme.bodyLarge!.color),
            onPressed: () => Get.back(),
          ),
          title: Text(widget.categoryName, style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color,
          )),
        ),
        endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,

        bottomNavigationBar: GetBuilder<CartController>(builder: (CartController cartController) {
          return cartController.cartList.isNotEmpty && !isDesktop
              ? const BottomCartWidget() : const SizedBox();
        }),

        body: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Center(child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, 0,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    controller.parentName ?? widget.categoryName,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),

                  if (controller.showRatingLine) Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                    child: Row(children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        controller.derivedRating.toStringAsFixed(1),
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        '(${controller.derivedRatingCount} ${'ratings'.tr})',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Text('select_a_service'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              items == null
                  ? const _ServiceCardShimmer()
                  : items.isEmpty
                      ? NoDataScreen(text: 'no_services_in_this_category'.tr)
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => Divider(
                            height: Dimensions.paddingSizeLarge * 2,
                            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                          ),
                          itemBuilder: (BuildContext context, int index) => ServiceSubCategoryCard(item: items[index]),
                        ),

              if (controller.isSectionBusy(_sectionId)) Center(child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              )),

              const SizedBox(height: 100),
            ]),
          )),
        ),
      );
    });
  }
}

/// One "Select a service" row: name, starting price, short description and
/// View details on the left; image with the Add button pinned under it on the right.
class ServiceSubCategoryCard extends StatelessWidget {
  final Item item;
  const ServiceSubCategoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String description = HtmlHelper.toPlainText(item.description);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          item.name ?? '',
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Text(
          '${'starts_at'.tr} ${PriceConverter.convertPrice(item.price)}${SquareFeetHelper.perUnitSuffix(item)}',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
        ),

        if (description.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
          child: Text(
            description,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
            ),
            maxLines: 3, overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        InkWell(
          onTap: () => ServiceDetailBottomSheet.show(item),
          child: Text('view_details'.tr, style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor,
          )),
        ),
      ])),
      const SizedBox(width: Dimensions.paddingSizeDefault),

      SizedBox(width: 110, child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: CustomImage(image: '${item.imageFullUrl}', height: 90, width: 110, fit: BoxFit.cover),
        ),

        Transform.translate(
          offset: const Offset(0, -16),
          child: SizedBox(height: 32, width: 76, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: Theme.of(context).primaryColor,
              side: BorderSide(color: Theme.of(context).primaryColor),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            ),
            onPressed: () => Get.find<ItemController>().itemDirectlyAddToCart(item, context),
            child: Text('add'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
          )),
        ),
      ])),
    ]);
  }
}

class _ServiceCardShimmer extends StatelessWidget {
  const _ServiceCardShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
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

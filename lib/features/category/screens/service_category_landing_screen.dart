import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/premium/premium_card.dart';
import 'package:sixam_mart/common/widgets/premium/premium_chip.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/widgets/service_sub_category_card.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/widgets/bottom_cart_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Landing page of one catalog category (services → categories sheet → *here*).
///
/// A gradient hero banner carries the category name and a rating pill derived
/// from the services actually loaded; below it, a card holding the "Select a
/// service" list — one row per bookable sub-category with its starting price,
/// a short description, View details, and Add.
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
          backgroundColor: Theme.of(context).primaryColor,
          surfaceTintColor: Theme.of(context).primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text(widget.categoryName, style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge, color: Colors.white,
          )),
          centerTitle: true,
        ),
        // endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,

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

              // Hero banner — brand gradient, rounded bottom edge, soft shadow so it
              // reads as a distinct header rather than a plain title bar.
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.fromLTRB(
              //     Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge,
              //     Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraLarge,
              //   ),
              //   decoration: BoxDecoration(
              //     gradient: PremiumTokens.brandGradient(context),
              //     borderRadius: const BorderRadius.only(
              //       bottomLeft: Radius.circular(PremiumTokens.radiusHero),
              //       bottomRight: Radius.circular(PremiumTokens.radiusHero),
              //     ),
              //     boxShadow: PremiumTokens.softShadow(context),
              //   ),
              //   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              //     // Text(
              //     //   controller.parentName ?? widget.categoryName,
              //     //   style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Colors.white),
              //     //   maxLines: 2, overflow: TextOverflow.ellipsis,
              //     // ),

              //     if (controller.showRatingLine) Padding(
              //       padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              //       child: Container(
              //         padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
              //         decoration: BoxDecoration(
              //           color: Colors.white.withValues(alpha: 0.16),
              //           borderRadius: BorderRadius.circular(PremiumTokens.radiusPill),
              //         ),
              //         child: Row(mainAxisSize: MainAxisSize.min, children: [
              //           const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
              //           const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              //           Text(
              //             controller.derivedRating.toStringAsFixed(1),
              //             style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
              //           ),
              //           const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              //           Text(
              //             '(${controller.derivedRatingCount} ${'ratings'.tr})',
              //             style: robotoRegular.copyWith(
              //               fontSize: Dimensions.fontSizeSmall, color: Colors.white.withValues(alpha: 0.85),
              //             ),
              //           ),
              //         ]),
              //       ),
              //     ),
              //   ]),
              // ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: PremiumCard(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: Row(children: [
                        Expanded(child: Text(
                          'select_a_service'.tr,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                        )),
                        if (items != null && items.isNotEmpty) StatusPill(
                          label: '${items.length} ${'services'.tr}',
                          color: Theme.of(context).primaryColor,
                        ),
                      ]),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    FadeSlideIn(child: ServiceItemsListView(items: items)),

                    if (controller.isSectionBusy(_sectionId)) Center(child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      ),
                    )),
                  ]),
                ),
              ),

              const SizedBox(height: 100),
            ]),
          )),
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/widgets/service_sub_category_card.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/widgets/bottom_cart_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

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

              ServiceItemsListView(items: items),

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

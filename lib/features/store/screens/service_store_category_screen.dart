import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/store/controllers/service_store_category_controller.dart';
import 'package:sixam_mart/features/store/widgets/bottom_cart_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Third level of the service catalogue: the customer picked a provider (Art Villa Salon),
/// then a category inside it (Coloring); this shows that category's children as chips
/// (All / Highlights / root touch-ups / global color) and the provider's services beneath.
///
/// If the category has no children the chip row collapses to just "All" and this is simply
/// the provider's services in that category — so it degrades cleanly on a 2-level tree.
class ServiceStoreCategoryScreen extends StatefulWidget {
  final int storeId;
  final int categoryId;
  final String categoryName;
  const ServiceStoreCategoryScreen({
    super.key, required this.storeId, required this.categoryId, required this.categoryName,
  });

  @override
  State<ServiceStoreCategoryScreen> createState() => _ServiceStoreCategoryScreenState();
}

class _ServiceStoreCategoryScreenState extends State<ServiceStoreCategoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Get.find<ServiceStoreCategoryController>().init(
      storeId: widget.storeId, categoryId: widget.categoryId, categoryName: widget.categoryName,
    );

    _scrollController.addListener(() {
      final ServiceStoreCategoryController controller = Get.find<ServiceStoreCategoryController>();
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent
          && controller.hasMore && !controller.isLoading) {
        controller.loadMore();
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

    return Scaffold(
      appBar: isDesktop ? const WebMenuBar() : AppBar(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).textTheme.bodyLarge!.color),
          onPressed: () => Get.back(),
        ),
        title: Text(widget.categoryName, style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color,
        )),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyLarge!.color),
            onPressed: () => Get.toNamed(RouteHelper.getSearchStoreItemRoute(widget.storeId)),
          ),
          IconButton(
            onPressed: () => Get.toNamed(RouteHelper.getCartRoute()),
            icon: CartWidget(color: Theme.of(context).textTheme.bodyLarge!.color, size: 25),
          ),
        ],
      ),
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,

      bottomNavigationBar: GetBuilder<CartController>(builder: (CartController cartController) {
        return cartController.cartList.isNotEmpty && !isDesktop
            ? const BottomCartWidget() : const SizedBox();
      }),

      body: GetBuilder<ServiceStoreCategoryController>(builder: (ServiceStoreCategoryController controller) {
        return Column(children: [

          if (controller.children != null && controller.children!.length > 1)
            _chipRow(context, controller),

          Expanded(child: SingleChildScrollView(
            controller: _scrollController,
            child: FooterView(child: Center(child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Column(children: [
                ItemsView(
                  isStore: false, stores: null,
                  items: controller.items,
                  isScrollable: false,
                  noDataText: 'no_category_item_found'.tr,
                ),

                if (controller.isLoading && controller.items != null) Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ),
              ]),
            ))),
          )),
        ]);
      }),
    );
  }

  Widget _chipRow(BuildContext context, ServiceStoreCategoryController controller) {
    return Container(
      height: 45,
      width: double.infinity,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        physics: const BouncingScrollPhysics(),
        itemCount: controller.children!.length,
        itemBuilder: (BuildContext context, int index) {
          final CategoryModel child = controller.children![index];
          final bool isSelected = index == controller.selectedIndex;

          return InkWell(
            onTap: () => controller.selectChild(index),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Text(
                child.name ?? '',
                style: isSelected
                    ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)
                    : robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          );
        },
      ),
    );
  }
}

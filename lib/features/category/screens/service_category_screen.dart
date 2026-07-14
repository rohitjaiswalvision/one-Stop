import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/widgets/service_section_menu_sheet.dart';
import 'package:sixam_mart/features/category/widgets/service_sub_category_tiles_widget.dart';
import 'package:sixam_mart/features/store/widgets/bottom_cart_widget.dart';
import 'package:sixam_mart/features/store/widgets/customizable_space_bar_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The service module's category landing page.
///
/// Every subcategory renders as its own section stacked down the page, and the tiles at
/// the top jump to them rather than filtering — so the customer sees the whole catalogue
/// of a category (e.g. "AC Repair & Service") at a glance and dives into one part of it.
///
/// The rating line and the offer strip are DERIVED from the services actually loaded:
/// the API carries no category-level rating, booking count or offer, so anything it
/// cannot back is simply not shown.
class ServiceCategoryScreen extends StatefulWidget {
  final String? categoryID;
  final String categoryName;
  final String slug;
  const ServiceCategoryScreen({
    super.key, required this.categoryID, required this.categoryName, this.slug = '',
  });

  @override
  State<ServiceCategoryScreen> createState() => _ServiceCategoryScreenState();
}

class _ServiceCategoryScreenState extends State<ServiceCategoryScreen> {
  late final AutoScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = AutoScrollController(
      axis: Axis.vertical,
      // Only a hint for how far to step while hunting an unbuilt section; affects how many
      // iterations the scroll takes to converge, never where it lands.
      suggestedRowHeight: 420,
      // The SliverAppBar is pinned, so it overlays the top of the viewport. Without this
      // inset every section heading would come to rest underneath it.
      viewportBoundaryGetter: () => Rect.fromLTRB(
        0, kToolbarHeight + MediaQuery.of(context).padding.top, 0, 0,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ServiceCategoryController>().initCategory(widget.categoryID ?? '', widget.categoryName);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Sections are built lazily by the sliver, so a target that is far off-screen has no
  /// element yet. AutoScrollController handles that by stepping toward it and re-checking,
  /// which a plain GlobalKey + Scrollable.ensureVisible cannot do.
  Future<void> _jumpToSection(int index) async {
    Get.find<ServiceCategoryController>().setSelectedSection(index);
    await _scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.begin,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _shareCategory() {
    if (widget.categoryID == null) return;
    final String url = '${AppConstants.webHostedUrl}${RouteHelper.getCategoryItemRoute(
      int.tryParse(widget.categoryID!), widget.categoryName, slug: widget.slug,
    )}';

    if (ResponsiveHelper.isDesktop(context)) {
      Clipboard.setData(ClipboardData(text: url));
      showCustomSnackBar('category_url_copied'.tr, isError: false);
    } else {
      SharePlus.instance.share(ShareParams(text: url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<ServiceCategoryController>(builder: (ServiceCategoryController controller) {
      final List<CategoryModel> sections = controller.sections ?? <CategoryModel>[];

      return Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: isDesktop ? const WebMenuBar() : null,
        endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,

        floatingActionButton: sections.length > 1 ? _menuPill(context, controller, sections) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

        // Scaffold lifts the FAB above this automatically — which is why the Menu pill is
        // a floatingActionButton and not a Positioned widget.
        bottomNavigationBar: GetBuilder<CartController>(builder: (CartController cartController) {
          return cartController.cartList.isNotEmpty && !isDesktop
              ? const BottomCartWidget() : const SizedBox();
        }),

        body: CustomScrollView(
          controller: _scrollController,
          slivers: [

            if (!isDesktop) _appBar(context, controller),

            if (isDesktop) SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Center(child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: _header(context, controller, collapsed: false),
              )),
            )),

            SliverToBoxAdapter(child: Center(child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: ServiceSubCategoryTilesWidget(
                sections: controller.sections,
                selectedIndex: controller.selectedSectionIndex,
                onTap: _jumpToSection,
              ),
            ))),

            SliverList(delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final CategoryModel section = sections[index];
                final int sectionId = section.id ?? -1;

                return AutoScrollTag(
                  key: ValueKey<int>(sectionId),
                  controller: _scrollController,
                  index: index,
                  child: Center(child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: TitleWidget(
                          title: section.name ?? '',
                          onTap: controller.hasMore(sectionId) ? () => controller.loadMore(sectionId) : null,
                        ),
                      ),

                      ItemsView(
                        isStore: false, stores: null,
                        items: controller.itemsOf(sectionId),
                        isScrollable: false,
                        shimmerLength: ServiceCategoryController.sectionPageSize,
                        noDataText: 'no_category_item_found'.tr,
                      ),

                      if (controller.isSectionBusy(sectionId)) Center(child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      )),
                    ]),
                  )),
                );
              },
              childCount: sections.length,
            )),

            // Clearance so the last card is not sat on by the Menu pill.
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      );
    });
  }

  Widget _appBar(BuildContext context, ServiceCategoryController controller) {
    return SliverAppBar(
      expandedHeight: 170,
      toolbarHeight: kToolbarHeight,
      pinned: true, floating: false, elevation: 0.5,
      backgroundColor: Theme.of(context).cardColor,
      surfaceTintColor: Theme.of(context).cardColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).textTheme.bodyLarge!.color),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyLarge!.color),
          onPressed: () => Get.toNamed(RouteHelper.getSearchRoute()),
        ),
        IconButton(
          icon: Icon(Icons.share, color: Theme.of(context).textTheme.bodyLarge!.color),
          onPressed: _shareCategory,
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: false,
        expandedTitleScale: 1.0,
        title: CustomizableSpaceBarWidget(builder: (BuildContext context, double scrollingRate) {
          // 0.0 expanded -> 1.0 collapsed. Fade the stats out as the bar closes, leaving
          // just the category name in the toolbar.
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
            ),
            child: Opacity(
              opacity: 1,
              child: _header(context, controller, collapsed: scrollingRate > 0.6, scrollingRate: scrollingRate),
            ),
          );
        }),
      ),
    );
  }

  Widget _header(
    BuildContext context, ServiceCategoryController controller, {
    required bool collapsed, double scrollingRate = 0,
  }) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text(
        controller.parentName ?? widget.categoryName,
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoBold.copyWith(
          fontSize: collapsed ? Dimensions.fontSizeLarge : Dimensions.fontSizeOverLarge,
        ),
      ),

      if (!collapsed) Opacity(
        opacity: (1 - scrollingRate).clamp(0.0, 1.0),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          if (controller.showRatingLine) Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
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

          if (controller.showOfferStrip) Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.local_offer_outlined, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Text(
                  '${'up_to'.tr} ${controller.maxDiscountPercent}% ${'off'.tr}',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _menuPill(BuildContext context, ServiceCategoryController controller, List<CategoryModel> sections) {
    return FloatingActionButton.extended(
      backgroundColor: Theme.of(context).textTheme.bodyLarge!.color,
      elevation: 4,
      icon: const Icon(Icons.menu, color: Colors.white, size: 18),
      label: Text('menu'.tr, style: robotoMedium.copyWith(
        color: Colors.white, fontSize: Dimensions.fontSizeSmall,
      )),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => ServiceSectionMenuSheet(
          sections: sections,
          selectedIndex: controller.selectedSectionIndex,
          onSelect: (int index) {
            // Close first so the scroll animation is visible rather than hidden behind the sheet.
            Get.back();
            _jumpToSection(index);
          },
        ),
      ),
    );
  }
}

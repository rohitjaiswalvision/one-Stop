import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// Tapping a service group on the home grid opens this sheet with the group's
/// categories (GET /services/catalog/services/{id}/categories); tapping a category
/// leads to its landing page.
///
/// If the catalog endpoint is not available (null response), the sheet closes and
/// falls back to the legacy category route, so the tile still leads somewhere.
class ServiceCategoriesBottomSheet extends StatefulWidget {
  final int serviceId;
  final String serviceName;
  final String slug;
  const ServiceCategoriesBottomSheet({
    super.key, required this.serviceId, required this.serviceName, this.slug = '',
  });

  static void show({required int serviceId, required String serviceName, String slug = ''}) {
    final Widget sheet = ServiceCategoriesBottomSheet(serviceId: serviceId, serviceName: serviceName, slug: slug);
    if (ResponsiveHelper.isMobile(Get.context)) {
      Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    } else {
      Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    }
  }

  @override
  State<ServiceCategoriesBottomSheet> createState() => _ServiceCategoriesBottomSheetState();
}

class _ServiceCategoriesBottomSheetState extends State<ServiceCategoriesBottomSheet> {
  List<CategoryModel>? _categories;

  @override
  void initState() {
    super.initState();

    Get.find<ServiceCategoryController>().categoryServiceInterface
        .getCatalogServiceCategories(widget.serviceId.toString())
        .then((List<CategoryModel>? categories) {
      if (!mounted) return;
      if (categories == null) {
        // Catalog not deployed — hand over to the legacy category screen.
        Get.back();
        Get.toNamed(RouteHelper.getCategoryItemRoute(widget.serviceId, widget.serviceName, slug: widget.slug));
        return;
      }
      setState(() => _categories = categories);
    });
  }

  void _openCategory(CategoryModel category) {
    Get.back();
    Get.toNamed(RouteHelper.getServiceCategoryRoute(
      categoryId: category.id, serviceId: widget.serviceId, name: category.name ?? '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7, maxWidth: 550),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

        Center(child: Container(
          height: 4, width: 40,
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
        )),

        Text(
          widget.serviceName,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Flexible(child: _categories == null
            ? const _CategoryGridShimmer()
            : _categories!.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Center(child: Text('no_category_found'.tr, style: robotoRegular.copyWith(
                      color: Theme.of(context).disabledColor,
                    ))),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: Dimensions.paddingSizeDefault,
                      crossAxisSpacing: Dimensions.paddingSizeDefault,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _categories!.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CategoryModel category = _categories![index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        onTap: () => _openCategory(category),
                        child: Column(children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              child: CustomImage(
                                image: '${category.imageFullUrl}',
                                height: 70, width: 70, fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Expanded(child: Text(
                            category.name ?? '',
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                          )),
                        ]),
                      );
                    },
                  )),
      ]),
    );
  }
}

class _CategoryGridShimmer extends StatelessWidget {
  const _CategoryGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (BuildContext context, int index) => Shimmer(child: Column(children: [
        Container(
          height: 70, width: 70,
          decoration: BoxDecoration(
            color: Theme.of(context).shadowColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Container(height: 10, width: 50, color: Theme.of(context).shadowColor),
      ])),
    );
  }
}

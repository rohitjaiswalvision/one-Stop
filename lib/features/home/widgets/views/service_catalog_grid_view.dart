import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/widgets/service_categories_bottom_sheet.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// The service module's home browse surface: a grid of service groups
/// (Women's Salon, Cleaning, AC & Appliance Repair, …) fed by
/// GET /services/catalog/services. Tapping a tile opens the group's categories
/// as a bottom sheet — providers are assigned behind the scenes, so stores are
/// not a browsing entry point here.
class ServiceCatalogGridView extends StatelessWidget {
  const ServiceCatalogGridView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (CategoryController categoryController) {
      final List<CategoryModel>? services = categoryController.categoryList;

      if (services != null && services.isEmpty) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Text('all_services'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          services == null ? const _ServiceGridShimmer() : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: Dimensions.paddingSizeDefault,
              crossAxisSpacing: Dimensions.paddingSizeDefault,
              childAspectRatio: 0.78,
            ),
            itemCount: services.length,
            itemBuilder: (BuildContext context, int index) {
              final CategoryModel service = services[index];
              return InkWell(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                onTap: () {
                  if (service.id != null) {
                    ServiceCategoriesBottomSheet.show(
                      serviceId: service.id!, serviceName: service.name ?? '', slug: service.slug ?? '',
                    );
                  }
                },
                child: Column(children: [
                  Expanded(child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: CustomImage(image: '${service.imageFullUrl}', fit: BoxFit.cover),
                    ),
                  )),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Text(
                    service.name ?? '',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                    maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  ),
                ]),
              );
            },
          ),
        ]),
      );
    });
  }
}

class _ServiceGridShimmer extends StatelessWidget {
  const _ServiceGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (BuildContext context, int index) => Shimmer(child: Column(children: [
        Expanded(child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).shadowColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
        )),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Container(height: 10, width: 60, color: Theme.of(context).shadowColor),
      ])),
    );
  }
}

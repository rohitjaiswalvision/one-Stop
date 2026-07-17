import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/widgets/service_categories_bottom_sheet.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// Service module only: the service groups this provider offers, rendered as the
/// SAME grid the home "All Services" section uses — 3 columns of image tiles.
///
/// Fed by GET /services/catalog/services?store_id= — the same endpoint and shape
/// as the home grid, scoped to one provider. Tapping a tile enters the identical
/// chain (categories sheet → landing → detail → booking); the service id from this
/// response pins the rest of the chain to this store on the backend, so there is
/// no provider-picker step. Falls back to the store's category-id filter over the
/// module categories while the endpoint is not deployed.
class ServiceStoreCategoriesView extends StatefulWidget {
  /// Provider to scope the catalog to. Null shows the whole catalog, same as home.
  final int? storeId;

  /// Shown instead when the catalog endpoint is unavailable (pre-deploy fallback).
  /// A synthetic id-0 "All" entry, if present, is filtered out.
  final List<CategoryModel>? fallbackCategories;

  const ServiceStoreCategoriesView({super.key, this.storeId, this.fallbackCategories});

  @override
  State<ServiceStoreCategoriesView> createState() => _ServiceStoreCategoriesViewState();
}

class _ServiceStoreCategoriesViewState extends State<ServiceStoreCategoriesView> {
  List<CategoryModel>? _services;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    if (!ModuleHelper.isService()) {
      _loading = false;
      return;
    }

    Get.find<ServiceCategoryController>().categoryServiceInterface
        .getCatalogServices(storeId: widget.storeId)
        .then((List<CategoryModel>? services) {
      if (!mounted) return;
      setState(() {
        _services = services ?? _legacyCategories();
        _loading = false;
      });
    });
  }

  List<CategoryModel> _legacyCategories() {
    return (widget.fallbackCategories ?? <CategoryModel>[])
        .where((CategoryModel c) => c.id != null && c.id != 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!ModuleHelper.isService()) {
      return const SizedBox();
    }
    if (_loading) {
      return const _StoreServicesGridShimmer();
    }
    final List<CategoryModel> services = _services ?? <CategoryModel>[];
    if (services.isEmpty) {
      return const SizedBox();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: Dimensions.paddingSizeDefault),

      Text('all_services'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      GridView.builder(
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
      const SizedBox(height: Dimensions.paddingSizeSmall),
    ]);
  }
}

class _StoreServicesGridShimmer extends StatelessWidget {
  const _StoreServicesGridShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
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

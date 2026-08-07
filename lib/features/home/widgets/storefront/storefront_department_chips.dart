import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/home/widgets/storefront/storefront_tokens.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The chip rail directly under the blue header: a leading "Departments" chip
/// that opens the full category list, followed by the module's own categories.
///
/// It renders nothing until the categories land, so the page never shows an empty
/// band where the rail will be.
class StorefrontDepartmentChips extends StatelessWidget {
  const StorefrontDepartmentChips({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (categoryController) {
      final List<CategoryModel> categories = categoryController.categoryList ?? [];
      if(categories.isEmpty) return const SizedBox();

      // Chips are a shortcut, not the catalog: past a dozen the rail stops being
      // scannable and "Departments" is the better door.
      final int visible = categories.length > 12 ? 12 : categories.length;

      return Container(
        width: double.infinity,
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(children: [

            _chip(
              context, label: 'departments'.tr, icon: Icons.grid_view_rounded, emphasised: true,
              onTap: () => Get.toNamed(RouteHelper.getCategoryRoute()),
            ),

            for(int i = 0; i < visible; i++)
              _chip(
                context, label: categories[i].name ?? '',
                onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(
                  categories[i].id, categories[i].name ?? '', slug: categories[i].slug ?? '',
                )),
              ),
          ]),
        ),
      );
    });
  }

  Widget _chip(BuildContext context, {required String label, required VoidCallback onTap, IconData? icon, bool emphasised = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StorefrontTokens.pillRadius),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: StorefrontTokens.chipFill(context),
            borderRadius: BorderRadius.circular(StorefrontTokens.pillRadius),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [

            if(icon != null) ...[
              Icon(icon, size: 18, color: StorefrontTokens.chipText(context)),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            ],

            Text(
              label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: (emphasised ? robotoBold : robotoMedium).copyWith(
                fontSize: Dimensions.fontSizeSmall, color: StorefrontTokens.chipText(context),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

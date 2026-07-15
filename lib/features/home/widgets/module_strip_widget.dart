import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A Swiggy-style horizontal strip of the zone's modules, meant to sit pinned at the top
/// of a module's home so the user can hop between modules (Services / Food / Parcel …)
/// without going back to the full module grid. The currently selected module is highlighted.
///
/// Taxi and pharmacy are excluded to match the module grid ([ModuleView]); switching is the
/// same call the grid makes, so cart/category/banner state is reset consistently.
class ModuleStripWidget extends StatelessWidget {
  const ModuleStripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (splashController) {
      final List<int> moduleIndices = <int>[];
      if (splashController.moduleList != null) {
        for (int i = 0; i < splashController.moduleList!.length; i++) {
          final String type = splashController.moduleList![i].moduleType.toString();
          if (type != AppConstants.taxi && type != AppConstants.pharmacy) {
            moduleIndices.add(i);
          }
        }
      }

      // Nothing to switch between: hide the strip entirely so single-module zones look normal.
      if (moduleIndices.length < 2) {
        return const SizedBox();
      }

      final int? currentId = splashController.module?.id;

      return Container(
        height: 74,
        color: Theme.of(context).cardColor,
        alignment: Alignment.center,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
          itemCount: moduleIndices.length,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (BuildContext context, int index) {
            final int originalIndex = moduleIndices[index];
            final module = splashController.moduleList![originalIndex];
            final bool isSelected = currentId != null && module.id == currentId;

            return CustomInkWell(
              onTap: () {
                if (!isSelected) {
                  splashController.switchModule(originalIndex, true);
                }
              },
              radius: Dimensions.radiusDefault,
              child: Container(
                width: 78,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.25),
                    width: isSelected ? 1 : 0.5,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: CustomImage(
                      image: '${module.iconFullUrl}',
                      height: 28, width: 28,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Text(
                    module.moduleName ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: isSelected
                        ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)
                        : robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                  ),

                ]),
              ),
            );
          },
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/premium/premium_motion.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A Swiggy-style horizontal strip of the zone's modules, meant to sit pinned at the top
/// of a module's home so the user can hop between modules (Services / Food / Parcel …)
/// without going back to the full module grid. The currently selected module is highlighted
/// with the brand gradient; switching animates the tile in smoothly.
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

            return PressableScale(
              onTap: () {
                if (!isSelected) {
                  splashController.switchModule(originalIndex, true);
                }
              },
              child: AnimatedContainer(
                duration: PremiumTokens.medium,
                curve: PremiumTokens.easeOut,
                width: 78,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  gradient: isSelected ? PremiumTokens.brandGradient(context) : null,
                  color: isSelected ? null : PremiumTokens.tint(context, opacity: 0.05),
                  boxShadow: isSelected ? PremiumTokens.softShadow(context, strength: 0.6) : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                  AnimatedContainer(
                    duration: PremiumTokens.medium,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: CustomImage(
                        image: '${module.iconFullUrl}',
                        height: 26, width: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Text(
                    module.moduleName ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: isSelected
                        ? robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Colors.white)
                        : robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).textTheme.bodyMedium!.color),
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

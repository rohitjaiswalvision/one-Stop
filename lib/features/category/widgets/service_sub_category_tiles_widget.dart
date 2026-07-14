import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The horizontal strip of subcategory tiles at the top of the service category page.
/// Tapping one scrolls to that section rather than filtering the list, so the selected
/// tile is a position indicator, not a filter.
class ServiceSubCategoryTilesWidget extends StatelessWidget {
  final List<CategoryModel>? sections;
  final int selectedIndex;
  final void Function(int index) onTap;
  const ServiceSubCategoryTilesWidget({
    super.key, required this.sections, required this.selectedIndex, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sections == null) {
      return _shimmer(context);
    }
    // A category with no subcategories renders as one section; a strip of one tile is noise.
    if (sections!.length < 2) {
      return const SizedBox();
    }

    return Container(
      height: 118,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        physics: const BouncingScrollPhysics(),
        itemCount: sections!.length,
        itemBuilder: (BuildContext context, int index) {
          final CategoryModel section = sections![index];
          final bool isSelected = index == selectedIndex;

          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: SizedBox(
              width: 80,
              child: Column(children: [
                Container(
                  height: 65, width: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: isSelected
                        ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: CustomImage(
                      image: section.imageFullUrl ?? '',
                      height: 65, width: 65, fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Expanded(child: Text(
                  section.name ?? '',
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                )),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _shimmer(BuildContext context) {
    return Container(
      height: 118,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (BuildContext context, int index) => SizedBox(
          width: 80,
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: true,
            child: Column(children: [
              Container(
                height: 65, width: 65,
                decoration: BoxDecoration(
                  color: Theme.of(context).shadowColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Container(
                height: 10, width: 55,
                decoration: BoxDecoration(
                  color: Theme.of(context).shadowColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

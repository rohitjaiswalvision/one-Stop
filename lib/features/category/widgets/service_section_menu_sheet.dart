import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/service_category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The "Menu" pill's sheet: a jump list of the sections on the page. It exists because
/// the subcategory tiles scroll away, leaving no way back to another section.
class ServiceSectionMenuSheet extends StatelessWidget {
  final List<CategoryModel> sections;
  final int selectedIndex;
  final void Function(int index) onSelect;
  const ServiceSectionMenuSheet({
    super.key, required this.sections, required this.selectedIndex, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ServiceCategoryController controller = Get.find<ServiceCategoryController>();

    return Container(
      constraints: BoxConstraints(maxHeight: context.height * 0.7),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          Container(
            height: 4, width: 35,
            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall,
            ),
            child: Row(children: [
              Expanded(child: Text('menu'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
            ]),
          ),
          const Divider(height: 0),

          Flexible(child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            itemCount: sections.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(height: 0),
            itemBuilder: (BuildContext context, int index) {
              final CategoryModel section = sections[index];
              final bool isSelected = index == selectedIndex;
              final int count = controller.totalOf(section.id ?? -1);

              return InkWell(
                onTap: () => onSelect(index),
                child: Container(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault,
                  ),
                  child: Row(children: [
                    Expanded(child: Text(
                      section.name ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? robotoMedium.copyWith(color: Theme.of(context).primaryColor)
                          : robotoRegular,
                    )),

                    if (count > 0) Text(
                      '$count',
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}

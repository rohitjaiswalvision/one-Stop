import 'package:flutter/material.dart';
import 'package:sixam_mart/features/category/screens/category_item_screen.dart';
import 'package:sixam_mart/features/category/screens/service_category_screen.dart';
import 'package:sixam_mart/helper/module_helper.dart';

/// Chooses which category screen `/category-item/:slug` opens.
///
/// The branch MUST live here, in build(), rather than in the GetPage. `_waitForModule`
/// takes an already-constructed widget and only defers its *rendering* behind the module
/// lookup — so deciding in the GetPage would read the module before it resolves, and a
/// deep link or cold start would open the wrong screen. build() runs after the future
/// completes, by which point the module is known.
class CategoryItemDispatcherScreen extends StatelessWidget {
  final String? categoryID;
  final String categoryName;
  final String slug;
  const CategoryItemDispatcherScreen({
    super.key, required this.categoryID, required this.categoryName, this.slug = '',
  });

  @override
  Widget build(BuildContext context) {
    return ModuleHelper.isService()
        ? ServiceCategoryScreen(categoryID: categoryID, categoryName: categoryName, slug: slug)
        : CategoryItemScreen(categoryID: categoryID, categoryName: categoryName);
  }
}

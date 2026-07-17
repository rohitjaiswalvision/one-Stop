import 'package:get/get.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/domain/models/service_catalog_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';

abstract class CategoryServiceInterface {
  Future<List<CategoryModel>?> getCategoryList(bool allCategory, {DataSourceEnum? source});
  Future<List<CategoryModel>?> getSubCategoryList(String? parentID);
  Future<ItemModel?> getCategoryItemList(String? categoryID, int offset, String type, {int? limit});
  Future<StoreModel?> getCategoryStoreList(String? categoryID, int offset, String type);
  Future<Response> getSearchData(String? query, String? categoryID, bool isStore, String type);
  Future<bool> saveUserInterests(List<int?> interests);

  /// Service module catalog browse flow. Null results mean the catalog endpoints are
  /// unavailable and the caller should fall back to the legacy category tree.
  Future<List<CategoryModel>?> getCatalogServiceCategories(String? serviceId);
  Future<ItemModel?> getCatalogSubCategories({required String categoryId, required String serviceId, int offset = 1, int limit = 10});
  Future<CatalogSubCategoryModel?> getCatalogSubCategoryDetail(int itemId);
}
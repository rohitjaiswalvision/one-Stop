import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class CategoryRepositoryInterface implements RepositoryInterface {
  @override
  Future getList({int? offset, bool categoryList = false, bool subCategoryList = false, bool categoryItemList = false, bool categoryStoreList = false, int? limit,
    bool? allCategory, String? id, String? type, DataSourceEnum? source});
  Future<dynamic> getSearchData(String? query, String? categoryID, bool isStore, String type);
  Future<dynamic> saveUserInterests(List<int?> interests);

  /// Service module catalog: categories of a catalog service (`/services/catalog/services/{id}/categories`).
  /// Null when the endpoint is unavailable — callers fall back to the legacy category tree.
  Future<dynamic> getCatalogServiceCategories(String? serviceId);

  /// Service module catalog: bookable sub-categories of a category, mapped to the app's
  /// item shape (`/services/catalog/categories/{id}/sub-categories?service_id=`).
  Future<dynamic> getCatalogSubCategories({required String categoryId, required String serviceId, int offset = 1, int limit = 10});

  /// Service module catalog: full sub-category detail (`/services/catalog/sub-categories/{itemId}`).
  Future<dynamic> getCatalogSubCategoryDetail(int itemId);
}
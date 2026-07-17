import 'dart:convert';

import 'package:get/get.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/domain/models/service_catalog_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/category/domain/reposotories/category_repository_interface.dart';

class CategoryRepository implements CategoryRepositoryInterface {
  final ApiClient apiClient;
  CategoryRepository({required this.apiClient});

  @override
  Future getList({int? offset, bool categoryList = false, bool subCategoryList = false, bool categoryItemList = false, bool categoryStoreList = false,
    bool? allCategory, String? id, String? type, DataSourceEnum? source, int? limit}) async {
    if (categoryList) {
      return await _getCategoryList(allCategory!, source ?? DataSourceEnum.client);
    } else if (subCategoryList) {
      return await _getSubCategoryList(id);
    } else if (categoryItemList) {
      return await _getCategoryItemList(id, offset!, type!, limit: limit);
    } else if (categoryStoreList) {
      return await _getCategoryStoreList(id, offset!, type!);
    }
  }

  Future<List<CategoryModel>?> _getCategoryList(bool allCategory, DataSourceEnum source) async {
    List<CategoryModel>? categoryList;
    Map<String, String>? header = allCategory ? {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.localizationKey: Get.find<LocalizationController>().locale.languageCode,
    } : null;

    Map<String, String>? cacheHeader = header ?? apiClient.getHeader();

    String cacheId = '${AppConstants.categoryUri} ${Get.find<SplashController>().module?.id??''}';

    switch(source) {
      case DataSourceEnum.client:
        // Service module browses the dedicated catalog: its top-level cards are catalog
        // *services* (GET /services/catalog/services), not module categories. The response
        // shape (id / name / image_full_url) parses as a CategoryModel, so the same cards,
        // cache and listeners serve both. Falls back to the legacy tree while the catalog
        // endpoints are not deployed.
        Response response = await apiClient.getData(
          ModuleHelper.isService() ? AppConstants.serviceCatalogServicesUri : AppConstants.categoryUri,
          headers: header, handleError: false,
        );
        if (response.statusCode != 200 && ModuleHelper.isService()) {
          response = await apiClient.getData(AppConstants.categoryUri, headers: header);
        }
        if (response.statusCode == 200 && response.body is List) {
          categoryList = [];
          response.body.forEach((category) {
            categoryList!.add(CategoryModel.fromJson(category));
          });
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(response.body), cacheHeader);

        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          categoryList = [];
          jsonDecode(cacheResponseData).forEach((category) {
            categoryList!.add(CategoryModel.fromJson(category));
          });
        }
    }

    return categoryList;
  }

  /// Categories of one catalog service — GET /services/catalog/services/{id}/categories.
  /// Null (not empty) when the endpoint is missing or errors, so the caller can fall back.
  @override
  Future<List<CategoryModel>?> getCatalogServiceCategories(String? serviceId) async {
    if (serviceId == null || serviceId.isEmpty) return null;
    Response response = await apiClient.getData(
      '${AppConstants.serviceCatalogServicesUri}/$serviceId/categories', handleError: false,
    );
    if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
      final CatalogCategoriesResponse parsed = CatalogCategoriesResponse.fromJson(response.body);
      return parsed.categories?.map((CatalogCategoryModel c) => c.toCategory()).toList();
    }
    return null;
  }

  /// Bookable sub-categories of a catalog category —
  /// GET /services/catalog/categories/{id}/sub-categories?service_id=&limit=&offset=.
  /// Each entry's id is an item id, so the result is delivered as the app's ItemModel.
  @override
  Future<ItemModel?> getCatalogSubCategories({required String categoryId, required String serviceId, int offset = 1, int limit = 10}) async {
    Response response = await apiClient.getData(
      '${AppConstants.serviceCatalogCategoriesUri}/$categoryId/sub-categories?service_id=$serviceId&limit=$limit&offset=$offset',
      handleError: false,
    );
    if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
      return CatalogSubCategoriesResponse.fromJson(response.body).toItemModel();
    }
    return null;
  }

  /// Full sub-category detail — GET /services/catalog/sub-categories/{itemId}.
  /// Everything the listing carries plus requirements, image gallery and buffer time.
  @override
  Future<CatalogSubCategoryModel?> getCatalogSubCategoryDetail(int itemId) async {
    Response response = await apiClient.getData(
      '${AppConstants.serviceCatalogSubCategoriesUri}/$itemId', handleError: false,
    );
    if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
      // Detail may come bare or wrapped in a `sub_category`-style envelope.
      final Map<String, dynamic> body = response.body;
      return CatalogSubCategoryModel.fromJson(
        body['id'] != null ? body : (body['sub_category'] is Map<String, dynamic> ? body['sub_category'] : body),
      );
    }
    return null;
  }

  Future<List<CategoryModel>?> _getSubCategoryList(String? parentID) async {
    List<CategoryModel>? subCategoryList;
    Response response = await apiClient.getData('${AppConstants.subCategoryUri}$parentID');
    if (response.statusCode == 200) {
      subCategoryList= [];
      response.body.forEach((category) => subCategoryList!.add(CategoryModel.fromJson(category)));
    }
    return subCategoryList;
  }

  /// [limit] defaults to 10 — the value every existing caller assumes, including the
  /// `(pageSize / 10).ceil()` page-count maths in CategoryItemScreen. Only pass a
  /// different limit where the caller does its own page maths (ServiceCategoryController).
  Future<ItemModel?> _getCategoryItemList(String? categoryID, int offset, String type, {int? limit}) async {
    ItemModel? categoryItem;
    Response response = await apiClient.getData('${AppConstants.categoryItemUri}$categoryID?limit=${limit ?? 10}&offset=$offset&type=$type');
    if (response.statusCode == 200) {
      categoryItem = ItemModel.fromJson(response.body);
    }
    return categoryItem;
  }

  Future<StoreModel?> _getCategoryStoreList(String? categoryID, int offset, String type) async {
    StoreModel? categoryStore;
    Response response = await apiClient.getData('${AppConstants.categoryStoreUri}$categoryID?limit=10&offset=$offset&type=$type');
    if (response.statusCode == 200) {
      categoryStore = StoreModel.fromJson(response.body);
    }
    return categoryStore;
  }

  @override
  Future<Response> getSearchData(String? query, String? categoryID, bool isStore, String type) async {
    return await apiClient.getData(
      '${AppConstants.searchUri}${isStore ? 'stores' : 'items'}/search?name=$query&category_id=$categoryID&type=$type&offset=1&limit=50',
    );
  }

  @override
  Future<bool> saveUserInterests(List<int?> interests) async {
    Response response = await apiClient.postData(AppConstants.interestUri, {"interest": interests});
    return (response.statusCode == 200);
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}
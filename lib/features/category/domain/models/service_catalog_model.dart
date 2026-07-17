import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Models for the service module's catalog browse flow:
///
///   GET /services/catalog/services                                  -> [CatalogServiceModel]
///   GET /services/catalog/services/{serviceId}/categories           -> [CatalogCategoriesResponse]
///   GET /services/catalog/categories/{categoryId}/sub-categories    -> [CatalogSubCategoriesResponse]
///
/// A catalog *sub-category entry* is the bookable unit: its `id` is the item id used by
/// slots, cart and booking. Each model maps onto the app's existing [CategoryModel]/[Item]
/// so every card, tile and details screen keeps working unchanged.
class CatalogServiceModel {
  int? id;
  String? name;
  String? imageFullUrl;
  int? categoriesCount;
  int? subCategoriesCount;

  CatalogServiceModel({this.id, this.name, this.imageFullUrl, this.categoriesCount, this.subCategoriesCount});

  CatalogServiceModel.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name'];
    imageFullUrl = json['image_full_url'];
    categoriesCount = _toInt(json['categories_count']);
    subCategoriesCount = _toInt(json['sub_categories_count']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    data['categories_count'] = categoriesCount;
    data['sub_categories_count'] = subCategoriesCount;
    return data;
  }

  CategoryModel toCategory() => CategoryModel(id: id, name: name, imageFullUrl: imageFullUrl);
}

/// GET /services/catalog/services/{serviceId}/categories
class CatalogCategoriesResponse {
  CatalogServiceModel? service;
  List<CatalogCategoryModel>? categories;

  CatalogCategoriesResponse({this.service, this.categories});

  CatalogCategoriesResponse.fromJson(Map<String, dynamic> json) {
    service = json['service'] != null ? CatalogServiceModel.fromJson(json['service']) : null;
    if (json['categories'] != null) {
      categories = [];
      json['categories'].forEach((v) => categories!.add(CatalogCategoryModel.fromJson(v)));
    }
  }
}

class CatalogCategoryModel {
  int? id;
  String? name;
  String? imageFullUrl;
  int? subCategoriesCount;

  CatalogCategoryModel({this.id, this.name, this.imageFullUrl, this.subCategoriesCount});

  CatalogCategoryModel.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name'];
    imageFullUrl = json['image_full_url'];
    subCategoriesCount = _toInt(json['sub_categories_count']);
  }

  CategoryModel toCategory() => CategoryModel(id: id, name: name, imageFullUrl: imageFullUrl);
}

/// GET /services/catalog/categories/{categoryId}/sub-categories?service_id=&limit=&offset=
class CatalogSubCategoriesResponse {
  CatalogServiceModel? service;
  CatalogCategoryModel? category;
  int? totalSize;
  List<CatalogSubCategoryModel>? subCategories;

  CatalogSubCategoriesResponse({this.service, this.category, this.totalSize, this.subCategories});

  CatalogSubCategoriesResponse.fromJson(Map<String, dynamic> json) {
    service = json['service'] != null ? CatalogServiceModel.fromJson(json['service']) : null;
    category = json['category'] != null ? CatalogCategoryModel.fromJson(json['category']) : null;
    totalSize = _toInt(json['total_size']);
    if (json['sub_categories'] != null) {
      subCategories = [];
      json['sub_categories'].forEach((v) => subCategories!.add(CatalogSubCategoryModel.fromJson(v)));
    }
  }

  /// The shape [ServiceCategoryController] pages over.
  ItemModel toItemModel() => ItemModel(
    totalSize: totalSize ?? subCategories?.length,
    items: subCategories?.map((CatalogSubCategoryModel s) => s.toItem()).toList(),
  );
}

class CatalogSubCategoryModel {
  /// The bookable item id — what slots, cart and booking key on.
  int? id;
  String? name;
  int? subCategoryId;
  String? subCategoryName;
  String? imageFullUrl;
  String? itemDescription;
  String? shortDescription;
  CatalogPricing? pricing;
  String? serviceDuration;
  bool? homeService;
  bool? atStore;
  int? storeId;
  // Detail endpoint only (GET /services/catalog/sub-categories/{itemId}):
  List<String>? imagesFullUrl;
  String? requirements;
  String? bufferTime;

  CatalogSubCategoryModel({
    this.id, this.name, this.subCategoryId, this.subCategoryName, this.imageFullUrl,
    this.itemDescription, this.shortDescription, this.pricing, this.serviceDuration,
    this.homeService, this.atStore, this.storeId,
    this.imagesFullUrl, this.requirements, this.bufferTime,
  });

  CatalogSubCategoryModel.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name'];
    if (json['sub_category'] is Map<String, dynamic>) {
      final Map<String, dynamic> sub = json['sub_category'];
      subCategoryId = _toInt(sub['id']);
      subCategoryName = sub['name'];
      imageFullUrl = sub['image_full_url'];
    }
    imageFullUrl = json['image_full_url'] ?? imageFullUrl;
    itemDescription = json['item_description'];
    shortDescription = json['short_description'];
    pricing = json['pricing'] is Map<String, dynamic> ? CatalogPricing.fromJson(json['pricing']) : null;
    serviceDuration = json['service_duration']?.toString();
    homeService = _toBool(json['home_service']);
    atStore = _toBool(json['at_store']);
    storeId = _toInt(json['store_id']);
    if (json['images_full_url'] is List) {
      imagesFullUrl = (json['images_full_url'] as List).whereType<String>().toList();
    }
    // Requirements can arrive as a string or a list of bullet points.
    final dynamic req = json['requirements'];
    if (req is List) {
      requirements = req.map((dynamic v) => v.toString()).join('\n');
    } else {
      requirements = req?.toString();
    }
    bufferTime = json['buffer_time']?.toString();
  }

  /// Maps a catalog entry onto the [Item] every existing card, tile, cart line and
  /// details route consumes. Any field the card widgets or navigation dereference
  /// with `!` (name, price, discount, rating, halal flags) must be non-null here —
  /// Item.fromJson always materialises them, so the cards never null-guard.
  Item toItem() => Item(
    id: id,
    name: name ?? subCategoryName ?? '',
    description: (itemDescription != null && itemDescription!.isNotEmpty) ? itemDescription : shortDescription,
    imageFullUrl: imageFullUrl,
    price: pricing?.price ?? 0,
    discount: 0,
    discountType: 'percent',
    avgRating: 0,
    ratingCount: 0,
    veg: 0,
    isStoreHalalActive: false,
    isHalalItem: false,
    storeId: storeId,
    moduleType: AppConstants.service,
    homeService: homeService,
    atStore: atStore,
    // An area-priced service is recognised across the app by its unit type
    // (see SquareFeetHelper), so requires=area must surface as one.
    unitType: pricing?.requiresArea == true ? (pricing?.unit ?? 'sqft') : pricing?.unit,
    variations: const [],
    foodVariations: const [],
  );
}

/// The `pricing` object of a catalog sub-category. The backend states what the price
/// depends on (`quantity` / `area` / nothing); keys are parsed tolerantly so a rename
/// on the server degrades to "no price shown" instead of a crash.
class CatalogPricing {
  /// 'quantity' | 'area' | 'nothing' (absent means fixed price).
  String? requires;
  double? price;
  String? unit;

  CatalogPricing({this.requires, this.price, this.unit});

  CatalogPricing.fromJson(Map<String, dynamic> json) {
    requires = (json['requires'] ?? json['type'] ?? json['based_on'])?.toString();
    price = _toDouble(json['price'] ?? json['base_price'] ?? json['amount'] ?? json['rate']);
    unit = (json['unit'] ?? json['unit_type'])?.toString();
  }

  bool get requiresArea => requires?.toLowerCase() == 'area';
  bool get requiresQuantity => requires?.toLowerCase() == 'quantity';
}

int? _toInt(dynamic value) => value == null ? null : int.tryParse(value.toString());

double? _toDouble(dynamic value) => value == null ? null : double.tryParse(value.toString());

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final String v = value.toString().toLowerCase();
  return v == '1' || v == 'true';
}

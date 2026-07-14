import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';

class CategoryController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;
  CategoryController({required this.categoryServiceInterface});

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  List<CategoryModel>? _subCategoryList;
  List<CategoryModel>? get subCategoryList => _subCategoryList;

  List<Item>? _categoryItemList;
  List<Item>? get categoryItemList => _categoryItemList;

  List<Store>? _categoryStoreList;
  List<Store>? get categoryStoreList => _categoryStoreList;

  List<Item>? _searchItemList = [];
  List<Item>? get searchItemList => _searchItemList;

  List<Store>? _searchStoreList = [];
  List<Store>? get searchStoreList => _searchStoreList;

  List<bool>? _interestSelectedList;
  List<bool>? get interestSelectedList => _interestSelectedList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _pageSize;
  int? get pageSize => _pageSize;

  int? _restPageSize;
  int? get restPageSize => _restPageSize;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  int _subCategoryIndex = 0;
  int get subCategoryIndex => _subCategoryIndex;

  String _type = 'all';
  String get type => _type;

  bool _isStore = false;
  bool get isStore => _isStore;

  String? _searchText = '';
  String? get searchText => _searchText;

  int _offset = 1;
  int get offset => _offset;

  void clearCategoryList() {
    _categoryList = null;
  }

  Future<void> getCategoryList(bool reload, {bool allCategory = false, DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    if(_categoryList == null || reload || fromRecall) {
      if(reload) {
        _categoryList = null;
      }
      List<CategoryModel>? categoryList;
      if(dataSource == DataSourceEnum.local) {
        categoryList = await categoryServiceInterface.getCategoryList(allCategory, source: DataSourceEnum.local);
        _prepareCategoryList(categoryList);
        getCategoryList(false, fromRecall: true, allCategory: allCategory, dataSource: DataSourceEnum.client);
      } else {
        categoryList = await categoryServiceInterface.getCategoryList(allCategory, source: DataSourceEnum.client);
        _prepareCategoryList(categoryList);
      }

    }
  }

  void _prepareCategoryList(List<CategoryModel>? categoryList) {
    if (categoryList != null) {
      _categoryList = [];
      _interestSelectedList = [];
      _categoryList!.addAll(categoryList);
      for(int i = 0; i < _categoryList!.length; i++) {
        _interestSelectedList!.add(false);
      }
    }
    update();
  }

  /// The name of the SUBcategory a service sits under — "Coloring" for a root-touch-up,
  /// never the top category ("Haircuts & Styling"). Null when the item has no subcategory
  /// or the tree has not loaded; callers must render nothing, not an error.
  ///
  /// An item carries only category IDs. Their `position` is the depth in the tree, but the
  /// numbering is NOT dependable — this backend starts at 1, others at 0 — so relying on a
  /// literal `position == 1` picks the top category on a 1-based tree. Instead: sort by
  /// depth, discard the shallowest entry (that IS the category), and return the deepest of
  /// the remainder whose name we can actually resolve.
  ///
  /// Names come from the `childes` that `/categories` already returns inline, so this costs
  /// no extra request. `/categories` only nests one level, so a third-level id resolves to
  /// nothing and we fall back to its parent — which is the subcategory we wanted anyway.
  String? subCategoryNameOf(Item item) {
    final List<CategoryIds>? ids = item.categoryIds;
    if (ids == null || ids.length < 2) {
      return null;
    }

    final List<CategoryIds> byDepth = List<CategoryIds>.from(ids)
      ..sort((CategoryIds a, CategoryIds b) => (a.position ?? 0).compareTo(b.position ?? 0));

    // Drop the shallowest: that is the top-level category, which is exactly what must not
    // be shown. Then prefer the most specific name we can put on the card.
    final List<CategoryIds> belowTop = byDepth.sublist(1).reversed.toList();

    for (final CategoryIds candidate in belowTop) {
      // The API sends the name with the id, so no lookup is normally needed.
      final String? inlineName = candidate.name;
      if (inlineName != null && inlineName.isNotEmpty) {
        return inlineName;
      }
      // Fall back to the loaded tree for payloads that send ids only.
      final String? name = _nameOfCategory(candidate.id);
      if (name != null) {
        return name;
      }
    }
    return null;
  }

  /// Finds a category's name anywhere in the loaded tree, at any depth.
  String? _nameOfCategory(int? categoryId) {
    if (categoryId == null || _categoryList == null) {
      return null;
    }
    for (final CategoryModel category in _categoryList!) {
      final String? found = _searchTree(category, categoryId);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  String? _searchTree(CategoryModel node, int categoryId) {
    for (final CategoryModel child in node.childes ?? const <CategoryModel>[]) {
      if (child.id == categoryId) {
        return child.name;
      }
      final String? deeper = _searchTree(child, categoryId);
      if (deeper != null) {
        return deeper;
      }
    }
    return null;
  }

  void getSubCategoryList(String? categoryID) async {
    _subCategoryIndex = 0;
    _subCategoryList = null;
    _categoryItemList = null;
    List<CategoryModel>? subCategoryList = await categoryServiceInterface.getSubCategoryList(categoryID);
    if (subCategoryList != null) {
      _subCategoryList= [];
      _subCategoryList!.add(CategoryModel(id: int.parse(categoryID!), name: 'all'.tr));
      _subCategoryList!.addAll(subCategoryList);
      getCategoryItemList(categoryID, 1, 'all', false);
    }
  }

  void setSubCategoryIndex(int index, String? categoryID) {
    _subCategoryIndex = index;
    if(_isStore) {
      getCategoryStoreList(_subCategoryIndex == 0 ? categoryID : _subCategoryList![index].id.toString(), 1, _type, true);
    }else {
      getCategoryItemList(_subCategoryIndex == 0 ? categoryID : _subCategoryList![index].id.toString(), 1, _type, true);
    }
  }

  void getCategoryItemList(String? categoryID, int offset, String type, bool notify) async {
    _offset = offset;
    if(offset == 1) {
      if(_type == type) {
        _isSearching = false;
      }
      _type = type;
      if(notify) {
        update();
      }
      _categoryItemList = null;
    }
    ItemModel? categoryItem = await categoryServiceInterface.getCategoryItemList(categoryID, offset, type);
    if (categoryItem != null) {
      if (offset == 1) {
        _categoryItemList = [];
      }
      _categoryItemList!.addAll(categoryItem.items!);
      _pageSize = categoryItem.totalSize;
      _isLoading = false;
    }
    update();
  }

  void getCategoryStoreList(String? categoryID, int offset, String type, bool notify) async {
    _offset = offset;
    if(offset == 1) {
      if(_type == type) {
        _isSearching = false;
      }
      _type = type;
      if(notify) {
        update();
      }
      _categoryStoreList = null;
    }
    StoreModel? categoryStore = await categoryServiceInterface.getCategoryStoreList(categoryID, offset, type);
    if (categoryStore != null) {
      if (offset == 1) {
        _categoryStoreList = [];
      }
      _categoryStoreList!.addAll(categoryStore.stores!);
      _restPageSize = categoryStore.totalSize;
      _isLoading = false;
    }
    update();
  }

  void searchData(String? query, String? categoryID, String type) async {
    if((_isStore && query!.isNotEmpty) || (!_isStore && query!.isNotEmpty /*&& query != _itemResultText*/)) {
      _searchText = query;
      _type = type;
      _isStore ? _searchStoreList = null : _searchItemList = null;
      _isSearching = true;
      update();

      Response response = await categoryServiceInterface.getSearchData(query, categoryID, _isStore, type);
      if (response.statusCode == 200) {
        if (query.isEmpty) {
          _isStore ? _searchStoreList = [] : _searchItemList = [];
        } else {
          if (_isStore) {
            _searchStoreList = [];
            _searchStoreList!.addAll(StoreModel.fromJson(response.body).stores!);
            update();
          } else {
            _searchItemList = [];
            _searchItemList!.addAll(ItemModel.fromJson(response.body).items!);
          }
        }
      }
      update();
    }
  }

  void toggleSearch() {
    _isSearching = !_isSearching;
    _searchItemList = [];
    if(_categoryItemList != null) {
      _searchItemList!.addAll(_categoryItemList!);
    }
    update();
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  Future<bool> saveInterest(List<int?> interests) async {
    _isLoading = true;
    update();
    bool isSuccess = await categoryServiceInterface.saveUserInterests(interests);
    _isLoading = false;
    update();
    return isSuccess;
  }

  void addInterestSelection(int index) {
    _interestSelectedList![index] = !_interestSelectedList![index];
    update();
  }

  void setRestaurant(bool isRestaurant) {
    _isStore = isRestaurant;
    update();
  }

}

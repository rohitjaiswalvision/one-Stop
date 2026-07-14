import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/services/store_service_interface.dart';

/// Backs the salon drill-down: the customer taps a category chip inside a provider
/// (e.g. "Coloring" in Art Villa Salon) and lands on that category's children
/// ("Highlights", "root touch-ups", "global color") with the provider's services beneath.
///
/// Everything stays scoped to the one provider — `/items/get-store-items` takes both a
/// `store_id` and a `category_id`, so "Highlights at this salon" is a single call.
///
/// Kept out of [StoreController] on purpose: that controller still owns the salon screen
/// underneath this one, and mutating its item list here would corrupt the page the
/// customer returns to on back.
class ServiceStoreCategoryController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;
  final StoreServiceInterface storeServiceInterface;
  ServiceStoreCategoryController({
    required this.categoryServiceInterface, required this.storeServiceInterface,
  });

  static const int pageSize = 20;

  int? _storeId;
  int? _parentCategoryId;

  /// "All" first, then the parent category's children. "All" carries the PARENT's id, so
  /// selecting it lists everything in the category rather than nothing.
  List<CategoryModel>? _children;
  List<CategoryModel>? get children => _children;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  List<Item>? _items;
  List<Item>? get items => _items;   // null while loading -> ItemsView shimmers

  int _totalSize = 0;
  int _offset = 1;
  int get offset => _offset;
  int get totalSize => _totalSize;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get hasMore => _items != null && _items!.length < _totalSize;

  /// The category the list is currently filtered by: the parent while "All" is selected,
  /// otherwise the chosen child.
  int? get selectedCategoryId {
    if (_children == null || _selectedIndex <= 0 || _selectedIndex >= _children!.length) {
      return _parentCategoryId;
    }
    return _children![_selectedIndex].id;
  }

  Future<void> init({required int storeId, required int categoryId, required String categoryName}) async {
    _storeId = storeId;
    _parentCategoryId = categoryId;
    _selectedIndex = 0;
    _children = null;
    _items = null;
    _totalSize = 0;
    _offset = 1;
    update();

    final List<CategoryModel>? childes = await categoryServiceInterface.getSubCategoryList(categoryId.toString());

    _children = [CategoryModel(id: categoryId, name: 'all'.tr)];
    if (childes != null) {
      _children!.addAll(childes);
    }
    update();

    await _load(1);
  }

  Future<void> _load(int offset) async {
    _isLoading = true;
    if (offset == 1) {
      _items = null;
    }
    update();

    final ItemModel? result = await storeServiceInterface.getStoreItemList(
      storeID: _storeId, offset: offset, categoryID: selectedCategoryId, type: 'all',
    );

    final List<Item> loaded = result?.items ?? [];
    if (offset == 1) {
      _items = loaded;
    } else {
      _items = [...?_items, ...loaded];
    }

    // The reported total can exceed what the store actually serves us; trust what arrived,
    // otherwise "load more" would spin forever on a page that returns nothing.
    final int reported = result?.totalSize ?? loaded.length;
    _totalSize = loaded.isEmpty ? _items!.length : (reported < _items!.length ? _items!.length : reported);
    _offset = offset;

    _isLoading = false;
    update();
  }

  void selectChild(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    _load(1);
  }

  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    await _load(_offset + 1);
  }
}

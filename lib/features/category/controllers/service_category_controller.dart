import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/category/domain/services/category_service_interface.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';

/// Drives the service category landing page: a category resolves to a list of
/// subcategory *sections*, each holding its own services, its own total and its own
/// pagination cursor.
///
/// Deliberately separate from [CategoryController], which backs the home screen, the
/// store screen and the generic category screen for every module. That controller keeps
/// one flat item list and injects a synthetic "All" entry at index 0 — neither of which
/// this page wants — and widening it would rebuild every one of its listeners across the
/// app on each section load.
class ServiceCategoryController extends GetxController implements GetxService {
  final CategoryServiceInterface categoryServiceInterface;
  ServiceCategoryController({required this.categoryServiceInterface});

  /// Services shown per section before "see all". Small on purpose: N sections load in
  /// parallel on open, so this multiplies.
  static const int sectionPageSize = 6;

  String? _parentId;
  String? _parentName;
  String? get parentId => _parentId;
  String? get parentName => _parentName;

  /// True when this page is fed by the service catalog (`/services/catalog/...`), where
  /// [_parentId] is a catalog *service* id, the sections are its categories, and each
  /// tile is a bookable sub-category. False on the legacy category tree — kept as a
  /// fallback until the catalog endpoints are live everywhere.
  bool _usesCatalog = false;
  bool get usesCatalog => _usesCatalog;

  /// The sections down the page. Null while loading; one synthetic entry pointing at the
  /// parent when the category has no subcategories.
  List<CategoryModel>? _sections;
  List<CategoryModel>? get sections => _sections;

  /// A section id ABSENT from this map means "not loaded yet" and must surface as null,
  /// because ItemsView renders its shimmer on null and its no-data screen on empty.
  final Map<int, List<Item>> _sectionItems = {};
  final Map<int, int> _sectionTotal = {};
  final Map<int, int> _sectionOffset = {};
  final Map<int, bool> _sectionBusy = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _selectedSectionIndex = 0;
  int get selectedSectionIndex => _selectedSectionIndex;

  double _derivedRating = 0;
  int _derivedRatingCount = 0;
  int _maxDiscountPercent = 0;

  double get derivedRating => _derivedRating;
  int get derivedRatingCount => _derivedRatingCount;
  int get maxDiscountPercent => _maxDiscountPercent;

  /// Both header extras hide entirely when there is nothing real behind them — there is
  /// no category-level rating or offer in the API, so an empty corpus shows nothing
  /// rather than a fabricated 0.0.
  bool get showRatingLine => _derivedRatingCount > 0;
  bool get showOfferStrip => _maxDiscountPercent > 0;

  List<Item>? itemsOf(int sectionId) => _sectionItems[sectionId];
  int totalOf(int sectionId) => _sectionTotal[sectionId] ?? 0;
  bool isSectionBusy(int sectionId) => _sectionBusy[sectionId] ?? false;
  bool hasMore(int sectionId) => totalOf(sectionId) > (_sectionItems[sectionId]?.length ?? 0);

  Future<void> initCategory(String categoryId, String categoryName) async {
    reset();
    _parentId = categoryId;
    _parentName = categoryName;
    _isLoading = true;
    update();

    // Catalog first: on the new backend the id opening this page is a catalog service id
    // and its categories are the sections. Null means the catalog endpoint is not there
    // (or the id predates it) — fall back to the legacy subcategory tree.
    List<CategoryModel>? children = await categoryServiceInterface.getCatalogServiceCategories(categoryId);
    _usesCatalog = children != null;
    if (!_usesCatalog) {
      children = await categoryServiceInterface.getSubCategoryList(categoryId);
    }

    if (children == null || children.isEmpty) {
      // Only the legacy tree can treat the parent as a section of its own — the catalog's
      // sub-category listing requires a real category id, which we don't have here.
      _sections = _usesCatalog ? <CategoryModel>[] : [CategoryModel(id: int.tryParse(categoryId), name: categoryName)];
    } else {
      _sections = children;
    }

    await Future.wait(_sections!
        .where((CategoryModel section) => section.id != null)
        .map((CategoryModel section) => _loadPage(section.id!, 1)));

    // Guard: services may be tagged against the parent category only, in which case every
    // child section comes back empty and the page would render as a wall of "no services".
    // Fall back to a single section over the parent so the customer still sees them.
    // Legacy tree only — the catalog has no parent-as-category to fall back onto.
    final bool everySectionEmpty = _sections!.every((CategoryModel s) => totalOf(s.id ?? -1) == 0);
    if (!_usesCatalog && everySectionEmpty && _sections!.length > 1) {
      if (kDebugMode) {
        print('[ServiceCategory] all subcategories empty — falling back to parent $categoryId');
      }
      _sectionItems.clear();
      _sectionTotal.clear();
      _sectionOffset.clear();
      _sections = [CategoryModel(id: int.tryParse(categoryId), name: categoryName)];
      await _loadPage(_sections!.first.id!, 1);
    }

    _recomputeDerived();
    _isLoading = false;
    update();
  }

  /// Backs the category landing page (services → sheet → *this*): one catalog category
  /// whose sub-categories are the "Select a service" list. Reuses the section machinery
  /// with a single section, so paging, totals and the derived header all keep working.
  Future<void> initCatalogCategory({required String serviceId, required String categoryId, required String categoryName}) async {
    reset();
    _usesCatalog = true;
    _parentId = serviceId;
    _parentName = categoryName;
    _isLoading = true;
    update();

    final int sectionId = int.tryParse(categoryId) ?? -1;
    _sections = [CategoryModel(id: sectionId, name: categoryName)];
    await _loadPage(sectionId, 1);

    _recomputeDerived();
    _isLoading = false;
    update();
  }

  Future<void> _loadPage(int sectionId, int offset) async {
    _sectionBusy[sectionId] = true;

    final ItemModel? result = _usesCatalog
        ? await categoryServiceInterface.getCatalogSubCategories(
            categoryId: sectionId.toString(), serviceId: _parentId ?? '',
            offset: offset, limit: sectionPageSize,
          )
        : await categoryServiceInterface.getCategoryItemList(
            sectionId.toString(), offset, 'all', limit: sectionPageSize,
          );

    if (result != null) {
      final List<Item> loaded = result.items ?? [];
      if (offset == 1) {
        _sectionItems[sectionId] = loaded;
      } else {
        _sectionItems[sectionId] = [...?_sectionItems[sectionId], ...loaded];
      }

      // `total_size` counts what the category holds, but the items array is filtered by
      // zone and store availability — so the two can disagree, and the server can report
      // a total while returning nothing we may show. Trust the items we actually got:
      // otherwise the section advertises a "see all" that would load nothing.
      final int reported = result.totalSize ?? loaded.length;
      final int held = _sectionItems[sectionId]!.length;
      _sectionTotal[sectionId] = loaded.isEmpty ? held : (reported < held ? held : reported);
      _sectionOffset[sectionId] = offset;
    } else {
      // Keep the key present so the section renders "no services" rather than shimmering forever.
      _sectionItems.putIfAbsent(sectionId, () => <Item>[]);
      _sectionTotal.putIfAbsent(sectionId, () => 0);
    }

    _sectionBusy[sectionId] = false;
  }

  Future<void> loadMore(int sectionId) async {
    if (isSectionBusy(sectionId) || !hasMore(sectionId)) return;
    update();
    await _loadPage(sectionId, (_sectionOffset[sectionId] ?? 1) + 1);
    _recomputeDerived();
    update();
  }

  void setSelectedSection(int index) {
    if (_selectedSectionIndex == index) return;
    _selectedSectionIndex = index;
    update();
  }

  /// Header rating and offer strip, derived from the services actually loaded. Stored as
  /// fields rather than getters so the collapsing app bar does not recompute them on
  /// every scroll frame.
  void _recomputeDerived() {
    final Iterable<Item> all = _sectionItems.values.expand((List<Item> list) => list);

    double ratingSum = 0;
    int ratingCount = 0;
    double bestDiscount = 0;

    for (final Item item in all) {
      final int count = item.ratingCount ?? 0;
      if (count > 0) {
        // Weighted by rating count: a lone 5.0 must not outrank a 4.5 with 200 ratings.
        ratingSum += (item.avgRating ?? 0) * count;
        ratingCount += count;
      }

      final double discount = item.discount ?? 0;
      if (discount > 0) {
        double percent = 0;
        if (item.discountType == 'percent') {
          percent = discount;
        } else if ((item.price ?? 0) > 0) {
          percent = discount / item.price! * 100;
        }
        if (percent > bestDiscount) {
          bestDiscount = percent;
        }
      }
    }

    _derivedRating = ratingCount > 0 ? ratingSum / ratingCount : 0;
    _derivedRatingCount = ratingCount;
    // Floor, never round up — the strip must not promise a discount no service offers.
    _maxDiscountPercent = bestDiscount.floor();
  }

  void reset() {
    _usesCatalog = false;
    _sections = null;
    _sectionItems.clear();
    _sectionTotal.clear();
    _sectionOffset.clear();
    _sectionBusy.clear();
    _selectedSectionIndex = 0;
    _derivedRating = 0;
    _derivedRatingCount = 0;
    _maxDiscountPercent = 0;
    _parentId = null;
    _parentName = null;
  }
}

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

    final List<CategoryModel>? children = await categoryServiceInterface.getSubCategoryList(categoryId);

    if (children == null || children.isEmpty) {
      _sections = [CategoryModel(id: int.tryParse(categoryId), name: categoryName)];
    } else {
      _sections = children;
    }

    await Future.wait(_sections!
        .where((CategoryModel section) => section.id != null)
        .map((CategoryModel section) => _loadPage(section.id!, 1)));

    // Guard: services may be tagged against the parent category only, in which case every
    // child section comes back empty and the page would render as a wall of "no services".
    // Fall back to a single section over the parent so the customer still sees them.
    final bool everySectionEmpty = _sections!.every((CategoryModel s) => totalOf(s.id ?? -1) == 0);
    if (everySectionEmpty && _sections!.length > 1) {
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

  Future<void> _loadPage(int sectionId, int offset) async {
    _sectionBusy[sectionId] = true;

    final ItemModel? result = await categoryServiceInterface.getCategoryItemList(
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

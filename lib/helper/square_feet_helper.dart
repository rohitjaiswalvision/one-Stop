import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/cart/widgets/square_feet_bottom_sheet.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Area-based pricing for the service module.
///
/// A service whose `unit_type` is set to square feet is priced per square foot
/// rather than per piece. The area the customer enters is carried in the cart's
/// existing `quantity` field, so `price * quantity` — the line-total formula used
/// everywhere in the app and on the server — already yields the correct total.
class SquareFeetHelper {
  SquareFeetHelper._();

  /// Every spelling of "square feet" an admin might type into `unit_type`,
  /// compared after stripping spaces, dots, dashes and underscores.
  static const List<String> _squareFeetUnits = ['sqft', 'sqfeet', 'sqfoot', 'squarefeet', 'squarefoot', 'sft'];

  static bool isSquareFeetItem(Item? item) {
    if (item == null || !_inServiceModule(item)) {
      return false;
    }
    final String? unitType = item.unitType?.toLowerCase().replaceAll(RegExp(r'[\s._-]'), '');
    return unitType != null && _squareFeetUnits.contains(unitType);
  }

  static bool _inServiceModule(Item item) {
    if (item.moduleType != null && item.moduleType!.isNotEmpty) {
      return item.moduleType == AppConstants.service;
    }
    return ModuleHelper.getModule()?.moduleType == AppConstants.service;
  }

  /// The unit as the admin spelled it, falling back to a translated label.
  static String unitLabel(Item? item) {
    final String unitType = item?.unitType ?? '';
    return unitType.isNotEmpty ? unitType : 'sq_ft'.tr;
  }

  /// e.g. `₹20 / sqft` — the rate a service card and the sheet advertise.
  static String ratePerUnit(Item item) {
    final String price = PriceConverter.convertPrice(item.price, discount: item.discount, discountType: item.discountType);
    return '$price / ${unitLabel(item)}';
  }

  /// ` / sqft` for an area-priced item, empty otherwise — appended to a price label.
  static String perUnitSuffix(Item? item) => isSquareFeetItem(item) ? ' / ${unitLabel(item)}' : '';

  /// e.g. `10 sqft × ₹20 / sqft` — the breakdown shown under the item in the cart.
  static String areaBreakdown(CartModel cart) {
    return '${cart.quantity} ${unitLabel(cart.item)} × ${ratePerUnit(cart.item!)}';
  }

  /// Opens the area-entry sheet. Pass [cart]/[cartIndex] to edit an existing line.
  static void openSquareFeetSheet(Item item, {CartModel? cart, int? cartIndex}) {
    final Widget sheet = SquareFeetBottomSheet(item: item, cart: cart, cartIndex: cartIndex);
    if (ResponsiveHelper.isMobile(Get.context)) {
      Get.bottomSheet(sheet, backgroundColor: Colors.transparent, isScrollControlled: true);
    } else {
      Get.dialog(Dialog(backgroundColor: Colors.transparent, child: sheet));
    }
  }
}

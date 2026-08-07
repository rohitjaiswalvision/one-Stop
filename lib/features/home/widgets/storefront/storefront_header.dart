import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/widgets/storefront/storefront_department_chips.dart';
import 'package:sixam_mart/features/home/widgets/storefront/storefront_tokens.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Blue storefront header: pill search + cart on top, the delivery address strip
/// under it, and the department chips sitting on the page surface below.
///
/// It paints its own status-bar inset (the home body is mounted with `top: false`
/// SafeArea) so the blue runs edge to edge behind the clock and battery.
class StorefrontHeader extends StatelessWidget {
  /// Hides the address strip and chips for module surfaces that have no catalog
  /// behind them (the module grid, taxi, ride), leaving just search and cart.
  final bool showCatalogRow;
  const StorefrontHeader({super.key, this.showCatalogRow = true});

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: StorefrontTokens.blue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Container(
          width: double.infinity,
          color: StorefrontTokens.blue,
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault, topInset + Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: _searchPill(context)),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _cartButton(context),
            ]),

            if(showCatalogRow) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _deliveryStrip(context),
            ],
          ]),
        ),

        if(showCatalogRow) const StorefrontDepartmentChips(),
      ]),
    );
  }

  Widget _searchPill(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
      borderRadius: BorderRadius.circular(StorefrontTokens.pillRadius),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(StorefrontTokens.pillRadius),
        ),
        child: Row(children: [
          const Icon(Icons.search, size: 22, color: Color(0xFF6B7280)),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Text(
            'search_item_or_store'.tr,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: const Color(0xFF6B7280)),
          )),

          const Icon(Icons.qr_code_scanner, size: 22, color: Color(0xFF4B5563)),
        ]),
      ),
    );
  }

  /// Cart glyph with its item-count bubble, and the running total underneath —
  /// the total is what makes the header feel like a till rather than a link.
  Widget _cartButton(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: GetBuilder<CartController>(builder: (cartController) {
        final int count = cartController.cartList.length;
        return Column(mainAxisSize: MainAxisSize.min, children: [

          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.shopping_cart_outlined, size: 26, color: Colors.white),

            Positioned(
              top: -6, right: -8,
              child: Container(
                height: 18, width: 18, alignment: Alignment.center,
                decoration: const BoxDecoration(color: StorefrontTokens.yellow, shape: BoxShape.circle),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: robotoBold.copyWith(fontSize: count > 99 ? 8 : 10, color: StorefrontTokens.blueDeep),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 2),

          Text(
            PriceConverter.convertPrice(cartController.calculationCart()),
            textDirection: TextDirection.ltr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Colors.white),
          ),
        ]);
      }),
    );
  }

  /// "Pickup or delivery?" + the saved address, opening the location picker.
  Widget _deliveryStrip(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController) {
      final String? address = AddressHelper.getUserAddressFromSharedPref()?.address;
      final bool hasAddress = address != null && address.isNotEmpty;

      return InkWell(
        onTap: () => locationController.navigateToLocationScreen('home'),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Row(children: [

          Container(
            height: 26, width: 26, alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_rounded, size: 15, color: StorefrontTokens.blue),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Text(
            'pickup_or_delivery'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Text(
            hasAddress ? address : (AuthHelper.isLoggedIn() ? 'set_your_location'.tr : 'select_your_location'.tr),
            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
          )),

          const Icon(Icons.keyboard_arrow_down, size: 22, color: Colors.white),
        ]),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/square_feet_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Asks the customer for the area of a per-square-foot service, then puts the
/// line in the cart with `quantity` set to that area — see [SquareFeetHelper].
class SquareFeetBottomSheet extends StatefulWidget {
  final Item item;
  final CartModel? cart;
  final int? cartIndex;
  const SquareFeetBottomSheet({super.key, required this.item, this.cart, this.cartIndex});

  @override
  State<SquareFeetBottomSheet> createState() => _SquareFeetBottomSheetState();
}

class _SquareFeetBottomSheetState extends State<SquareFeetBottomSheet> {
  final TextEditingController _areaController = TextEditingController();
  final FocusNode _areaFocus = FocusNode();
  int _squareFeet = 0;

  bool get _isEditing => widget.cart != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _squareFeet = widget.cart!.quantity ?? 0;
      _areaController.text = '$_squareFeet';
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _areaFocus.dispose();
    super.dispose();
  }

  double get _unitPrice => PriceConverter.convertWithDiscount(widget.item.price!, widget.item.discount, widget.item.discountType)!;

  double get _totalPrice => _unitPrice * _squareFeet;

  @override
  Widget build(BuildContext context) {
    final String unit = SquareFeetHelper.unitLabel(widget.item);

    return Container(
      width: 550,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      margin: EdgeInsets.only(top: ResponsiveHelper.isMobile(context) ? 30 : 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isMobile(context)
            ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge))
            : BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: CustomImage(image: '${widget.item.imageFullUrl}', height: 60, width: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.item.name!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(
                SquareFeetHelper.ratePerUnit(widget.item),
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                textDirection: TextDirection.ltr,
              ),
            ])),

            InkWell(
              onTap: () => Get.back(),
              child: Icon(Icons.close, size: 22, color: Theme.of(context).disabledColor),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text('${'enter_area_in'.tr} $unit', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          TextField(
            controller: _areaController,
            focusNode: _areaFocus,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            decoration: InputDecoration(
              hintText: 'e_g_10'.tr,
              hintStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
              suffixText: unit,
              suffixStyle: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            onChanged: (String value) => setState(() => _squareFeet = int.tryParse(value) ?? 0),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text(
                  '${_squareFeet > 0 ? _squareFeet : 0} $unit × ${SquareFeetHelper.ratePerUnit(widget.item)}',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  textDirection: TextDirection.ltr,
                )),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('total_amount'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                Text(
                  PriceConverter.convertPrice(_totalPrice),
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                  textDirection: TextDirection.ltr,
                ),
              ]),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          SafeArea(child: GetBuilder<CartController>(builder: (cartController) {
            return CustomButton(
              isLoading: cartController.isLoading,
              buttonText: _isEditing ? 'update_in_cart'.tr : 'add_to_cart'.tr,
              onPressed: _squareFeet > 0 ? () => _submit(cartController) : null,
            );
          })),
        ]),
      ),
    );
  }

  Future<void> _submit(CartController cartController) async {
    if (_squareFeet <= 0) {
      showCustomSnackBar('enter_a_valid_area'.tr, getXSnackBar: true);
      return;
    }

    final Item item = widget.item;
    final double price = item.price!;
    final double discount = item.discount ?? 0;
    final double discountedPrice = PriceConverter.convertWithDiscount(price, discount, item.discountType)!;

    final CartModel cartModel = CartModel(
      widget.cart?.id, price, discount, [], [], (price - discountedPrice), _squareFeet, [], [], false,
      item.stock, item, item.quantityLimit,
    );

    final OnlineCart onlineCart = OnlineCart(
      widget.cart?.id, item.id, null, price.toString(), '', null,
      ModuleHelper.getModuleConfig(item.moduleType).newVariation! ? [] : null,
      // quantity carries the measured area (see SquareFeetHelper) — confirmed against the
      // backend that price * quantity is what yields the correct order total. area is also
      // sent as supplementary info. The per-item `maximum_cart_quantity` cap that can reject
      // a large area value is an admin-side setting to raise for area-priced items, not
      // something the client should work around by changing what quantity means.
      _squareFeet, [], [], [], 'Item', area: _squareFeet,
    );

    if (Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && (item.stock ?? 0) <= 0) {
      showCustomSnackBar('out_of_stock'.tr, getXSnackBar: true);
      return;
    }

    if (!_isEditing && cartController.existAnotherStoreItem(
      cartModel.item!.storeId,
      ModuleHelper.getModule() != null ? ModuleHelper.getModule()?.id : ModuleHelper.getCacheModule()?.id,
    )) {
      Get.dialog(ConfirmationDialog(
        icon: Images.warning,
        title: 'are_you_sure_to_reset'.tr,
        description: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
            ? 'if_you_continue'.tr : 'if_you_continue_without_another_store'.tr,
        onYesPressed: () {
          Get.back();
          cartController.clearCartOnline().then((bool success) async {
            if (success) {
              await cartController.addToCartOnline(onlineCart);
              Get.find<ItemController>().setExistInCart(item, null);
              Get.back();
            }
          });
        },
      ), barrierDismissible: false);
      return;
    }

    final bool success = _isEditing
        ? await cartController.updateCartOnline(onlineCart)
        : await cartController.addToCartOnline(onlineCart);

    if (success) {
      Get.find<ItemController>().setExistInCart(item, null);
      Get.back();
    }
  }
}

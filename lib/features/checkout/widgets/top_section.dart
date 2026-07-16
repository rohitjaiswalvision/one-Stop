import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/checkout/widgets/guest_create_account.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/features/cart/widgets/delivery_option_button_widget.dart';
import 'package:sixam_mart/features/checkout/widgets/coupon_section.dart';
import 'package:sixam_mart/features/checkout/widgets/delivery_instruction_view.dart';
import 'package:sixam_mart/features/checkout/widgets/delivery_section.dart';
import 'package:sixam_mart/features/checkout/widgets/deliveryman_tips_section.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_section.dart';
import 'package:sixam_mart/features/checkout/widgets/time_slot_section.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/service_booking/controllers/service_booking_controller.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_slot_model.dart';
import 'package:sixam_mart/features/service_booking/widgets/service_schedule_bottom_sheet.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/features/checkout/widgets/web_delivery_instruction_view.dart';

import 'upload_prescription_widget.dart';

class TopSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final double charge;
  final double deliveryCharge;
  final List<DropdownItem<int>> addressList;
  final bool tomorrowClosed;
  final bool todayClosed;
  final Module? module;
  final  double price;
  final double discount;
  final double addOns;
  final int? storeId;
  final List<AddressModel> address;
  final List<CartModel?>? cartList;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final double total;
  final bool isOfflinePaymentActive;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  final JustTheController tooltipController1;
  final JustTheController tooltipController2;
  final JustTheController dmTipsTooltipController;
  final TextEditingController guestPasswordController;
  final TextEditingController guestConfirmPasswordController;
  final FocusNode guestPasswordNode;
  final FocusNode guestConfirmPasswordNode;
  final double variationPrice;
  final String deliveryChargeForView;
  final double badWeatherCharge;
  final double extraChargeForToolTip;

  const TopSection({
    super.key, required this.deliveryCharge, required  this.charge, required this.tomorrowClosed,
    required this.todayClosed, required this.price, required this.discount, required this.addOns,
    required this.addressList, required this.checkoutController,
    this.module, this.storeId, required this.address, required this.cartList,
    required this.isCashOnDeliveryActive, required this.isDigitalPaymentActive, required this.isWalletActive,
    required this.total, required this.isOfflinePaymentActive, required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController, required this.guestNumberNode,
    required this.guestEmailController, required this.guestEmailNode, required this.tooltipController1,
    required this.tooltipController2, required this.dmTipsTooltipController, required this.guestPasswordController, required this.guestConfirmPasswordController,
    required this.guestPasswordNode, required this.guestConfirmPasswordNode, required this.variationPrice, required this.deliveryChargeForView,
    required this.badWeatherCharge, required this.extraChargeForToolTip,
  });

  @override
  Widget build(BuildContext context) {
    bool takeAway = (checkoutController.orderType == 'take_away');
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();

    return Container(
      decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ) : null,
      child: Column(children: [

        // No prescription upload for services.
        !AuthHelper.isGuestLoggedIn() && storeId != null && !ModuleHelper.isService() ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
          child: UploadPrescriptionWidget(
            checkoutController: checkoutController, storeId: storeId, isPrescriptionRequired: storeId != null,
            tooltipController1: tooltipController1, tooltipController2: tooltipController2,
          ),
        ) : const SizedBox(),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // delivery option
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
          width: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('delivery_type'.tr, style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              storeId != null ? DeliveryOptionButtonWidget(
                value: 'delivery', title: 'home_delivery'.tr, charge: charge,
                isFree: (checkoutController.store!.freeDelivery?? false) || deliveryCharge == 0, fromWeb: true, total: total,
                deliveryChargeForView: deliveryChargeForView, badWeatherCharge: badWeatherCharge, extraChargeForToolTip: extraChargeForToolTip,
              ) : SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                Get.find<SplashController>().configModel!.homeDeliveryStatus == 1 && checkoutController.store!.delivery! ? DeliveryOptionButtonWidget(
                  value: 'delivery', title: 'home_delivery'.tr, charge: charge,
                  isFree: (checkoutController.store!.freeDelivery?? false) || deliveryCharge == 0,  fromWeb: true, total: total,
                  deliveryChargeForView: deliveryChargeForView, badWeatherCharge: badWeatherCharge, extraChargeForToolTip: extraChargeForToolTip,
                ) : const SizedBox(),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                Get.find<SplashController>().configModel!.takeawayStatus == 1 && checkoutController.store!.takeAway! ? DeliveryOptionButtonWidget(
                  value: 'take_away', title: 'take_away'.tr, charge: deliveryCharge, isFree: true,  fromWeb: true, total: total,
                  deliveryChargeForView: deliveryChargeForView, badWeatherCharge: badWeatherCharge, extraChargeForToolTip: extraChargeForToolTip,
                ) : const SizedBox(),
              ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        ///delivery section
        DeliverySection(checkoutController: checkoutController, address: address, addressList: addressList,
          guestNameTextEditingController: guestNameTextEditingController, guestNumberTextEditingController: guestNumberTextEditingController,
          guestNumberNode: guestNumberNode, guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
        ),

        SizedBox(height: !takeAway ? isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall : 0),

        ///Create Account with existing info
        isGuestLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus! ? GuestCreateAccount(
          guestPasswordController: guestPasswordController, guestConfirmPasswordController: guestConfirmPasswordController,
          guestPasswordNode: guestPasswordNode, guestConfirmPasswordNode: guestConfirmPasswordNode,
        ) : const SizedBox(),
        SizedBox(height: isGuestLoggedIn && Get.find<SplashController>().configModel!.centralizeLoginSetup!.manualLoginStatus! ? Dimensions.paddingSizeSmall : 0),

        ///delivery instruction
        !takeAway ? isDesktop ? const WebDeliveryInstructionView() : const DeliveryInstructionView() : const SizedBox(),
        SizedBox(height: !takeAway ? isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall : 0),

        /// Time Slot — the service module replaces the generic slot picker with
        /// server-driven appointment slots (date + slot grid) per service item.
        (Get.find<SplashController>().module?.moduleType.toString() == AppConstants.service)
            ? _serviceSlotSection(context)
            : TimeSlotSection(
                storeId: storeId, checkoutController: checkoutController, cartList: cartList, tooltipController2: tooltipController2,
                tomorrowClosed: tomorrowClosed, todayClosed: todayClosed, module: module,
              ),

        /// Coupon..
        !isDesktop && !isGuestLoggedIn ? CouponSection(
          storeId: storeId, checkoutController: checkoutController, total: total, price: price,
          discount: discount, addOns: addOns, deliveryCharge: deliveryCharge, variationPrice: variationPrice,
        ) : const SizedBox(),

        ///DmTips..
        DeliveryManTipsSection(
          takeAway: takeAway, tooltipController3: dmTipsTooltipController,
          totalPrice: total, onTotalChange: (double price) => total + price, storeId: storeId,
        ),

        ///Payment..
        Container(
          decoration: isDesktop ? const BoxDecoration() : BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: Dimensions.paddingSizeLarge),
          child: Column(children: [

            // A service is settled with the vendor after the work is done, so there is
            // nothing to choose here — the picker is replaced by a plain explanation.
            ModuleHelper.isService() ? _payAfterServiceNote(context) : PaymentSection(
              storeId: storeId, isCashOnDeliveryActive: isCashOnDeliveryActive, isDigitalPaymentActive: isDigitalPaymentActive,
              isWalletActive: isWalletActive, total: total, checkoutController: checkoutController, isOfflinePaymentActive: isOfflinePaymentActive,
            ),

          ]),
        ),
        SizedBox(height: isDesktop ? Dimensions.paddingSizeLarge : 0),

      ]),
    );
  }

  /// Stands in for the payment-method picker in the service module: there is nothing to
  /// pay now, so the customer is simply told when and how they will pay.
  Widget _payAfterServiceNote(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.verified_outlined, color: Theme.of(context).primaryColor, size: 22),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('pay_after_service'.tr, style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor,
          )),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Text('you_will_pay_the_provider_after_the_work_is_done'.tr, style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
          )),
        ])),
      ]),
    );
  }

  /// One appointment slot picker per service item in the cart.
  Widget _serviceSlotSection(BuildContext context) {
    final List<CartModel?> items = cartList ?? [];
    final List<CartModel> serviceItems = items.whereType<CartModel>().where((c) => c.item != null).toList();
    if(serviceItems.isEmpty) return const SizedBox();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for(int i = 0; i < serviceItems.length; i++) ...[
          if(serviceItems.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Text(serviceItems[i].item!.name ?? '', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
            ),
          _chooseScheduleField(context, serviceItems[i].item!),
          if(i != serviceItems.length - 1) const Divider(height: Dimensions.paddingSizeExtraLarge),
        ],
      ]),
    );
  }

  /// Collapsed "Choose Schedule" field. Tapping it opens the date + time-slot
  /// picker in a bottom sheet (dialog on desktop); the field itself shows the
  /// selected schedule once picked.
  Widget _chooseScheduleField(BuildContext context, Item item) {
    return GetBuilder<ServiceBookingController>(builder: (controller) {
      final ServiceSlot? slot = controller.selectedSlot(item.id!);
      final bool hasSelection = slot != null;
      final String summary = hasSelection
          ? '${DateConverter.dateToReadableDate(controller.selectedDate(item.id!))}  •  ${slot.displayLabel}'
          : 'select_your_schedule'.tr;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('choose_schedule'.tr, style: robotoMedium),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        InkWell(
          onTap: () => _openScheduleSheet(context, item),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor, width: 0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Row(children: [
              Icon(Icons.calendar_month_outlined, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: Text(
                  summary, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(
                    color: hasSelection ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).disabledColor,
                  ),
                ),
              ),

              const Icon(Icons.arrow_drop_down, size: 28),
            ]),
          ),
        ),
      ]);
    });
  }

  void _openScheduleSheet(BuildContext context, Item item) {
    // checkoutController.store is the full Store (loaded in initCheckoutData), so it
    // already carries the weekly `schedules` the picker needs for opening hours.
    final Store? store = checkoutController.store;
    if(ResponsiveHelper.isDesktop(context)) {
      showDialog(context: context, builder: (con) => Dialog(child: ServiceScheduleBottomSheet(item: item, store: store)));
    } else {
      showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (con) => ServiceScheduleBottomSheet(item: item, store: store),
      );
    }
  }
}

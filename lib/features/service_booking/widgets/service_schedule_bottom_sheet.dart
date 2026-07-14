import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/service_booking/controllers/service_booking_controller.dart';
import 'package:sixam_mart/features/service_booking/widgets/service_slot_picker.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Bottom sheet (dialog on desktop) that hosts the date + time-slot picker for a
/// single service item. Opened from the "Choose Schedule" field in checkout so
/// the slot grid stays collapsed until the user taps it. All selection state
/// lives in [ServiceBookingController] (keyed by item id), so it persists after
/// the sheet is dismissed.
class ServiceScheduleBottomSheet extends StatelessWidget {
  final Item item;

  /// The service provider, supplying the opening hours the picker validates a
  /// hand-entered time against. Optional — without it the picker shows chips only.
  final Store? store;
  const ServiceScheduleBottomSheet({super.key, required this.item, this.store});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Container(
      width: isDesktop ? 550 : context.width,
      constraints: BoxConstraints(maxHeight: context.height * 0.85, minHeight: 0),
      margin: EdgeInsets.only(top: GetPlatform.isWeb ? 0 : 30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: isDesktop
            ? const BorderRadius.all(Radius.circular(Dimensions.radiusDefault))
            : const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          if(!isDesktop) Container(
            height: 4, width: 35,
            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(color: Theme.of(context).disabledColor, borderRadius: BorderRadius.circular(10)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall,
            ),
            child: Row(children: [
              Expanded(
                child: Text('schedule_your_service'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
            ]),
          ),
          const Divider(height: 0),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: ServiceSlotPicker(item: item, store: store),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: GetBuilder<ServiceBookingController>(builder: (controller) {
              final bool ready = controller.selectedSlot(item.id!) != null;
              return CustomButton(
                buttonText: 'confirm'.tr,
                isBold: !isDesktop,
                radius: isDesktop ? Dimensions.radiusSmall : Dimensions.radiusDefault,
                height: isDesktop ? 50 : null,
                onPressed: ready ? () => Get.back() : null,
              );
            }),
          ),

        ]),
      ),
    );
  }
}

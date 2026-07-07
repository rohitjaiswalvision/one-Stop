import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/service_booking/controllers/service_booking_controller.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_slot_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Date picker + location toggle + server-driven time-slot grid for a single
/// service item. The `slots` list from the backend is the ONLY source of
/// availability — nothing is computed client-side.
class ServiceSlotPicker extends StatefulWidget {
  final Item item;
  final int dayRange;
  const ServiceSlotPicker({super.key, required this.item, this.dayRange = 14});

  @override
  State<ServiceSlotPicker> createState() => _ServiceSlotPickerState();
}

class _ServiceSlotPickerState extends State<ServiceSlotPicker> {
  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ServiceBookingController>().initItem(
        itemId: widget.item.id!,
        atStore: widget.item.atStore ?? true,
        homeService: widget.item.homeService ?? false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final int itemId = widget.item.id!;
    final bool showStore = widget.item.atStore ?? true;
    final bool showHome = widget.item.homeService ?? false;

    return GetBuilder<ServiceBookingController>(builder: (controller) {
      final DateTime selected = controller.selectedDate(itemId);
      final List<ServiceSlot> slots = controller.slotsFor(itemId);
      final ServiceSlot? chosen = controller.selectedSlot(itemId);

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('select_date'.tr, style: robotoMedium),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        SizedBox(
          height: 68,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.dayRange,
            itemBuilder: (context, index) {
              final DateTime day = _dateAt(index);
              final bool isSelected = _sameDay(day, selected);
              return InkWell(
                onTap: () => controller.selectDate(itemId, day),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_weekdays[day.weekday - 1], style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: isSelected ? Colors.white : Theme.of(context).disabledColor,
                    )),
                    Text('${day.day}', style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color,
                    )),
                    Text(_months[day.month - 1], style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: isSelected ? Colors.white : Theme.of(context).disabledColor,
                    )),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        if(showStore && showHome) ...[
          Text('service_location'.tr, style: robotoMedium),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [
            _locationChip(context, controller, itemId, 'store', 'at_store'.tr),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _locationChip(context, controller, itemId, 'home', 'at_home'.tr),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],

        Text('select_time_slot'.tr, style: robotoMedium),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        if(controller.isLoadingSlots(itemId))
          const Center(child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: CircularProgressIndicator(),
          ))
        else if(slots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
            child: Text('no_slots_available_on_this_date'.tr, style: robotoRegular.copyWith(
              color: Theme.of(context).disabledColor,
            )),
          )
        else
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: slots.map((slot) {
              final bool isSelected = chosen != null && chosen.start == slot.start;
              return InkWell(
                onTap: () => controller.selectSlot(itemId, slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(slot.displayLabel, style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color,
                  )),
                ),
              );
            }).toList(),
          ),
      ]);
    });
  }

  Widget _locationChip(BuildContext context, ServiceBookingController controller, int itemId, String type, String label) {
    final bool isSelected = controller.locationType(itemId) == type;
    return InkWell(
      onTap: () => controller.setLocationType(itemId, type),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color,
        )),
      ),
    );
  }

  DateTime _dateAt(int offset) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: offset));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

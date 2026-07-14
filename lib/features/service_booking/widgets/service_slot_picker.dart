import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/service_booking/controllers/service_booking_controller.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_slot_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Date picker + location toggle + time selection for a single service item.
///
/// Time can be chosen two ways: the slot chips the backend offers, or — within the
/// provider's opening hours for the chosen day — any time the customer names. The
/// two are mutually exclusive; picking either clears the other.
///
/// [store] supplies the opening hours and is optional: without it the hours line
/// and the manual field are hidden and this degrades to the original chips-only picker.
class ServiceSlotPicker extends StatefulWidget {
  final Item item;
  final Store? store;
  final int dayRange;
  const ServiceSlotPicker({super.key, required this.item, this.store, this.dayRange = 14});

  @override
  State<ServiceSlotPicker> createState() => _ServiceSlotPickerState();
}

class _ServiceSlotPickerState extends State<ServiceSlotPicker> {
  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final TextEditingController _timeController = TextEditingController();

  /// Inline error under the time field; null when the field is empty or valid.
  String? _timeError;

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
  void dispose() {
    _timeController.dispose();
    super.dispose();
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
      final List<Schedules> hours = _schedulesFor(selected);

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
                onTap: () {
                  _clearTimeField();
                  controller.selectDate(itemId, day);
                },
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

        if(widget.store != null) ...[
          _storeHoursLine(context, hours),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        if(controller.isLoadingSlots(itemId))
          const Center(child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: CircularProgressIndicator(),
          ))
        else if(slots.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Text('no_slots_available_on_this_date'.tr, style: robotoRegular.copyWith(
              color: Theme.of(context).disabledColor,
            )),
          )
        else
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: slots.map((slot) {
              final bool isSelected = !controller.isManualTime(itemId) && chosen != null && chosen.start == slot.start;
              return InkWell(
                onTap: () {
                  _timeController.text = ServiceSlot(start: slot.start).displayLabel;
                  setState(() => _timeError = null);
                  controller.selectSlot(itemId, slot);
                },
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

        if(widget.store != null && hours.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _manualTimeField(context, controller, itemId),
        ],
      ]);
    });
  }

  /// "Store open 10:00 AM - 10:00 PM  ·  You can select any time in between."
  /// A day can carry several shifts, so every range for that day is listed.
  Widget _storeHoursLine(BuildContext context, List<Schedules> hours) {
    if(hours.isEmpty) {
      return Text('closed_on_this_day'.tr, style: robotoRegular.copyWith(
        fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error,
      ));
    }

    final String ranges = hours.map((s) =>
      '${DateConverter.serviceTimeToReadable(s.openingTime)} - ${DateConverter.serviceTimeToReadable(s.closingTime)}',
    ).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.access_time, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(child: Text(
            '${'store_hours'.tr}: $ranges',
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
            textDirection: TextDirection.ltr,
          )),
        ]),
        const SizedBox(height: 2),

        Text('you_can_select_any_time_in_between'.tr, style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor,
        )),
      ]),
    );
  }

  Widget _manualTimeField(BuildContext context, ServiceBookingController controller, int itemId) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('or_enter_your_own_time'.tr, style: robotoMedium),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      TextField(
        controller: _timeController,
        keyboardType: TextInputType.datetime,
        style: robotoRegular,
        onChanged: (String value) => _applyTypedTime(controller, itemId, value),
        decoration: InputDecoration(
          hintText: 'enter_time'.tr,
          hintStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
          errorText: _timeError,
          suffixIcon: IconButton(
            icon: Icon(Icons.access_time, color: Theme.of(context).primaryColor),
            tooltip: 'enter_time'.tr,
            onPressed: () => _pickTimeFromClock(context, controller, itemId),
          ),
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
      ),
    ]);
  }

  Future<void> _pickTimeFromClock(BuildContext context, ServiceBookingController controller, int itemId) async {
    final List<Schedules> hours = _schedulesFor(controller.selectedDate(itemId));
    final TimeOfDay initial = DateConverter.parseFlexibleTime(_timeController.text)
        ?? _openingTimeOf(hours.isNotEmpty ? hours.first : null)
        ?? TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initial);
    if(picked == null) return;

    _timeController.text = _format(picked);
    _applyTypedTime(controller, itemId, _timeController.text);
  }

  /// Validates the text and either records the time or surfaces why it was refused.
  /// An invalid entry leaves no slot selected, so the sheet's Confirm stays disabled.
  void _applyTypedTime(ServiceBookingController controller, int itemId, String value) {
    if(value.trim().isEmpty) {
      setState(() => _timeError = null);
      return;
    }

    final TimeOfDay? time = DateConverter.parseFlexibleTime(value);
    if(time == null) {
      setState(() => _timeError = 'invalid_time_format'.tr);
      return;
    }

    final DateTime date = controller.selectedDate(itemId);
    final List<Schedules> hours = _schedulesFor(date);
    final bool withinHours = hours.any((s) => DateConverter.isTimeWithinOpeningHours(time, s.openingTime, s.closingTime));
    if(!withinHours) {
      setState(() => _timeError = 'please_select_a_time_within_store_hours'.tr);
      return;
    }

    if(_sameDay(date, DateTime.now()) && _isPast(time)) {
      setState(() => _timeError = 'please_select_a_future_time'.tr);
      return;
    }

    setState(() => _timeError = null);
    controller.selectManualTime(itemId, time.hour, time.minute);
  }

  void _clearTimeField() {
    _timeController.clear();
    setState(() => _timeError = null);
  }

  /// The store's schedule rows for the weekday of [date]. Mirrors the 0=Sun..6=Sat
  /// convention used by `StoreController.isStoreClosed`.
  List<Schedules> _schedulesFor(DateTime date) {
    final int weekday = date.weekday == 7 ? 0 : date.weekday;
    return widget.store?.schedules?.where((Schedules s) => s.day == weekday).toList() ?? [];
  }

  TimeOfDay? _openingTimeOf(Schedules? schedule) =>
      schedule == null ? null : DateConverter.parseFlexibleTime(schedule.openingTime);

  bool _isPast(TimeOfDay time) {
    final DateTime now = DateTime.now();
    return ((time.hour * 60) + time.minute) <= ((now.hour * 60) + now.minute);
  }

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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

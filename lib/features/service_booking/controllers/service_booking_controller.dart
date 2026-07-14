import 'package:get/get.dart';
import 'package:sixam_mart/common/models/error_response.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/service_booking/domain/models/appointment_model.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_booking_model.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_slot_model.dart';
import 'package:sixam_mart/features/service_booking/domain/services/service_booking_service_interface.dart';
import 'package:sixam_mart/helper/date_converter.dart';

class ServiceBookingController extends GetxController implements GetxService {
  final ServiceBookingServiceInterface serviceBookingServiceInterface;
  ServiceBookingController({required this.serviceBookingServiceInterface});

  // ----- per-item booking selection state (keyed by item_id) -----
  final Map<int, DateTime> _selectedDate = {};
  final Map<int, AvailableSlotsModel?> _slots = {};
  final Map<int, ServiceSlot?> _selectedSlot = {};
  final Map<int, String> _locationType = {};
  final Set<int> _loadingItems = {};

  /// Items whose selected slot was named by the customer rather than offered by
  /// the server. Such a slot is absent from `slotsFor`, so it must be exempt from
  /// the "drop what the server no longer offers" sweep in [getAvailableSlots].
  final Set<int> _manualTimeItems = {};

  DateTime selectedDate(int itemId) => _selectedDate[itemId] ?? DateTime.now();
  List<ServiceSlot> slotsFor(int itemId) => _slots[itemId]?.slots ?? [];
  ServiceSlot? selectedSlot(int itemId) => _selectedSlot[itemId];
  String? locationType(int itemId) => _locationType[itemId];
  bool isLoadingSlots(int itemId) => _loadingItems.contains(itemId);
  bool isManualTime(int itemId) => _manualTimeItems.contains(itemId);

  /// Length of a booking in minutes, as reported with the day's slots. Null until
  /// the slots have loaded, or if the server omits it.
  int? slotDurationFor(int itemId) => _slots[itemId]?.duration;

  /// Seed defaults for an item and load its slots for today.
  /// `atStore`/`homeService` come from the Item; default location honours them.
  Future<void> initItem({required int itemId, required bool atStore, required bool homeService, DateTime? date}) async {
    _selectedDate[itemId] = date ?? _stripTime(DateTime.now());
    _locationType.putIfAbsent(itemId, () => atStore ? 'store' : (homeService ? 'home' : 'store'));
    await getAvailableSlots(itemId);
  }

  Future<void> selectDate(int itemId, DateTime date) async {
    _selectedDate[itemId] = _stripTime(date);
    _selectedSlot[itemId] = null; // a new date invalidates the old slot
    _manualTimeItems.remove(itemId);
    await getAvailableSlots(itemId);
  }

  Future<void> getAvailableSlots(int itemId) async {
    _loadingItems.add(itemId);
    update();
    final String date = DateConverter.dateToDate(selectedDate(itemId));
    final AvailableSlotsModel? result = await serviceBookingServiceInterface.getAvailableSlots(itemId: itemId, date: date);
    _slots[itemId] = result;
    // Drop a previously chosen slot if it is no longer offered. A time the customer
    // named themselves is never in this list, so it is left alone.
    final ServiceSlot? chosen = _selectedSlot[itemId];
    if (chosen != null && !isManualTime(itemId) && !(result?.slots?.any((s) => s.start == chosen.start) ?? false)) {
      _selectedSlot[itemId] = null;
    }
    _loadingItems.remove(itemId);
    update();
  }

  void selectSlot(int itemId, ServiceSlot slot) {
    _selectedSlot[itemId] = slot;
    _manualTimeItems.remove(itemId);
    update();
  }

  /// A time the customer typed or picked from the clock, rather than a server slot.
  /// The caller is responsible for having validated it against the store's hours.
  void selectManualTime(int itemId, int hour, int minute) {
    _selectedSlot[itemId] = ServiceSlot.manual(
      hour: hour, minute: minute, durationMinutes: slotDurationFor(itemId),
    );
    _manualTimeItems.add(itemId);
    update();
  }

  void setLocationType(int itemId, String type) {
    _locationType[itemId] = type;
    update();
  }

  /// Called when the order endpoint returns `service_slot` for an item:
  /// the slot was taken/expired between selection and submit. Re-fetch and
  /// drop the stale choice so the user must re-pick.
  Future<void> onSlotConflict(int itemId) async {
    _selectedSlot[itemId] = null;
    _manualTimeItems.remove(itemId);
    await getAvailableSlots(itemId);
    showCustomSnackBar('selected_slot_no_longer_available'.tr);
  }

  /// The order endpoint returned `location_type`: hide the unsupported option
  /// by forcing the other one (best-effort; the picker also gates on the item).
  void onLocationTypeRejected(int itemId) {
    if (_locationType[itemId] == 'home') {
      _locationType[itemId] = 'store';
    } else {
      _locationType[itemId] = 'home';
    }
    update();
  }

  ServiceBooking? bookingFor(int itemId) {
    final ServiceSlot? slot = _selectedSlot[itemId];
    if (slot == null) return null;
    return ServiceBooking(
      itemId: itemId,
      serviceDate: DateConverter.dateToDate(selectedDate(itemId)),
      startTime: slot.startTimeForPayload,
      locationType: _locationType[itemId] ?? 'store',
    );
  }

  /// Build the `service_bookings` payload for the given service item ids.
  List<ServiceBooking> buildServiceBookings(List<int> itemIds) {
    final List<ServiceBooking> bookings = [];
    for (final int id in itemIds) {
      final ServiceBooking? b = bookingFor(id);
      if (b != null) bookings.add(b);
    }
    return bookings;
  }

  /// True only when every service item has a complete {date, slot, location}.
  bool isSelectionComplete(List<int> itemIds) {
    if (itemIds.isEmpty) return false;
    for (final int id in itemIds) {
      final ServiceBooking? b = bookingFor(id);
      if (b == null || !b.isComplete) return false;
    }
    return true;
  }

  /// Whether `home` location currently requires a saved address id.
  bool requiresCustomerAddress(List<int> itemIds) =>
      itemIds.any((id) => _locationType[id] == 'home');

  void clearSelections() {
    _selectedDate.clear();
    _slots.clear();
    _selectedSlot.clear();
    _locationType.clear();
    _loadingItems.clear();
    _manualTimeItems.clear();
  }

  // ----- My Appointments -----
  List<Appointment>? _appointments;
  List<Appointment>? get appointments => _appointments;
  bool _appointmentsLoading = false;
  bool get appointmentsLoading => _appointmentsLoading;
  int? _appointmentTotalSize;
  int? get appointmentTotalSize => _appointmentTotalSize;
  final Set<int> _cancellingIds = {};
  bool isCancelling(int id) => _cancellingIds.contains(id);

  Future<void> getMyAppointments({int offset = 1, bool reload = true}) async {
    if (reload) {
      _appointments = null;
      _appointmentsLoading = true;
      update();
    }
    final AppointmentListModel? result = await serviceBookingServiceInterface.getMyAppointments(offset: offset);
    if (result != null) {
      if (offset == 1 || _appointments == null) {
        _appointments = [];
      }
      _appointments!.addAll(result.appointments ?? []);
      _appointmentTotalSize = result.totalSize;
    }
    _appointmentsLoading = false;
    update();
  }

  Future<bool> cancelAppointment(int id) async {
    _cancellingIds.add(id);
    update();
    final Response response = await serviceBookingServiceInterface.cancelAppointment(id);
    bool success = false;
    if (response.statusCode == 200) {
      success = true;
      _appointments?.removeWhere((a) => a.id == id);
      showCustomSnackBar('appointment_cancelled'.tr, isError: false);
    } else {
      showCustomSnackBar(_extractErrorMessage(response) ?? 'appointment_cancel_failed'.tr);
    }
    _cancellingIds.remove(id);
    update();
    return success;
  }

  String? _extractErrorMessage(Response response) {
    try {
      if (response.body != null && response.body.toString().contains('errors')) {
        final ErrorResponse errorResponse = ErrorResponse.fromJson(response.body);
        if (errorResponse.errors != null && errorResponse.errors!.isNotEmpty) {
          return errorResponse.errors![0].message;
        }
      }
    } catch (_) {}
    return response.statusText;
  }

  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);
}

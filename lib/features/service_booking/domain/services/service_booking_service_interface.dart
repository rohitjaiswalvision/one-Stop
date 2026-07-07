import 'package:get/get.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_slot_model.dart';
import 'package:sixam_mart/features/service_booking/domain/models/appointment_model.dart';

abstract class ServiceBookingServiceInterface {
  Future<AvailableSlotsModel?> getAvailableSlots({required int itemId, required String date});
  Future<List<dynamic>?> getStaff({int? itemId, int? storeId});
  Future<AppointmentListModel?> getMyAppointments({int limit = 25, int offset = 1});
  Future<Response> cancelAppointment(int id);
}

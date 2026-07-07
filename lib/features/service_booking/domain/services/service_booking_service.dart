import 'package:get/get.dart';
import 'package:sixam_mart/features/service_booking/domain/models/appointment_model.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_slot_model.dart';
import 'package:sixam_mart/features/service_booking/domain/repositories/service_booking_repository_interface.dart';
import 'package:sixam_mart/features/service_booking/domain/services/service_booking_service_interface.dart';

class ServiceBookingService implements ServiceBookingServiceInterface {
  final ServiceBookingRepositoryInterface serviceBookingRepositoryInterface;
  ServiceBookingService({required this.serviceBookingRepositoryInterface});

  @override
  Future<AvailableSlotsModel?> getAvailableSlots({required int itemId, required String date}) {
    return serviceBookingRepositoryInterface.getAvailableSlots(itemId: itemId, date: date);
  }

  @override
  Future<List<dynamic>?> getStaff({int? itemId, int? storeId}) {
    return serviceBookingRepositoryInterface.getStaff(itemId: itemId, storeId: storeId);
  }

  @override
  Future<AppointmentListModel?> getMyAppointments({int limit = 25, int offset = 1}) {
    return serviceBookingRepositoryInterface.getMyAppointments(limit: limit, offset: offset);
  }

  @override
  Future<Response> cancelAppointment(int id) {
    return serviceBookingRepositoryInterface.cancelAppointment(id);
  }
}

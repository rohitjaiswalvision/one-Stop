import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/service_booking/domain/models/appointment_model.dart';
import 'package:sixam_mart/features/service_booking/domain/models/service_slot_model.dart';
import 'package:sixam_mart/features/service_booking/domain/repositories/service_booking_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ServiceBookingRepository implements ServiceBookingRepositoryInterface {
  final ApiClient apiClient;
  ServiceBookingRepository({required this.apiClient});

  @override
  Future<AvailableSlotsModel?> getAvailableSlots({required int itemId, required String date}) async {
    AvailableSlotsModel? slotsModel;
    Response response = await apiClient.getData(
      '${AppConstants.serviceAvailableSlotsUri}?item_id=$itemId&date=$date',
    );
    if (response.statusCode == 200 && response.body != null) {
      slotsModel = AvailableSlotsModel.fromJson(response.body);
    }
    return slotsModel;
  }

  @override
  Future<List<dynamic>?> getStaff({int? itemId, int? storeId}) async {
    final String query = itemId != null ? 'item_id=$itemId' : 'store_id=$storeId';
    Response response = await apiClient.getData('${AppConstants.serviceStaffUri}?$query');
    if (response.statusCode == 200 && response.body is List) {
      return response.body;
    }
    return null;
  }

  @override
  Future<AppointmentListModel?> getMyAppointments({int limit = 25, int offset = 1}) async {
    AppointmentListModel? listModel;
    Response response = await apiClient.getData(
      '${AppConstants.serviceMyAppointmentsUri}?limit=$limit&offset=$offset',
    );
    if (response.statusCode == 200 && response.body != null) {
      // Endpoint may return a bare list or a paginated object.
      if (response.body is List) {
        listModel = AppointmentListModel(
          appointments: (response.body as List).map((v) => Appointment.fromJson(v)).toList(),
          totalSize: (response.body as List).length,
          offset: offset,
        );
      } else {
        listModel = AppointmentListModel.fromJson(response.body);
      }
    }
    return listModel;
  }

  @override
  Future<Response> cancelAppointment(int id) async {
    // handleError:false so we can read the 403 `status` error code ourselves.
    return await apiClient.putData(
      '${AppConstants.serviceAppointmentsUri}/$id/cancel', {}, handleError: false,
    );
  }
}

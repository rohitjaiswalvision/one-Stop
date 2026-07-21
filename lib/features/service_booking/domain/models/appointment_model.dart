/// Paginated response of GET /services/my-appointments?limit=&offset=
class AppointmentListModel {
  int? totalSize;
  String? limit;
  int? offset;
  List<Appointment>? appointments;

  AppointmentListModel({this.totalSize, this.limit, this.offset, this.appointments});

  AppointmentListModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'] != null ? int.tryParse(json['total_size'].toString()) : null;
    limit = json['limit']?.toString();
    offset = json['offset'] != null ? int.tryParse(json['offset'].toString()) : null;
    // Backend may key the list as `appointments`, `bookings`, or `data`.
    final dynamic list = json['appointments'] ?? json['bookings'] ?? json['data'];
    if (list != null) {
      appointments = [];
      list.forEach((v) => appointments!.add(Appointment.fromJson(v)));
    }
  }
}

class Appointment {
  int? id;
  String? status; // pending / accepted / ...
  String? serviceDate;
  String? startTime;
  String? endTime;
  String? locationType;
  AppointmentItem? item;
  AppointmentStaff? staff; // null until the provider assigns someone
  AppointmentStore? store;
  AppointmentOrder? order;

  Appointment({
    this.id, this.status, this.serviceDate, this.startTime, this.endTime,
    this.locationType, this.item, this.staff, this.store, this.order,
  });

  Appointment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    serviceDate = json['service_date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    locationType = json['location_type'];
    item = json['item'] != null ? AppointmentItem.fromJson(json['item']) : null;
    staff = json['staff'] != null ? AppointmentStaff.fromJson(json['staff']) : null;
    store = json['store'] != null ? AppointmentStore.fromJson(json['store']) : null;
    order = json['order'] != null ? AppointmentOrder.fromJson(json['order']) : null;
  }

  /// Cancellation is only permitted while pending or accepted (backend rule).
  bool get isCancellable => status == 'pending' || status == 'accepted';

  /// Pay-after-service gate: once the provider finishes the job the customer settles
  /// online. "Finished" is read from the booking's own status first ([status] is the
  /// service_bookings value the vendor updates), because orders.order_status can lag
  /// behind the vendor's completion. Settling keeps the order completed, only flipping
  /// payment_status to paid.
  bool get isPayable =>
      order?.id != null &&
      order?.paymentStatus == 'unpaid' &&
      (status == 'completed' ||
          order?.orderStatus == 'delivered' ||
          order?.orderStatus == 'completed');
}

class AppointmentItem {
  int? id;
  String? name;
  String? image;

  AppointmentItem({this.id, this.name, this.image});

  AppointmentItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image_full_url'] ?? json['image'];
  }
}

class AppointmentStaff {
  int? id;
  String? name;

  AppointmentStaff({this.id, this.name});

  AppointmentStaff.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'] ?? '${json['f_name'] ?? ''} ${json['l_name'] ?? ''}'.trim();
  }
}

class AppointmentStore {
  int? id;
  String? name;

  AppointmentStore({this.id, this.name});

  AppointmentStore.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }
}

class AppointmentOrder {
  int? id;
  String? paymentStatus;
  String? orderStatus;

  AppointmentOrder({this.id, this.paymentStatus, this.orderStatus});

  AppointmentOrder.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    paymentStatus = json['payment_status'];
    orderStatus = json['order_status'];
  }
}

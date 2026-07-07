/// One entry of the `service_bookings` array sent to POST /customer/order/place.
/// There is one entry per service item in the cart.
class ServiceBooking {
  int? itemId;
  String? serviceDate; // YYYY-MM-DD
  String? startTime;   // HH:mm (must be a `start` returned by available-slots)
  String? locationType; // "store" | "home"

  ServiceBooking({this.itemId, this.serviceDate, this.startTime, this.locationType});

  ServiceBooking.fromJson(Map<String, dynamic> json) {
    itemId = json['item_id'];
    serviceDate = json['service_date'];
    startTime = json['start_time'];
    locationType = json['location_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['item_id'] = itemId;
    data['service_date'] = serviceDate;
    data['start_time'] = startTime;
    data['location_type'] = locationType;
    return data;
  }

  bool get isComplete =>
      itemId != null &&
      serviceDate != null && serviceDate!.isNotEmpty &&
      startTime != null && startTime!.isNotEmpty &&
      locationType != null && locationType!.isNotEmpty;
}

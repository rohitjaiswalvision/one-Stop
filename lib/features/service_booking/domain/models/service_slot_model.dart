/// Response of GET /services/available-slots?item_id=&date=
/// The `slots` list is already filtered server-side by staff capacity and time,
/// so it is the single source of truth for what the customer may pick.
class AvailableSlotsModel {
  int? itemId;
  String? date;
  int? duration;
  List<ServiceSlot>? slots;

  AvailableSlotsModel({this.itemId, this.date, this.duration, this.slots});

  AvailableSlotsModel.fromJson(Map<String, dynamic> json) {
    itemId = json['item_id'];
    date = json['date'];
    duration = json['duration'];
    if (json['slots'] != null) {
      slots = [];
      json['slots'].forEach((v) => slots!.add(ServiceSlot.fromJson(v)));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['item_id'] = itemId;
    data['date'] = date;
    data['duration'] = duration;
    if (slots != null) {
      data['slots'] = slots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServiceSlot {
  /// Raw server values, e.g. "07:00:00" / "08:00:00".
  String? start;
  String? end;

  ServiceSlot({this.start, this.end});

  ServiceSlot.fromJson(Map<String, dynamic> json) {
    start = json['start'];
    end = json['end'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['start'] = start;
    data['end'] = end;
    return data;
  }

  /// The value that must be sent back as `start_time` (HH:mm), derived from the
  /// server `start`. Sending anything not returned by the endpoint is rejected.
  String get startTimeForPayload {
    if (start == null) return '';
    final List<String> parts = start!.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    return start!;
  }

  /// "07:00 - 08:00" style label for the slot grid.
  String get displayLabel => '${_hhmm(start)} - ${_hhmm(end)}';

  static String _hhmm(String? raw) {
    if (raw == null) return '';
    final List<String> parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    return raw;
  }
}

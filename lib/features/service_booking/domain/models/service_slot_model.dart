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

  /// A time the customer typed or picked themselves rather than one the server
  /// offered. [durationMinutes] comes from `AvailableSlotsModel.duration`; when it
  /// is unknown the slot carries no end and renders as a bare start time.
  factory ServiceSlot.manual({required int hour, required int minute, int? durationMinutes}) {
    final int startMinutes = (hour * 60) + minute;
    String? end;
    if (durationMinutes != null && durationMinutes > 0) {
      final int endMinutes = (startMinutes + durationMinutes) % (24 * 60);
      end = _fromMinutes(endMinutes);
    }
    return ServiceSlot(start: _fromMinutes(startMinutes), end: end);
  }

  static String _fromMinutes(int minutes) {
    final String hh = (minutes ~/ 60).toString().padLeft(2, '0');
    final String mm = (minutes % 60).toString().padLeft(2, '0');
    return '$hh:$mm:00';
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

  /// "07:00 - 08:00" for a server slot; a bare "10:30" when the customer named a
  /// time and the service duration is unknown, so there is no end to show.
  String get displayLabel {
    final String from = _hhmm(start);
    final String to = _hhmm(end);
    return to.isEmpty ? from : '$from - $to';
  }

  static String _hhmm(String? raw) {
    if (raw == null) return '';
    final List<String> parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    return raw;
  }
}

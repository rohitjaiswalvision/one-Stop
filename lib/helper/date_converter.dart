import 'package:flutter/material.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DateConverter {

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd hh:mm:ss a').format(dateTime);
  }

  static String dateToTimeOnly(DateTime dateTime) {
    return DateFormat(_timeFormatter()).format(dateTime);
  }

  static String dateToDateAndTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String dateToDateAndTimeAm(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd ${_timeFormatter()}').format(dateTime);
  }

  static String dateToDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String dateToTime24(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String dateToReadableDate(DateTime dateTime) {
    return DateFormat('dd MMM, yyy').format(dateTime);
  }

  static String dateTimeStringToDateTime(String dateTime) {
    DateTime d;
    try{
      d = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
    } catch(_) {
     d = isoStringToLocalDate(dateTime);
    }
    return DateFormat('dd MMM yyyy,  ${_timeFormatter()}').format(d);
  }

  static String taxiDateTimeToString(DateTime dateTime) {
    return DateFormat('dd MMM yyyy,  ${_timeFormatter()}').format(dateTime);
  }

  static String dateTimeStringToUTCTime(String dateTime) {
    return DateFormat('dd MMM yyyy  ${_timeFormatter()}').format(DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(dateTime));
  }

  static String dateTimeStringToDateOnly(String dateTime) {
    return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime));
  }

  static DateTime dateTimeStringToDate(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
  }

  static DateTime isoStringToLocalDate(String dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(dateTime);
  }

  static String isoStringToLocalString(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(dateTime).toLocal());
  }

  static String isoStringToReadableString(String dateTime) {
    return DateFormat('dd MMMM, yyyy HH:mm a').format(DateTime.parse(dateTime).toLocal());
  }

  static String stringToReadableString(String dateTime) {
    return DateFormat('dd MMMM, yyyy').format(DateTime.parse(dateTime).toLocal());
  }

  static String isoStringToDateTimeString(String dateTime) {
    return DateFormat('dd MMM yyyy  ${_timeFormatter()}').format(isoStringToLocalDate(dateTime));
  }

  static String isoStringToLocalDateOnly(String dateTime) {
    return DateFormat('dd MMM yyyy').format(isoStringToLocalDate(dateTime));
  }

  static String stringToLocalDateOnly(String dateTime) {
    return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd').parse(dateTime));
  }

  static String localDateToIsoString(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime);
  }

  static String convertTimeToTime(String time) {
    return DateFormat(_timeFormatter()).format(DateFormat('HH:mm').parse(time));
  }

  static DateTime convertStringTimeToDate(String time) {
    return DateFormat('HH:mm').parse(time);
  }

  static String convertTimeToTimeDate(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static bool isAvailable(String? start, String? end, {DateTime? time}) {
    // Server APP_TIMEZONE=Asia/Kolkata, so schedule times are already in IST.
    // currentTime (DateTime.now()) is also IST on Indian devices — direct comparison is correct.
    DateTime currentTime;
    if(time != null) {
      currentTime = time;
    }else {
      currentTime = Get.find<SplashController>().currentTime;
    }
    DateTime start0 = start != null ? DateFormat('HH:mm').parse(start) : DateTime(currentTime.year);
    DateTime end0 = end != null ? DateFormat('HH:mm').parse(end) : DateTime(currentTime.year, currentTime.month, currentTime.day, 23, 59, 59);
    DateTime startTime = DateTime(currentTime.year, currentTime.month, currentTime.day, start0.hour, start0.minute, start0.second);
    DateTime endTime = DateTime(currentTime.year, currentTime.month, currentTime.day, end0.hour, end0.minute, end0.second);
    if(endTime.isBefore(startTime)) {
      if(currentTime.isBefore(startTime) && currentTime.isBefore(endTime)){
        startTime = startTime.add(const Duration(days: -1));
      }else {
        endTime = endTime.add(const Duration(days: 1));
      }
    }
    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  static String _timeFormatter() {
    return Get.find<SplashController>().configModel!.timeformat == '24' ? 'HH:mm' : 'hh:mm a';
  }

  static String convertFromMinute(int minMinute, int maxMinute) {
    int firstValue = minMinute;
    int secondValue = maxMinute;
    String type = 'min';
    if(minMinute >= 525600) {
      firstValue = (minMinute / 525600).floor();
      secondValue = (maxMinute / 525600).floor();
      type = 'year';
    }else if(minMinute >= 43200) {
      firstValue = (minMinute / 43200).floor();
      secondValue = (maxMinute / 43200).floor();
      type = 'month';
    }else if(minMinute >= 10080) {
      firstValue = (minMinute / 10080).floor();
      secondValue = (maxMinute / 10080).floor();
      type = 'week';
    }else if(minMinute >= 1440) {
      firstValue = (minMinute / 1440).floor();
      secondValue = (maxMinute / 1440).floor();
      type = 'day';
    }else if(minMinute >= 60) {
      firstValue = (minMinute / 60).floor();
      secondValue = (maxMinute / 60).floor();
      type = 'hour';
    }
    return '$firstValue-$secondValue ${type.tr}';
  }

  static String localDateToIsoStringAMPM(DateTime dateTime) {
    return DateFormat('${_timeFormatter()} | d-MMM-yyyy ').format(dateTime.toLocal());
  }

  static bool isBeforeTime(String? dateTime) {
    if(dateTime == null) {
      return false;
    }
    DateTime scheduleTime = dateTimeStringToDate(dateTime);
    return scheduleTime.isBefore(DateTime.now());
  }

  static int differenceInMinute(String? deliveryTime, String? orderTime, int? processingTime, String? scheduleAt) {
    // 'min', 'hours', 'days'
    int minTime = processingTime ?? 0;
    if(deliveryTime != null && deliveryTime.isNotEmpty && processingTime == null) {
      try {
        List<String> timeList = deliveryTime.split('-'); // ['15', '20']
        minTime = int.parse(timeList[0]);
      }catch(_) {}
    }
    DateTime deliveryTime0 = dateTimeStringToDate(scheduleAt ?? orderTime!).add(Duration(minutes: minTime));
    return deliveryTime0.difference(DateTime.now()).inMinutes;
  }

  static String containTAndZToUTCFormat(String time) {
    var newTime = '${time.substring(0,10)} ${time.substring(11,23)}';
    return DateFormat('dd MMM, yyyy').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(newTime));
  }

  static String convertTodayYesterdayFormat(String createdAt) {
    final now = DateTime.now();
    final createdAtDate = DateTime.parse(createdAt).toLocal();

    if (createdAtDate.year == now.year && createdAtDate.month == now.month && createdAtDate.day == now.day) {
      return 'Today, ${DateFormat.jm().format(createdAtDate)}';
    } else if (createdAtDate.year == now.year && createdAtDate.month == now.month && createdAtDate.day == now.day - 1) {
      return 'Yesterday, ${DateFormat.jm().format(createdAtDate)}';
    } else {
      return DateConverter.localDateToIsoStringAMPM(createdAtDate);
    }
  }

  static String convertOnlyTodayTime(String createdAt) {
    final now = DateTime.now();
    final createdAtDate = DateTime.parse(createdAt).toLocal();

    if (createdAtDate.year == now.year &&
        createdAtDate.month == now.month &&
        createdAtDate.day == now.day) {
      return DateFormat('h:mm a').format(createdAtDate);
    } else {
      return DateConverter.localDateToIsoStringAMPM(createdAtDate);
    }
  }

  static String convertRestaurantOpenTime(String time) {
    return DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(time).toLocal());
  }

  static String dateTimeStringToFormattedTime(String dateTime) {
    return DateFormat(_timeFormatter()).format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime));
  }

  static DateTime formattingTripDateTime(DateTime pickedTime, DateTime pickedDate) {
    return DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
  }

  static bool isSameDate(DateTime pickedTime) {
    return pickedTime.year == DateTime.now().year && pickedTime.month == DateTime.now().month && pickedTime.day == DateTime.now().day && pickedTime.hour == DateTime.now().hour && pickedTime.minute == DateTime.now().minute;
  }

  static bool isAfterCurrentDateTime(DateTime pickedTime) {
    DateTime pick = DateTime(pickedTime.year, pickedTime.month, pickedTime.day, pickedTime.hour, pickedTime.minute);
    DateTime current = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute);
    return pick.isAfter(current);
  }

  static int durationFromNow(String time) {
    DateTime parsedTime = DateTime.parse(time);
    return parsedTime.difference(DateTime.now()).inMinutes;
  }

  static String dateToDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  static String convertTodayYesterdayDate(String createdAt) {
    final DateTime createdDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdAt);
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd MMM yyyy');

    if (createdDate.year == now.year && createdDate.month == now.month && createdDate.day == now.day) {
      return 'Today';
    }

    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (createdDate.year == yesterday.year && createdDate.month == yesterday.month && createdDate.day == yesterday.day) {
      return 'Yesterday';
    }

    return formatter.format(createdDate);
  }

  static String stringDateTimeToDate(String dateTime) {
    return DateFormat('dd MMM, yyyy').format(DateFormat('yyyy-MM-dd').parse(dateTime));
  }

  static DateTime dateFormatToShow(String? date){
    return DateTime.now();
    // return DateFormat('yyyy-MM-dd').parse(
    //   date ?? DateTime.now().add(Duration(seconds: Get.find<ConfigController>().config?.minimumScheduleBookTime ?? 0)).toString(),
    // );
  }

  static DateTime timeFormatToShow(DateTime? time){
    return DateTime.now();
    // return time ?? DateTime.now().add(Duration(seconds: Get.find<ConfigController>().config?.minimumScheduleBookTime  ?? 0));
  }

  static String stringDateTimeToTimeOnly(String dateTime) {
    return DateFormat(_timeFormatter()).format(DateFormat('yyyy-MM-dd HH:mm').parse(dateTime));
  }

  static String formatUtcTime(String utcString) {
    DateTime dateTime = DateTime.parse(utcString).toLocal();

    final formatter = DateFormat('dd MMM yyyy');
    return formatter.format(dateTime);
  }

  static String convertDateTimeToTime(DateTime time) {
    return DateFormat(_timeFormatter()).format(time);
  }
  static String dateMonthYearTimeTwentyFourFormat(DateTime dateTime) {
    return _localDateFormatter('d MMM, y ${_timeFormatter()}').format(dateTime);
  }

  static DateTime isoUtcStringToLocalDate(String dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(dateTime, true).toLocal();
  }

  static DateFormat _localDateFormatter(String format){
    return DateFormat(format);
  }

  static String convertDateTimeRangeToString(DateTimeRange dateRange, {String format = 'dd / MM / yy'}) {
    final startDate = DateFormat(format).format(dateRange.start);
    final endDate = DateFormat(format).format(dateRange.end);
    if (startDate == endDate) {
      return startDate;
    }
    return '$startDate   -   $endDate';
  }

  static String dateStringMonthYear(DateTime ? dateTime) {
    return DateFormat('d MMM, y').format(dateTime!);
  }

  static String dateMonthYearTime(DateTime ? dateTime) {
    return _localDateFormatter('d MMM, y, ${_timeFormatter()}').format(dateTime!);
  }

  static String convert24HourTimeTo12HourTime(DateTime time) {
    return _localDateFormatter(_timeFormatter()).format(time);
  }

  static String convertStringDateTimeToTime(String time) {
    return DateFormat(_timeFormatter()).format(DateFormat('HH:mm').parse(time));
  }

  static DateTimeRange? convertDateTimeListToDateTimeRange(List<DateTime> dateList) {
    if (dateList.isEmpty) {
      return null;
    }
    DateTime start = dateList.reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime end = dateList.reduce((a, b) => a.isAfter(b) ? a : b);

    return DateTimeRange(start: start, end: end);
  }
  static TimeOfDay convertDateTimeToTimeOfDay(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  static DateTime combineDateTimeAndTimeOfDay({required DateTime date, required TimeOfDay time}) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static String convertServiceStringTimeToDate(DateTime time) {
    return _localDateFormatter(_timeFormatter()).format(time);
  }

  static String convertStringTimeToTime(String time) {
    return DateFormat(_timeFormatter()).format(DateFormat('HH:mm').parse(time));
  }

  static DateTime convertTimeToDateTime(String time) {
    return DateFormat('HH:mm').parse(time);
  }

  /// `2026-07-08` -> `08 Jul 2026`. Returns the raw string if it is not a plain date.
  static String serviceDateToReadable(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd').parse(date));
    } catch (_) {
      return date;
    }
  }

  /// `12:00:00` (or `12:00`) -> `12:00 PM`, honouring the configured 12/24h format.
  static String serviceTimeToReadable(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final List<String> parts = time.split(':');
      return DateFormat(_timeFormatter()).format(DateFormat('HH:mm').parse('${parts[0]}:${parts[1]}'));
    } catch (_) {
      return time;
    }
  }

  /// Parses what a customer might type into a time field — `10:30`, `10:30 AM`,
  /// `10.30am`, `22:30`, `9pm`, `9 PM` — and returns null for anything else.
  static TimeOfDay? parseFlexibleTime(String? input) {
    if (input == null || input.trim().isEmpty) return null;

    final String text = input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final RegExpMatch? match = RegExp(r'^(\d{1,2})(?:[:.](\d{1,2}))?(AM|PM)?$').firstMatch(text);
    if (match == null) return null;

    int? hour = int.tryParse(match.group(1)!);
    final int minute = match.group(2) != null ? (int.tryParse(match.group(2)!) ?? -1) : 0;
    final String? meridiem = match.group(3);
    if (hour == null || minute < 0 || minute > 59) return null;

    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      if (meridiem == 'AM' && hour == 12) {
        hour = 0;
      } else if (meridiem == 'PM' && hour != 12) {
        hour += 12;
      }
    }
    if (hour < 0 || hour > 23) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Whether [time] falls inside a store's opening window. [opening]/[closing] are
  /// `HH:mm` (or `HH:mm:ss`) as carried on `Schedules`.
  ///
  /// Inclusive of both bounds — booking exactly at opening or closing is legitimate.
  /// (`isAvailable` above is deliberately exclusive, so it cannot be reused here.)
  /// A window whose close is before its open is treated as running past midnight.
  static bool isTimeWithinOpeningHours(TimeOfDay time, String? opening, String? closing) {
    final int? open = _minutesOfTime(opening);
    final int? close = _minutesOfTime(closing);
    if (open == null || close == null) return false;

    final int candidate = (time.hour * 60) + time.minute;
    if (open == close) return true;
    if (close > open) return candidate >= open && candidate <= close;
    return candidate >= open || candidate <= close;
  }

  static int? _minutesOfTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final List<String> parts = raw.split(':');
    if (parts.length < 2) return null;
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour * 60) + minute;
  }



}

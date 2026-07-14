import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/helper/date_converter.dart';

/// Covers the two pure helpers behind manual time entry in the service schedule
/// sheet: parsing what a customer types, and checking it against the provider's
/// opening hours. Neither touches GetX, so they are testable in isolation.
void main() {
  group('parseFlexibleTime', () {
    test('accepts the forms a customer plausibly types', () {
      expect(DateConverter.parseFlexibleTime('10:30'), const TimeOfDay(hour: 10, minute: 30));
      expect(DateConverter.parseFlexibleTime('10:30 AM'), const TimeOfDay(hour: 10, minute: 30));
      expect(DateConverter.parseFlexibleTime('10:30am'), const TimeOfDay(hour: 10, minute: 30));
      expect(DateConverter.parseFlexibleTime('10.30 pm'), const TimeOfDay(hour: 22, minute: 30));
      expect(DateConverter.parseFlexibleTime('22:30'), const TimeOfDay(hour: 22, minute: 30));
      expect(DateConverter.parseFlexibleTime('9pm'), const TimeOfDay(hour: 21, minute: 0));
      expect(DateConverter.parseFlexibleTime('9 PM'), const TimeOfDay(hour: 21, minute: 0));
      expect(DateConverter.parseFlexibleTime('  8:05  '), const TimeOfDay(hour: 8, minute: 5));
    });

    test('handles the 12-hour midnight/noon boundaries', () {
      expect(DateConverter.parseFlexibleTime('12:00 AM'), const TimeOfDay(hour: 0, minute: 0));
      expect(DateConverter.parseFlexibleTime('12:00 PM'), const TimeOfDay(hour: 12, minute: 0));
      expect(DateConverter.parseFlexibleTime('12:30 AM'), const TimeOfDay(hour: 0, minute: 30));
    });

    test('rejects malformed input', () {
      for (final String bad in ['', '   ', 'abc', '25:99', '10:75', '99', '13:00 PM', '0:00 AM', '10:30 XM', ':30', '10:']) {
        expect(DateConverter.parseFlexibleTime(bad), isNull, reason: 'should reject "$bad"');
      }
      expect(DateConverter.parseFlexibleTime(null), isNull);
    });
  });

  group('isTimeWithinOpeningHours', () {
    const String open = '10:00';
    const String close = '22:00';

    test('accepts times inside a normal window, inclusive of both bounds', () {
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 10, minute: 0), open, close), isTrue);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 10, minute: 30), open, close), isTrue);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 22, minute: 0), open, close), isTrue);
    });

    test('rejects times outside a normal window', () {
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 9, minute: 59), open, close), isFalse);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 3, minute: 0), open, close), isFalse);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 22, minute: 1), open, close), isFalse);
    });

    test('handles a window that runs past midnight', () {
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 20, minute: 0), '18:00', '02:00'), isTrue);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 1, minute: 0), '18:00', '02:00'), isTrue);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 12, minute: 0), '18:00', '02:00'), isFalse);
    });

    test('tolerates HH:mm:ss and rejects unusable schedule data', () {
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 11, minute: 0), '10:00:00', '22:00:00'), isTrue);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 11, minute: 0), null, close), isFalse);
      expect(DateConverter.isTimeWithinOpeningHours(const TimeOfDay(hour: 11, minute: 0), 'garbage', close), isFalse);
    });
  });
}

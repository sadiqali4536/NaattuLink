import 'package:flutter_test/flutter_test.dart';
import 'package:naattulink/MVVM/utils/service_functions/availability_utils.dart';

void main() {
  group('AvailabilityUtils', () {
    test('invalid schedules return invalidSchedule', () {
      expect(AvailabilityUtils.checkAvailability(null), ServiceAvailability.invalidSchedule);
      expect(AvailabilityUtils.checkAvailability(''), ServiceAvailability.invalidSchedule);
      expect(AvailabilityUtils.checkAvailability('9 AM'), ServiceAvailability.invalidSchedule);
      expect(AvailabilityUtils.checkAvailability('9 AM to 8 PM'), ServiceAvailability.invalidSchedule);
      expect(AvailabilityUtils.checkAvailability('gibberish - gibberish'), ServiceAvailability.invalidSchedule);
    });

    test('standard schedule: 9 AM - 8 PM', () {
      const schedule = '9 AM - 8 PM';
      
      // 10:00 AM should be available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 10, 0)),
        ServiceAvailability.available,
      );

      // 8:00 AM should be not available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 8, 0)),
        ServiceAvailability.notAvailable,
      );

      // 9:00 PM should be not available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 21, 0)),
        ServiceAvailability.notAvailable,
      );
    });

    test('overnight schedule: 8 PM - 2 AM', () {
      const schedule = '8 PM - 2 AM';
      
      // 11:00 PM should be available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 23, 0)),
        ServiceAvailability.available,
      );

      // 1:00 AM should be available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 2, 1, 0)),
        ServiceAvailability.available,
      );

      // 3:00 AM should be not available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 2, 3, 0)),
        ServiceAvailability.notAvailable,
      );

      // 7:00 PM should be not available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 19, 0)),
        ServiceAvailability.notAvailable,
      );
    });

    test('handles zero-padded and minute formats: 09:30 AM - 10:45 PM', () {
      const schedule = '09:30 AM - 10:45 PM';

      // 9:15 AM should be not available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 9, 15)),
        ServiceAvailability.notAvailable,
      );

      // 9:45 AM should be available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 9, 45)),
        ServiceAvailability.available,
      );

      // 10:30 PM should be available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 22, 30)),
        ServiceAvailability.available,
      );

      // 11:00 PM should be not available
      expect(
        AvailabilityUtils.checkAvailability(schedule, currentTime: DateTime(2023, 1, 1, 23, 0)),
        ServiceAvailability.notAvailable,
      );
    });
  });
}

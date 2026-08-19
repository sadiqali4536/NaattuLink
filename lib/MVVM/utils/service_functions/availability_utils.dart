import 'package:flutter/material.dart';

enum ServiceAvailability { available, notAvailable, invalidSchedule }

class AvailabilityUtils {
  /// Parses the schedule string (e.g. "9 AM - 8 PM" or "09:00 AM - 10:00 PM")
  /// and checks if the current time falls within operating hours.
  static ServiceAvailability checkAvailability(String? scheduleString,
      {DateTime? currentTime}) {
    if (scheduleString == null || scheduleString.trim().isEmpty) {
      return ServiceAvailability.invalidSchedule;
    }

    final now = currentTime ?? DateTime.now();
    final parts = scheduleString.split('-');
    if (parts.length != 2) {
      return ServiceAvailability.invalidSchedule;
    }

    try {
      final openTime = _parseTime(parts[0].trim());
      final closeTime = _parseTime(parts[1].trim());

      if (openTime == null || closeTime == null) {
        return ServiceAvailability.invalidSchedule;
      }

      // Convert current time to a comparable double (hours.minutes)
      final currentDouble = now.hour + (now.minute / 60.0);
      final openDouble = openTime.hour + (openTime.minute / 60.0);
      final closeDouble = closeTime.hour + (closeTime.minute / 60.0);

      if (closeDouble < openDouble) {
        // Overnight schedule (e.g. 8:00 PM - 2:00 AM)
        if (currentDouble >= openDouble || currentDouble < closeDouble) {
          return ServiceAvailability.available;
        } else {
          return ServiceAvailability.notAvailable;
        }
      } else {
        // Standard schedule (e.g. 9:00 AM - 8:00 PM)
        if (currentDouble >= openDouble && currentDouble < closeDouble) {
          return ServiceAvailability.available;
        } else {
          return ServiceAvailability.notAvailable;
        }
      }
    } catch (e) {
      return ServiceAvailability.invalidSchedule;
    }
  }

  static TimeOfDay? _parseTime(String timeString) {
    timeString = timeString.toUpperCase().trim();
    final regex = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$');
    final match = regex.firstMatch(timeString);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      String period = match.group(3)!;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }
}

class AvailabilityBadge extends StatelessWidget {
  final String? scheduleString;

  const AvailabilityBadge({Key? key, this.scheduleString}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = AvailabilityUtils.checkAvailability(scheduleString);

    String text;
    Color color;

    switch (status) {
      case ServiceAvailability.available:
        text = 'Open';
        color = Colors.green;
        break;
      case ServiceAvailability.notAvailable:
        text = 'Closed';
        color = Colors.red;
        break;
      case ServiceAvailability.invalidSchedule:
        text = 'Hours not available';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

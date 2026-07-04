// ============ Date Formatter ===================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

getFormattedDate(DateTime date) {
  return DateFormat('d MMM yyyy').format(date);
}

getFormattedDateForApi(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

getDateFromString(String date, {String format = 'yyyy-MM-dd'}) {
  // Expected format: yyyy-MM-dd
  return DateTime.parse(date);
}

getFormattedDateInMMDDYYYY(DateTime date) {
  return DateFormat('MMMM dd yyyy').format(date);
}

getFormattedDateInMonthDateYear(DateTime date) {
  return DateFormat('MMMM dd, yyyy').format(date);
}

String getDayLabel(DateTime date) {
  final DateTime now = DateTime.now();

  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final DateTime checkDate = DateTime(date.year, date.month, date.day);

  if (checkDate == today) {
    return "Today";
  } else if (checkDate == yesterday) {
    return "Yesterday";
  } else {
    return getFormattedDateInMonthDateYear(date);
  }
}

String getCurrentDayName() {
  final now = DateTime.now();
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  return days[now.weekday - 1];
}

// DateTime getDateFromString(String date) {
//   final dateParts = date.split('-');
//   final day = int.parse(dateParts[0]);
//   final month = int.parse(dateParts[1]);
//   final year = int.parse(dateParts[2]);
//   return DateTime(year, month, day);
// }

List<Map<String, dynamic>> getCurrentWeekDates() {
  final DateTime today = DateTime.now();

  // Sunday as start of the week
  final DateTime startOfWeek =
      today.subtract(Duration(days: today.weekday % 7));
  return List.generate(7, (index) {
    final DateTime date = startOfWeek.add(Duration(days: index));
    return {
      "day": _getDayName(date.weekday),
      "date": date.day.toString(),
      "is_today": DateUtils.isSameDay(date, today)
    };
  });
}

String _getDayName(int weekday) {
  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  return days[weekday - 1];
}

List<Map<String, String>> generate7Days() {
  final DateTime today = DateTime.now();
  final DateFormat dayFormat = DateFormat('dd');
  final DateFormat dayNameFormat = DateFormat('EEE');
  final DateFormat fullDateFormat = DateFormat('yyyy-MM-dd');

  List<Map<String, String>> days = [];

  // From -3 days to +3 days (today at center)
  for (int i = -3; i <= 3; i++) {
    final DateTime date = today.add(Duration(days: i));

    days.add({
      "day": dayFormat.format(date),
      "day_name": dayNameFormat.format(date),
      "date": fullDateFormat.format(date)
    });
  }

  return days;
}

// Get Greeting Based On Time
String getGreeting() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) {
    return "Good Morning";
  } else if (hour >= 12 && hour < 17) {
    return "Good Afternoon";
  } else if (hour >= 17 && hour < 21) {
    return "Good Evening";
  } else {
    return "Good Night";
  }
}

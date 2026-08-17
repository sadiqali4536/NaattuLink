import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HelperFunctions {
  // Navigate to another screen
  static void navigateToScreenPush(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void navigateToScreenPushReplaceAll(
      BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  // Navigate to another screen
  static void navigateToScreenPop(BuildContext context, Widget screen) {
    Navigator.pop(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Check if dark mode is enabled
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

String formatDate(Timestamp? timestamp) {
  if (timestamp == null) return 'N/A';
  final dateTime = timestamp.toDate(); // Convert Timestamp to DateTime
  final formatter = DateFormat('d MMM, y'); // e.g. 24 May, 2025
  return formatter.format(dateTime);
}

Future<String?> getRole(String? uid) async {
  if (uid == null) return null;

  final collections = [
    'users',
    'workers',
    'healthcare',
    'transports',
    'shops_businesses'
  ];

  for (String collection in collections) {
    final doc =
        await FirebaseFirestore.instance.collection(collection).doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('role')) {
      return doc['role'];
    }
  }

  return null;
}

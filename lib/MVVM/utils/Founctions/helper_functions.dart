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

Future<DocumentSnapshot?> getUserDocument(
    User firebaseUser, String collection) async {
  // 1. By UID
  final doc = await FirebaseFirestore.instance
      .collection(collection)
      .doc(firebaseUser.uid)
      .get();
  if (doc.exists) return doc;

  // 2. By Email
  if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
    final emailQuery = await FirebaseFirestore.instance
        .collection(collection)
        .where('email', isEqualTo: firebaseUser.email!.trim().toLowerCase())
        .limit(1)
        .get();
    if (emailQuery.docs.isNotEmpty) return emailQuery.docs.first;
  }

  // 3. By Phone
  if (firebaseUser.phoneNumber != null &&
      firebaseUser.phoneNumber!.isNotEmpty) {
    String phone = firebaseUser.phoneNumber!;
    String rawPhone = phone;
    String phoneWithPrefix = phone;
    if (!phone.startsWith('+91')) {
      phoneWithPrefix = '+91$phone';
    } else {
      rawPhone = phone.replaceFirst('+91', '');
    }
    final phoneQuery = await FirebaseFirestore.instance
        .collection(collection)
        .where('phone', whereIn: [rawPhone, phoneWithPrefix])
        .limit(1)
        .get();
    if (phoneQuery.docs.isNotEmpty) return phoneQuery.docs.first;
  }

  return null;
}

Future<String?> getRole(User? firebaseUser) async {
  if (firebaseUser == null) return null;

  final collections = [
    'users',
    'workers',
    'healthcare',
    'transports',
    'shops_businesses',
    'businesses'
  ];

  for (String collection in collections) {
    final doc = await getUserDocument(firebaseUser, collection);
    if (doc != null &&
        doc.data() != null &&
        (doc.data() as Map<String, dynamic>).containsKey('role')) {
      return (doc.data() as Map<String, dynamic>)['role'];
    }
  }

  return null;
}

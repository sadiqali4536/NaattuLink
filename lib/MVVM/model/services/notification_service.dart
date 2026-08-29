import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // 3. Android Notification Channel (High Importance)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Foreground messaging listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      _showLocalNotification(message, channel);
    });

    // 6. Handling notification open app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Message clicked!");
      _handleDeepLink(message.data['deepLink']);
    });

    // 7. Handling notification when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleDeepLink(initialMessage.data['deepLink']);
    }

    // 8. Token handling
    _messaging.onTokenRefresh.listen((newToken) {
      saveFcmTokenToFirestore(newToken);
    });

    // 9. Initial token retrieval
    await syncCurrentToken();

    _initialized = true;
  }

  Future<void> syncCurrentToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint("====================================================");
        debugPrint("🌟 FCM TOKEN: $token");
        debugPrint("====================================================");
        await saveFcmTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }
  }

  Future<void> _showLocalNotification(
      RemoteMessage message, AndroidNotificationChannel channel) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      BigPictureStyleInformation? bigPictureStyleInformation;

      String? imgUrl = android.imageUrl ?? message.data['imageUrl'] as String?;
      if (imgUrl != null && imgUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(imgUrl));
          if (response.statusCode == 200) {
            final Uint8List bytes = response.bodyBytes;
            bigPictureStyleInformation = BigPictureStyleInformation(
              ByteArrayAndroidBitmap(bytes),
            );
          }
        } catch (e) {
          debugPrint("Failed to load image for local notification: $e");
        }
      }

      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'ic_notification',
            styleInformation: bigPictureStyleInformation,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['deepLink'] as String?,
      );
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      debugPrint("Notification tapped with payload deepLink: $payload");
      _handleDeepLink(payload);
    }
  }

  Future<void> _handleDeepLink(String? deepLink) async {
    if (deepLink == null || deepLink.trim().isEmpty) return;

    final link = deepLink.trim();

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      if (Get.currentRoute.isEmpty) {
        Get.toNamed(link);
        return;
      }

      Get.toNamed(link);
    } catch (e) {
      debugPrint('Deep link navigation failed: $e');
    }
  }

  Future<void> saveFcmTokenToFirestore(String token) async {
    try {
      // 1. Cache locally
      final storage = GetStorage();
      String? cachedToken = storage.read('firebase_fcm_token');

      // 2. Check current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If not logged in, just cache it locally and wait
        storage.write('firebase_fcm_token', token);
        return;
      }

      // If token is same as cached, avoid unnecessary write, but if we don't have it in Firestore, we should still write.
      if (cachedToken == token) {
        // To strictly prevent unnecessary writes, we could return here,
        // but it's safer to always ensure Firestore is in sync during login flow or token refresh.
      }
      storage.write('firebase_fcm_token', token);

      final db = FirebaseFirestore.instance;
      final userId = user.uid;

      // Find user collection logic
      DocumentReference? userDocRef;

      Future<DocumentSnapshot?> findInCollection(String collection) async {
        final doc = await db.collection(collection).doc(userId).get();
        if (doc.exists) return doc;

        if (user.email != null && user.email!.isNotEmpty) {
          final query = await db
              .collection(collection)
              .where('email', isEqualTo: user.email!.trim().toLowerCase())
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) return query.docs.first;
        }

        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          String phone = user.phoneNumber!;
          String rawPhone = phone;
          String phoneWithPrefix = phone;
          if (!phone.startsWith('+91')) {
            phoneWithPrefix = '+91$phone';
          } else {
            rawPhone = phone.replaceFirst('+91', '');
          }
          final phoneQuery = await db
              .collection(collection)
              .where('phone', whereIn: [rawPhone, phoneWithPrefix])
              .limit(1)
              .get();
          if (phoneQuery.docs.isNotEmpty) return phoneQuery.docs.first;
        }
        return null;
      }

      final collections = [
        'users',
        'workers',
        'transports',
        'healthcare',
        'shops_businesses'
      ];

      for (var collection in collections) {
        final doc = await findInCollection(collection);
        if (doc != null) {
          userDocRef = doc.reference;
          break;
        }
      }

      if (userDocRef != null) {
        final installId = _getInstallationId();
        await userDocRef.set({
          'devices': {
            installId: {
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            }
          },
          'notificationsEnabled': true,
        }, SetOptions(merge: true));
        debugPrint(
            "FCM token updated successfully for install $installId in ${userDocRef.path}");
      } else {
        debugPrint(
            "User document not found across collections to update FCM token.");
      }
    } catch (e) {
      debugPrint("Error saving FCM token to Firestore: $e");
    }
  }

  Future<void> clearFcmTokenFromFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userId = user.uid;
      final db = FirebaseFirestore.instance;

      DocumentReference? userDocRef;
      Future<DocumentSnapshot?> findInCollection(String collection) async {
        final doc = await db.collection(collection).doc(userId).get();
        if (doc.exists) return doc;
        return null; // Simplify for clear token
      }

      final collections = [
        'users',
        'workers',
        'transports',
        'healthcare',
        'shops_businesses'
      ];
      for (var collection in collections) {
        final doc = await findInCollection(collection);
        if (doc != null) {
          userDocRef = doc.reference;
          break;
        }
      }
      if (userDocRef != null) {
        final installId = _getInstallationId();
        await userDocRef.update({
          'devices.$installId': FieldValue.delete(),
        });
      }
      GetStorage().remove('firebase_fcm_token');
    } catch (e) {
      debugPrint("Error clearing FCM token: $e");
    }
  }

  String _getInstallationId() {
    final storage = GetStorage();
    String? installId = storage.read('installation_id');
    if (installId == null) {
      final rand = Random();
      installId =
          'install_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(100000)}';
      storage.write('installation_id', installId);
    }
    return installId;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EmailService {
  static const String serviceId =
      'service_j42fwxa'; // Ensure these match User's actual IDs
  static const String templateId = 'template_94gtqo7';
  static const String publicKey = 'IODbTKJ4kKqg3U4x4';

  Future<bool> sendPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'to_email': email,
            'otp': otp,
          }
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('EmailJS Error: [${response.statusCode}] ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('EmailJS Exception: $e');
      return false;
    }
  }
}

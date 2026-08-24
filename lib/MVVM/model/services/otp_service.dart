import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class OtpService {
  // Vercel deployment endpoints
  static const String vercelBackendBaseUrl =
      'https://naattulink-backend-c1x0hp0fz-sadiqalis-projects.vercel.app/api';

  static void toastError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void toastSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Sends an OTP to the given identifier (phone number or email).
  /// Purpose can be 'login' or 'password_reset'.
  /// Returns the requestId if successful, or null on failure.
  static Future<String?> sendOtp({
    required String identifier,
    required String purpose,
  }) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    debugPrint("=== OTP SERVICE: sendOtp STARTED ===");
    debugPrint("Entered identifier: $normalizedIdentifier | Purpose: $purpose");

    if (normalizedIdentifier.isEmpty) {
      toastError('Please enter your email or phone number');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$vercelBackendBaseUrl/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': normalizedIdentifier,
          'purpose': purpose,
        }),
      );

      debugPrint("Backend Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['requestId'] != null) {
          toastSuccess('OTP sent successfully!');
          return body['requestId'];
        }
      } else {
        try {
          final body = json.decode(response.body);
          final errorMessage = body['error'] ?? 'Server error: ${response.statusCode}';
          debugPrint("Server error: $errorMessage");
          toastError(errorMessage);
        } catch (_) {
          debugPrint("Non-JSON Server error: ${response.statusCode}");
          debugPrint("Response body: ${response.body}");
          toastError('Server error: ${response.statusCode}. Check logs.');
        }
      }
    } catch (e) {
      debugPrint("Error making network request: $e");
      toastError('Network error. Please check your connection.');
    }
    
    return null;
  }

  /// Verifies an OTP and returns a Map containing 'success' and token information
  static Future<Map<String, dynamic>?> verifyOtp({
    required String requestId,
    required String otp,
    required String purpose,
  }) async {
    if (otp.isEmpty || otp.length < 4) {
      toastError('Please enter a valid OTP');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$vercelBackendBaseUrl/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requestId': requestId,
          'otp': otp,
          'purpose': purpose,
        }),
      );

      debugPrint("Backend Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          toastSuccess('OTP verified successfully!');
          return body;
        }
      } else {
        try {
          final body = json.decode(response.body);
          final errorMessage = body['error'] ?? 'Server error: ${response.statusCode}';
          debugPrint("Server error: $errorMessage");
          toastError(errorMessage);
        } catch (_) {
          debugPrint("Non-JSON Server error: ${response.statusCode}");
          debugPrint("Response body: ${response.body}");
          toastError('Server error: ${response.statusCode}. Check logs.');
        }
      }
    } catch (e) {
      debugPrint("Error making network request: $e");
      toastError('Network error. Please check your connection.');
    }
    
    return null;
  }
}

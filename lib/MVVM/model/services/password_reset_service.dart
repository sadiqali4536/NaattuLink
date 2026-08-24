import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class PasswordResetService {
  // Vercel backend base URL for the forgot-password flow
  static const String baseUrl =
      'https://naattulink-backend-c1x0hp0fz-sadiqalis-projects.vercel.app/api/auth/forgot-password';

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

  /// Step 1: Check if the account exists and fetch available recovery methods
  static Future<Map<String, dynamic>?> checkAccount(String identifier) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    
    if (normalizedIdentifier.isEmpty) {
      toastError('Please enter your email or phone number');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check-account'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': normalizedIdentifier}),
      );

      debugPrint("checkAccount Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body;
      } else {
        _handleError(response);
      }
    } catch (e) {
      debugPrint("Error making network request: $e");
      toastError('Network error. Please check your connection.');
    }
    return null;
  }

  /// Step 2: Send OTP via the selected method
  static Future<Map<String, dynamic>?> sendOtp({
    required String identifier,
    required String method,
  }) async {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': normalizedIdentifier,
          'method': method,
        }),
      );

      debugPrint("sendOtp Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        toastSuccess('OTP sent successfully!');
        return body; // contains verificationId
      } else {
        _handleError(response);
      }
    } catch (e) {
      debugPrint("Error making network request: $e");
      toastError('Network error. Please check your connection.');
    }
    return null;
  }

  /// Step 3: Verify the OTP
  static Future<Map<String, dynamic>?> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    if (otp.isEmpty || otp.length < 4) {
      toastError('Please enter a valid OTP');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'verificationId': verificationId,
          'otp': otp,
        }),
      );

      debugPrint("verifyOtp Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        toastSuccess('OTP verified successfully!');
        return body; // contains resetToken
      } else {
        _handleError(response);
      }
    } catch (e) {
      debugPrint("Error making network request: $e");
      toastError('Network error. Please check your connection.');
    }
    return null;
  }

  /// Step 4: Reset the password and get the Custom Token
  static Future<Map<String, dynamic>?> resetPassword({
    required String verificationId,
    required String resetToken,
    required String newPassword,
  }) async {
    if (newPassword.isEmpty || newPassword.length < 6) {
      toastError('Password must be at least 6 characters long');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'verificationId': verificationId,
          'resetToken': resetToken,
          'newPassword': newPassword,
        }),
      );

      debugPrint("resetPassword Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        toastSuccess('Password reset successfully!');
        return body; // contains customToken
      } else {
        _handleError(response);
      }
    } catch (e) {
      debugPrint("Error making network request: $e");
      toastError('Network error. Please check your connection.');
    }
    return null;
  }

  static void _handleError(http.Response response) {
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
}

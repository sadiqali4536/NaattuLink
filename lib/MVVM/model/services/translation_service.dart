import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TranslationService {
  // Configurable backend URL. Replace with your actual deployed backend URL when ready.
  // For example: 'https://api.naattulink.com/api/translate-location'
  static const String _backendTranslateUrl = 'https://YOUR_BACKEND_URL/api/translate-location';

  /// Calls the secure backend to translate the [text] to Malayalam and Hindi.
  /// Returns a map with 'english', 'malayalam', and 'hindi' keys.
  static Future<Map<String, String>> translateLocation(String text) async {
    try {
      // Return early if the text is empty
      if (text.trim().isEmpty) {
        return {
          'english': '',
          'malayalam': '',
          'hindi': '',
        };
      }

      // If backend is not yet ready/configured, you can return a mock or fallback
      if (_backendTranslateUrl.contains('YOUR_BACKEND_URL')) {
        debugPrint('TranslationService: Backend URL not configured. Returning fallback translation.');
        return {
          'english': text,
          'malayalam': text, // Fallback until backend is active
          'hindi': text,     // Fallback until backend is active
        };
      }

      final response = await http.post(
        Uri.parse(_backendTranslateUrl),
        headers: {
          'Content-Type': 'application/json',
          // Add any auth tokens required by your backend here
        },
        body: jsonEncode({
          'text': text,
          'sourceLanguage': 'en',
          'targetLanguages': ['ml', 'hi']
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'english': data['english'] ?? text,
          'malayalam': data['malayalam'] ?? text,
          'hindi': data['hindi'] ?? text,
        };
      } else {
        debugPrint('Translation backend error: ${response.statusCode}');
        // Fallback to English on error
        return {
          'english': text,
          'malayalam': text,
          'hindi': text,
        };
      }
    } catch (e) {
      debugPrint('Translation API Error: $e');
      // Fallback
      return {
        'english': text,
        'malayalam': text,
        'hindi': text,
      };
    }
  }
}

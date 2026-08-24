import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String serviceId = 'service_j42fwxa';
  const String templateId = 'template_94gtqo7';
  const String publicKey = 'IODbTKJ4kKqg3U4x4';

  print('Sending via HTTP...');
  final response = await http.post(
    Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'to_email': 'dreemfighter9@gmail.com',
        'otp': '4920',
      },
    }),
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}

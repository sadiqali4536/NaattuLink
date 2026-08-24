import 'sms_account_type.dart';

class TextBeeConfig {
  final SmsAccountType accountType;
  final String accountName;
  final int priority;

  const TextBeeConfig({
    required this.accountType,
    required this.accountName,
    required this.priority,
  });
}

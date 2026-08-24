import 'sms_account_type.dart';
import 'textbee_config.dart';

class TextBeeConfigManager {
  static TextBeeConfig getConfig(SmsAccountType accountType) {
    switch (accountType) {
      case SmsAccountType.account1:
        return const TextBeeConfig(
          accountType: SmsAccountType.account1,
          accountName: 'TextBee Account 1',
          priority: 1,
        );

      case SmsAccountType.account2:
        return const TextBeeConfig(
          accountType: SmsAccountType.account2,
          accountName: 'TextBee Account 2',
          priority: 2,
        );

      case SmsAccountType.account3:
        return const TextBeeConfig(
          accountType: SmsAccountType.account3,
          accountName: 'TextBee Account 3',
          priority: 3,
        );

      case SmsAccountType.account4:
        return const TextBeeConfig(
          accountType: SmsAccountType.account4,
          accountName: 'TextBee Account 4',
          priority: 4,
        );
    }
  }
}

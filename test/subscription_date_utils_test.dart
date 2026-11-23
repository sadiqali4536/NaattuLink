import 'package:flutter_test/flutter_test.dart';
import 'package:naattulink/MVVM/utils/subscription_date_utils.dart';

void main() {
  group('SubscriptionDateUtils Tests', () {
    test('calculateRemainingDays returns 365 on day 1 for 1-year plan', () {
      // Current date: 2026-11-20 10:00:00 IST
      final now = DateTime(2026, 11, 20, 10, 0);
      // Expiry date: 364 days later (365th day) at 23:59:59 IST (2027-11-19)
      final expiry = DateTime(2027, 11, 19, 23, 59, 59);

      final days = SubscriptionDateUtils.calculateRemainingDays(expiry, currentTime: now);
      expect(days, equals(365));
    });

    test('calculateRemainingDays automatically decrements on day 2 to 364', () {
      final nowNextDay = DateTime(2026, 11, 21, 08, 0);
      final expiry = DateTime(2027, 11, 19, 23, 59, 59);

      final days = SubscriptionDateUtils.calculateRemainingDays(expiry, currentTime: nowNextDay);
      expect(days, equals(364));
    });

    test('calculateRemainingDays returns 1 on last day before midnight', () {
      final now = DateTime(2026, 11, 20, 15, 0);
      final expiry = DateTime(2026, 11, 20, 23, 59, 59);

      final days = SubscriptionDateUtils.calculateRemainingDays(expiry, currentTime: now);
      expect(days, equals(1));
    });

    test('calculateRemainingDays returns 0 and is not active when expired', () {
      final now = DateTime(2026, 11, 21, 00, 01);
      final expiry = DateTime(2026, 11, 20, 23, 59, 59);

      final days = SubscriptionDateUtils.calculateRemainingDays(expiry, currentTime: now);
      expect(days, equals(0));

      final isActive = SubscriptionDateUtils.isSubscriptionActive(expiry, currentTime: now);
      expect(isActive, isFalse);
    });

    test('Renewal before expiry extends from existing expiry date', () {
      final now = DateTime(2026, 11, 15, 10, 0);
      final currentExpiry = DateTime(2026, 11, 20, 23, 59, 59);

      final result = SubscriptionDateUtils.calculateRenewalDates(
        currentExpiryDate: currentExpiry,
        durationDays: 30,
        renewalDate: now,
      );

      // Expiry should extend 30 days past Nov 20 -> Dec 20
      final expiryIst = SubscriptionDateUtils.toIST(result.expiryDate);
      expect(expiryIst.month, equals(12));
      expect(expiryIst.day, equals(20));
    });

    test('Renewal after expiry starts from renewal activation date', () {
      final now = DateTime(2026, 11, 25, 10, 0);
      final expiredDate = DateTime(2026, 11, 20, 23, 59, 59);

      final result = SubscriptionDateUtils.calculateRenewalDates(
        currentExpiryDate: expiredDate,
        durationDays: 30,
        renewalDate: now,
      );

      final startIst = SubscriptionDateUtils.toIST(result.startDate);
      expect(startIst.day, equals(25));
      expect(startIst.month, equals(11));

      // 30 days starting on 25th -> Nov 25 + 29 days = Dec 24
      final expiryIst = SubscriptionDateUtils.toIST(result.expiryDate);
      expect(expiryIst.month, equals(12));
      expect(expiryIst.day, equals(24));
    });
  });
}

import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'dart:math';

class DynamicContentService {
  static int _getPeriodSeed(String? storeId) {
    final now = DateTime.now();
    final int daysSinceEpoch =
        now.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
    final int periodSeed = daysSinceEpoch ~/ 2;
    int finalSeed = periodSeed;
    if (storeId != null && storeId.isNotEmpty) {
      finalSeed += storeId.hashCode;
    }
    return finalSeed.abs();
  }

  static double calculateDiscount(StoreProductModel p) {
    if (p.discountPrice > 0 && p.price > 0 && p.discountPrice < p.price) {
      return ((p.price - p.discountPrice) / p.price) * 100;
    }
    return 0.0;
  }

  static bool hasOffer(StoreProductModel p) {
    return calculateDiscount(p) > 0;
  }

  static List<StoreProductModel> getDynamicProducts(
      List<StoreProductModel> products, String section,
      {String? storeId, Set<String>? excludeIds}) {
    if (products.isEmpty) return [];

    List<StoreProductModel> result = List.from(products);

    // Apply exclusion filter if provided and enough products exist
    if (excludeIds != null && excludeIds.isNotEmpty) {
      final filtered = result.where((p) => !excludeIds.contains(p.id)).toList();
      // Only exclude if we don't exhaust the pool (allow reuse if too few items)
      if (filtered.length >= 4) {
        result = filtered;
      }
    }

    final random = Random(); // Dynamic randomization on every call

    if (section == 'Top Value Deals' ||
        section == 'Flash Deals' ||
        section == 'Top Deals') {
      result.sort((a, b) {
        return calculateDiscount(b).compareTo(calculateDiscount(a));
      });
    } else if (section == 'Brands in Spotlight') {
      result.sort(
          (a, b) => b.isFeatured == a.isFeatured ? 0 : (b.isFeatured ? 1 : -1));
    } else if (section == 'Popular Nearby') {
      result.sort((a, b) => b.totalRatings.compareTo(a.totalRatings));
    } else if (section == 'Afternoon Picks' ||
        section == 'Suggested For You' ||
        section == 'Handpicked') {
      // Dynamic shuffle
      result.shuffle(random);
    }

    return result;
  }

  static String getGreeting(String? username, {String? storeId}) {
    final int seed = _getPeriodSeed(storeId);
    final name = (username != null && username.isNotEmpty) ? username : '';
    final greetings = [
      'New week, new treats $name 🌟',
      'Fresh picks for you $name ✨',
      'Something special for you $name 💙',
      'Ready for some great picks? 🛍️',
      'A few things you might love 👀',
      'Good finds are waiting for you ✨',
      'Your next favorite might be here 💫',
      'Fresh deals, just for you 🔥',
      'A little shopping inspiration 🛒',
      'Something worth checking out 👌',
      'Today’s picks are looking good 😍',
      'Discover something new today 🌟',
    ];
    return greetings[seed % greetings.length];
  }

  static String getPromotionalDialogue(
      String section, List<StoreProductModel> availableProducts,
      {String? storeId}) {
    final int seed = _getPeriodSeed(storeId);
    final bool hasStrongDiscounts =
        availableProducts.any((p) => calculateDiscount(p) > 30);
    final bool hasHighlyRated =
        availableProducts.any((p) => p.averageRating > 4.5);

    if (section == 'Still Looking For') {
      final options = [
        'Still Looking For Something?',
        'Looking For More?',
        'You Might Like These',
        'More Picks For You',
        'Worth A Look',
        'Picked For You',
      ];
      return options[seed % options.length];
    }
    if (section == 'Afternoon Picks') {
      if (hasStrongDiscounts && seed % 2 == 0)
        return "Afternoon deals you don't want to miss";
      if (hasHighlyRated && seed % 3 == 0)
        return "Popular picks for this afternoon";
      return "Afternoon picks for you";
    }

    if (section == 'Top Value Deals') {
      if (hasStrongDiscounts) return "Max discounts available now";
      return "Great value products";
    }

    if (section == 'Suggested') {
      if (seed % 2 == 0) return "Fresh choices for you";
      return "Based on your interest";
    }

    return "Great picks for you";
  }

  static String getDynamicTitle(
      String baseTitle, List<StoreProductModel> availableProducts,
      {String? storeId}) {
    return baseTitle;
  }
}

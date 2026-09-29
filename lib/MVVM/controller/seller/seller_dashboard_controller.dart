import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/seller/seller_access_controller.dart';
import 'package:naattulink/MVVM/model/seller/seller_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerDashboardController extends GetxController {
  static SellerDashboardController get to => Get.find();

  final RxInt bottomNavIndex = 0.obs;
  final RxInt totalProducts = 0.obs;
  final RxInt totalOrders = 0.obs;
  final RxDouble totalSales = 0.0.obs;
  final RxDouble thisMonthSales = 0.0.obs;
  final RxInt totalCustomers = 0.obs;
  final RxInt todayCustomers = 0.obs;
  final RxInt totalDispatchedOrders = 0.obs;
  final RxDouble averageRating = 0.0.obs;
  final RxInt totalViews = 0.obs;
  final RxInt outOfStockProducts = 0.obs;
  final RxInt refundPendingOrders = 0.obs;

  // Today's Sales State
  final Rx<DateTime> selectedSalesDate = DateTime.now().obs;
  final RxDouble selectedDateSales = 0.0.obs;
  final RxInt selectedDateOrders = 0.obs;
  final RxList<double> hourlySales = List.filled(24, 0.0).obs;
  final RxMap<String, double> productSalesData = <String, double>{}.obs;
  final RxBool isLoadingSales = false.obs;

  SellerModel? get currentSeller =>
      SellerAccessController.to.currentSeller.value;

  @override
  void onInit() {
    super.onInit();
    // Heavy queries moved to onReady to avoid freezing the route transition
  }

  @override
  void onReady() {
    super.onReady();
    // Add a slight delay to let the page transition animation finish smoothly
    Future.delayed(const Duration(milliseconds: 300), () {
      fetchProductCount();
      fetchDashboardMetrics();
      fetchSalesForDate(DateTime.now());
    });
  }

  void changeTabIndex(int index) {
    bottomNavIndex.value = index;
    if (index == 0) {
      // Refresh metrics when coming back to dashboard tab
      fetchProductCount();
      fetchDashboardMetrics();
    }
  }

  Future<void> fetchDashboardMetrics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('sellerId', isEqualTo: uid)
          .where('bookingType', isEqualTo: 'Product Order')
          .limit(20)
          .get();

      int pendingAndProcessingCount = 0;

      double sales = 0.0;
      double currentMonthSales = 0.0;
      int dispatchedOrdersCount = 0;
      int refundPendingCount = 0;
      Set<String> uniqueCustomers = {};
      Set<String> todayUniqueCustomers = {};

      final now = DateTime.now();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        final rawPrice =
            data['totalAmount'] ?? data['price'] ?? data['discountPrice'] ?? 0;
        final numPrice = num.tryParse(rawPrice.toString()) ?? 0;
        final priceVal = numPrice.toDouble();
        final status = (data['status'] ?? '').toString().toLowerCase();

        // Only count dispatched/delivered orders for sales totals
        final isDispatched =
            status.contains('dispatch') || status.contains('deliver');

        if (isDispatched) {
          sales += priceVal;
          dispatchedOrdersCount++;
        }

        // Count pending and processing orders
        if (status.contains('pending') || status.contains('process')) {
          pendingAndProcessingCount++;
        }

        // Count refund pending online orders
        if (status.contains('cancel') || status.contains('reject')) {
          final isRefunded = data['Refuned']?.toString() == '1' ||
              data['Refuned']?.toString().toLowerCase() == 'true' ||
              data['Refuned'] == true ||
              data['Refuned'] == 1;

          final paymentMethod =
              data['paymentMethod']?.toString().toLowerCase() ?? '';
          final transactionId = data['transactionId']?.toString() ?? '';
          final isOnline = paymentMethod.contains('online') ||
              paymentMethod.contains('upi') ||
              transactionId.isNotEmpty;

          if (isOnline && !isRefunded) {
            refundPendingCount++;
          }
        }

        // Check if the order is from this month
        DateTime? orderDate;
        if (data['createdAt'] is Timestamp) {
          orderDate = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          orderDate = DateTime.tryParse(data['createdAt']);
        } else if (data['bookingDate'] is Timestamp) {
          orderDate = (data['bookingDate'] as Timestamp).toDate();
        } else if (data['bookingDate'] is String) {
          orderDate = DateTime.tryParse(data['bookingDate']);
        }

        if (orderDate != null) {
          if (orderDate.year == now.year && orderDate.month == now.month) {
            if (isDispatched) {
              currentMonthSales += priceVal;
            }
          }
        }

        final userId = data['userId']?.toString();
        if (userId != null && userId.isNotEmpty) {
          uniqueCustomers.add(userId);
          if (orderDate != null &&
              orderDate.year == now.year &&
              orderDate.month == now.month &&
              orderDate.day == now.day) {
            todayUniqueCustomers.add(userId);
          }
        }
      }

      totalOrders.value = pendingAndProcessingCount;
      totalSales.value = sales;
      thisMonthSales.value = currentMonthSales;
      totalCustomers.value = uniqueCustomers.length;
      todayCustomers.value = todayUniqueCustomers.length;
      totalDispatchedOrders.value = dispatchedOrdersCount;
      refundPendingOrders.value = refundPendingCount;
    } catch (e) {
      print("Error fetching dashboard metrics: $e");
    }
  }

  Future<void> fetchProductCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final countSnap = await FirebaseFirestore.instance
          .collection('store_products')
          .where('sellerId', isEqualTo: uid)
          .count()
          .get();
      totalProducts.value = countSnap.count ?? 0;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('store_products')
          .where('sellerId', isEqualTo: uid)
          .limit(20)
          .get();

      double totalRatingSum = 0.0;
      int ratingCount = 0;
      int viewsCount = 0;
      int outOfStockCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Check stock
        bool isProductOutOfStock = false;
        final status = (data['status']?.toString().toUpperCase() ?? '');
        if (status == 'OUT OF STOCK' || status == 'OUT_OF_STOCK') {
          isProductOutOfStock = true;
        } else {
          final stockQty = data['stockQuantity'];
          if (stockQty != null) {
            final qty = num.tryParse(stockQty.toString()) ?? 0;
            if (qty <= 0) isProductOutOfStock = true;
          }
          if (!isProductOutOfStock) {
            final variants = data['variants'];
            if (variants is List && variants.isNotEmpty) {
              isProductOutOfStock = variants.every((v) {
                final vStock = num.tryParse(
                        (v is Map ? v['stockQuantity'] : null)?.toString() ??
                            '1') ??
                    1;
                return vStock <= 0;
              });
            }
          }
        }

        if (isProductOutOfStock) {
          outOfStockCount++;
        }

        // Calculate views
        if (data['views'] != null) {
          viewsCount += (data['views'] as num).toInt();
        }

        // Calculate ratings
        if (data['rating'] != null) {
          final ratingData = data['rating'];
          final avg = (ratingData['average'] as num?)?.toDouble() ?? 0.0;
          final count = (ratingData['totalRatings'] as num?)?.toInt() ?? 0;

          if (count > 0) {
            totalRatingSum += (avg * count);
            ratingCount += count;
          }
        }
      }

      totalViews.value = viewsCount;
      averageRating.value =
          ratingCount > 0 ? (totalRatingSum / ratingCount) : 0.0;
      outOfStockProducts.value = outOfStockCount;
    } catch (e) {
      print("Error fetching product count: $e");
    }
  }

  Future<void> fetchSalesForDate(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    selectedSalesDate.value = date;
    isLoadingSales.value = true;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay =
          DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('sellerId', isEqualTo: uid)
          .where('bookingType', isEqualTo: 'Product Order')
          .get();

      double totalSalesForDate = 0.0;
      int orderCount = 0;
      List<double> newHourlySales = List.filled(24, 0.0);
      Map<String, double> newProductSales = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();

        // Skip orders that are not dispatched or delivered
        if (!status.contains('dispatch') && !status.contains('deliver')) {
          continue;
        }

        DateTime? orderDate;
        if (data['createdAt'] is Timestamp) {
          orderDate = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          orderDate = DateTime.tryParse(data['createdAt']);
        } else if (data['bookingDate'] is Timestamp) {
          orderDate = (data['bookingDate'] as Timestamp).toDate();
        } else if (data['bookingDate'] is String) {
          orderDate = DateTime.tryParse(data['bookingDate']);
        }

        if (orderDate != null) {
          if (orderDate.year == date.year &&
              orderDate.month == date.month &&
              orderDate.day == date.day) {
            final rawPrice = data['totalAmount'] ??
                data['price'] ??
                data['discountPrice'] ??
                0;
            final numPrice = num.tryParse(rawPrice.toString()) ?? 0;
            final priceVal = numPrice.toDouble();

            totalSalesForDate += priceVal;
            orderCount++;

            int hour = orderDate.hour;
            if (hour >= 0 && hour < 24) {
              newHourlySales[hour] += priceVal;
            }

            // Calculate product/category wise sales
            final cart = data['cart'];
            if (cart is List && cart.isNotEmpty) {
              for (var item in cart) {
                if (item is Map) {
                  // Only count items belonging to this seller
                  final itemSellerId = item['sellerId']?.toString();
                  if (itemSellerId == null || itemSellerId == uid) {
                    final name = item['name']?.toString() ?? 'Unknown Product';
                    final qty =
                        num.tryParse(item['qty']?.toString() ?? '1')?.toInt() ??
                            1;
                    final itemPriceRaw = item['price'] ?? 0;
                    final itemPrice =
                        num.tryParse(itemPriceRaw.toString())?.toDouble() ??
                            0.0;
                    newProductSales[name] =
                        (newProductSales[name] ?? 0.0) + (itemPrice * qty);
                  }
                }
              }
            } else {
              final name =
                  data['serviceTitle']?.toString() ?? 'Unknown Product';
              newProductSales[name] = (newProductSales[name] ?? 0.0) + priceVal;
            }
          }
        }
      }

      selectedDateSales.value = totalSalesForDate;
      selectedDateOrders.value = orderCount;
      hourlySales.value = newHourlySales;
      productSalesData.value = newProductSales;
    } catch (e) {
      print("Error fetching sales for date: $e");
    } finally {
      isLoadingSales.value = false;
    }
  }
}

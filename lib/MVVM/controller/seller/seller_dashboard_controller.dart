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
  final RxInt totalCustomers = 0.obs;

  SellerModel? get currentSeller =>
      SellerAccessController.to.currentSeller.value;

  @override
  void onInit() {
    super.onInit();
    fetchProductCount();
    fetchDashboardMetrics();
  }

  void changeTabIndex(int index) {
    bottomNavIndex.value = index;
  }

  Future<void> fetchDashboardMetrics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('sellerId', isEqualTo: uid)
          .where('bookingType', isEqualTo: 'Product Order')
          .get();
      
      totalOrders.value = querySnapshot.size;
      
      double sales = 0.0;
      Set<String> uniqueCustomers = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        final rawPrice = data['totalAmount'] ?? data['price'] ?? data['discountPrice'] ?? 0;
        final numPrice = num.tryParse(rawPrice.toString()) ?? 0;
        sales += numPrice.toDouble();
        
        final userId = data['userId']?.toString();
        if (userId != null && userId.isNotEmpty) {
          uniqueCustomers.add(userId);
        }
      }
      
      totalSales.value = sales;
      totalCustomers.value = uniqueCustomers.length;
    } catch (e) {
      print("Error fetching dashboard metrics: $e");
    }
  }

  Future<void> fetchProductCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final query = await FirebaseFirestore.instance
          .collection('store_products')
          .where('sellerId', isEqualTo: uid)
          .count()
          .get();
      totalProducts.value = query.count ?? 0;
    } catch (e) {
      print("Error fetching product count: $e");
    }
  }
}

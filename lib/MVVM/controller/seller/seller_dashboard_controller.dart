import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/seller/seller_access_controller.dart';
import 'package:naattulink/MVVM/model/seller/seller_model.dart';

class SellerDashboardController extends GetxController {
  static SellerDashboardController get to => Get.find();

  final RxInt bottomNavIndex = 0.obs;

  SellerModel? get currentSeller => SellerAccessController.to.currentSeller.value;

  void changeTabIndex(int index) {
    bottomNavIndex.value = index;
  }
}

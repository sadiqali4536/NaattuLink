import 'package:get/get.dart';

/// A simple GetX controller that stores the user's current location place name.
/// Set once from FindingLocationPage, read from Homepage and WorkerDashboard.
class LocationController extends GetxController {
  static LocationController get to => Get.find();

  final currentLocation = ''.obs;
}

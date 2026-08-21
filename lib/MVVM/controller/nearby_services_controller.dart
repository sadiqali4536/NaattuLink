import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/nearby_service_model.dart';
import 'package:naattulink/MVVM/model/repository/nearby_services_repository.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';

class NearbyServicesController extends GetxController {
  final NearbyServicesRepository _repository = NearbyServicesRepository();

  // States
  RxBool isLoading = false.obs;
  RxBool isEmpty = false.obs;
  RxBool isError = false.obs;
  RxString errorMessage = ''.obs;
  RxString searchQuery = ''.obs;

  // Data
  RxList<NearbyServiceModel> services = <NearbyServiceModel>[].obs;
  RxMap<String, List<NearbyServiceModel>> categorizedResults =
      <String, List<NearbyServiceModel>>{}.obs;

  // Current context
  String _currentCategory = '';
  DateTime? _lastRefreshTime;

  @override
  void onInit() {
    super.onInit();
    // Warm up cached location on startup
    LocationController.to.fetchLocation();
  }

  void resetState() {
    isLoading.value = false;
    isEmpty.value = false;
    isError.value = false;
    errorMessage.value = '';
    services.clear();
    categorizedResults.clear();
  }

  void performSearch(String query) {
    if (searchQuery.value == query) return;
    searchQuery.value = query;
    if (_currentCategory.isNotEmpty) {
      fetchNearbyServices(_currentCategory);
    }
  }

  Future<void> fetchNearbyServices(String category) async {
    _currentCategory = category;
    resetState();
    isLoading.value = true;

    try {
      // 1. Load location
      await LocationController.to.fetchLocation();
      final locationModel = LocationController.to.currentLocationModel.value;

      if (locationModel == null) {
        isError.value = true;
        errorMessage.value = 'Could not determine location.';
        isLoading.value = false;
        return;
      }

      // 3. Map category to actual Firestore collection name
      final collectionName = _getCollectionNameForCategory(category);
      if (collectionName.isEmpty) {
        isError.value = true;
        errorMessage.value = 'Invalid category or not location-based.';
        isLoading.value = false;
        return;
      }

      // 4. Query, calculate, filter, and sort
      final results = await _repository.getNearbyServices(
        collectionName: collectionName,
        userLat: locationModel.latitude,
        userLng: locationModel.longitude,
        maxSearchRadiusKm: 10.0,
        searchQuery: searchQuery.value,
      );

      // 5. Update state
      services.assignAll(results);

      // 6. Healthcare Special Handling
      if (category.toLowerCase() == 'healthcare') {
        _categorizeHealthcareResults(results);
      } else if (category.toLowerCase() == 'taxi drivers') {
        // Taxi drivers collection contains all transports.
        // We must filter only Taxi here since we couldn't easily do it in geoflutterfire_plus without compounding queries
        final taxiOnly =
            results.where((s) => s.category.toLowerCase() == 'taxi').toList();
        services.assignAll(taxiOnly);
      }

      isEmpty.value = services.isEmpty && categorizedResults.isEmpty;
    } catch (e) {
      isError.value = true;
      errorMessage.value = 'An error occurred while fetching services.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshLocation() async {
    if (_currentCategory.isEmpty) return;

    // Throttle refresh to prevent spam
    if (_lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!).inSeconds < 3) {
      return;
    }
    _lastRefreshTime = DateTime.now();

    isLoading.value = true;

    // Force refresh GPS
    await LocationController.to.fetchLocation(forceRefresh: true);
    final locationModel = LocationController.to.currentLocationModel.value;

    if (locationModel != null) {
      // Re-query with fresh location
      await fetchNearbyServices(_currentCategory);
    } else {
      isError.value = true;
      errorMessage.value = 'Failed to refresh location.';
      isLoading.value = false;
    }
  }

  String _getCollectionNameForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'taxi drivers':
      case 'transportation':
        return 'transports';
      case 'healthcare':
        return 'healthcare';
      // Fallbacks if stub collections are later created:
      case 'shops':
        return 'shops';
      case 'education':
        return 'education';
      case 'public services':
        return 'public_services';
      default:
        return '';
    }
  }

  void _categorizeHealthcareResults(List<NearbyServiceModel> results) {
    final Map<String, List<NearbyServiceModel>> sections = {
      'Hospitals': [],
      'Clinics': [],
      'Pharmacies': [],
      'Laboratories': [],
    };

    for (var service in results) {
      final prof = service.profession?.toLowerCase() ?? '';

      if (prof.contains('hospital')) {
        sections['Hospitals']!.add(service);
      } else if (prof.contains('clinic')) {
        sections['Clinics']!.add(service);
      } else if (prof.contains('pharmacy')) {
        sections['Pharmacies']!.add(service);
      } else if (prof.contains('laboratory') || prof.contains('lab')) {
        sections['Laboratories']!.add(service);
      }
    }

    // Only add sections that have data to avoid empty headers in UI
    sections.removeWhere((key, value) => value.isEmpty);

    categorizedResults.assignAll(sections);

    // Clear flat list so UI prefers categorized results if present
    if (sections.isNotEmpty) {
      services.clear();
    }
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get_storage/get_storage.dart';
import 'package:naattulink/MVVM/View/Authentication/force_update_screen.dart';
import 'package:naattulink/MVVM/View/Authentication/maintenance_screen.dart';

class AppConfigService extends GetxController with WidgetsBindingObserver {
  static AppConfigService get to => Get.find<AppConfigService>();

  final RxBool isMaintenanceMode = false.obs;
  final RxString maintenanceMessage = ''.obs;

  final RxBool isForceUpdateRequired = false.obs;
  final RxBool isOptionalUpdateAvailable = false.obs;

  final RxString installedVersion = ''.obs;
  final RxString minimumRequiredVersion = ''.obs;
  final RxString latestVersion = ''.obs;

  // Defaults
  final Map<String, dynamic> _defaults = {
    'latest_version_android': '',
    'latest_version_ios': '',
    'min_version_android': '',
    'min_version_ios': '',
    'android_review_version': '',
    'ios_review_version': '',
    'force_update_android': false,
    'force_update_ios': false,
    'optional_update_enabled_android': false,
    'optional_update_enabled_ios': false,
    'maintenance_mode': false,
    'maintenance_message':
        'We are currently undergoing maintenance. Please check back later.',
    'free_mode_enabled_android': false,
    'free_mode_enabled_ios': false,
    'show_prices_android': true,
    'show_prices_ios': true,
    'show_payment_methods_android': true,
    'show_payment_methods_ios': true,
    'play_store_url': '',
    'app_store_url': '',
  };

  Map<String, dynamic> _currentConfig = {};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _currentConfig = Map<String, dynamic>.from(_defaults);
    _loadCachedConfig();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-fetch config when app opens from background
      initialize().then((_) {
        if (isMaintenanceMode.value) {
          Get.offAll(() => const MaintenanceScreen());
        } else if (isForceUpdateRequired.value) {
          Get.offAll(() => const ForceUpdateScreen());
        }
      });
    }
  }

  void _loadCachedConfig() {
    final storage = GetStorage();
    final cached = storage.read('app_config');
    if (cached != null && cached is Map<String, dynamic>) {
      _currentConfig.addAll(cached);
    }
  }

  void _saveCachedConfig(Map<String, dynamic> config) {
    final storage = GetStorage();
    storage.write('app_config', config);
  }

  Future<void> initialize() async {
    try {
      // 5-second timeout for offline startup gracefully
      final docSnapshot = await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .get()
          .timeout(const Duration(seconds: 5));

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        _currentConfig.addAll(data);
        _saveCachedConfig(_currentConfig);
      }
    } catch (e) {
      debugPrint('Failed to fetch Firestore config: $e');
      // If offline or failed, fallback to cached values or defaults.
    }

    await _checkVersionAndConfig();
  }

  dynamic _getConfigValue(String key) {
    return _currentConfig[key] ?? _defaults[key];
  }

  Future<void> _checkVersionAndConfig() async {
    isMaintenanceMode.value =
        _getConfigValue('maintenance_mode') as bool? ?? false;
    maintenanceMessage.value =
        _getConfigValue('maintenance_message') as String? ??
            'We are currently undergoing maintenance.';

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    installedVersion.value = packageInfo.version;

    String currentPlatformLatestVersion = '1.0.0';
    String currentPlatformMinVersion = '1.0.0';
    bool forceUpdateEnabled = false;
    bool optionalUpdateEnabled = false;

    if (Platform.isIOS) {
      currentPlatformLatestVersion =
          _getConfigValue('latest_version_ios') as String? ?? '1.0.0';
      currentPlatformMinVersion =
          _getConfigValue('min_version_ios') as String? ?? '1.0.0';
      forceUpdateEnabled =
          _getConfigValue('force_update_ios') as bool? ?? false;
      optionalUpdateEnabled =
          _getConfigValue('optional_update_enabled_ios') as bool? ?? false;
    } else {
      currentPlatformLatestVersion =
          _getConfigValue('latest_version_android') as String? ?? '1.0.0';
      currentPlatformMinVersion =
          _getConfigValue('min_version_android') as String? ?? '1.0.0';
      forceUpdateEnabled =
          _getConfigValue('force_update_android') as bool? ?? false;
      optionalUpdateEnabled =
          _getConfigValue('optional_update_enabled_android') as bool? ?? false;
    }

    latestVersion.value = currentPlatformLatestVersion;
    minimumRequiredVersion.value = currentPlatformMinVersion;

    if (forceUpdateEnabled &&
        _compareVersions(installedVersion.value, currentPlatformMinVersion) <
            0) {
      isForceUpdateRequired.value = true;
    } else {
      isForceUpdateRequired.value = false;
      if (optionalUpdateEnabled &&
          _compareVersions(
                  installedVersion.value, currentPlatformLatestVersion) <
              0) {
        isOptionalUpdateAvailable.value = true;
      } else {
        isOptionalUpdateAvailable.value = false;
      }
    }

    String androidReviewVersion =
        _getConfigValue('android_review_version') as String? ?? '';
    String iosReviewVersion =
        _getConfigValue('ios_review_version') as String? ?? '';

    debugPrint("=== APP CONFIG SERVICE LOG ===");
    debugPrint("Installed Version: ${installedVersion.value}");
    debugPrint(
        "Latest Version: ${latestVersion.value} | Min Version: ${minimumRequiredVersion.value}");
    debugPrint("Force Update Required: ${isForceUpdateRequired.value}");
    debugPrint("Optional Update: ${isOptionalUpdateAvailable.value}");
    debugPrint("Maintenance Mode: ${isMaintenanceMode.value}");
    debugPrint("Maintenance Message: ${maintenanceMessage.value}");
    debugPrint(
        "Android Review Version: $androidReviewVersion | iOS Review Version: $iosReviewVersion");
    debugPrint(
        "Free Mode: $isFreeModeEnabled | Show Prices: $showPrices | Show Payments: $showPaymentMethods");
    debugPrint("===============================");
  }

  int _compareVersions(String version1, String version2) {
    List<int> v1Components =
        version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Components =
        version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int length = v1Components.length > v2Components.length
        ? v1Components.length
        : v2Components.length;

    for (int i = 0; i < length; i++) {
      int v1 = i < v1Components.length ? v1Components[i] : 0;
      int v2 = i < v2Components.length ? v2Components[i] : 0;

      if (v1 > v2) return 1;
      if (v1 < v2) return -1;
    }

    return 0;
  }

  bool get isFreeModeEnabled {
    return Platform.isIOS
        ? (_getConfigValue('free_mode_enabled_ios') as bool? ?? false)
        : (_getConfigValue('free_mode_enabled_android') as bool? ?? false);
  }

  bool get showPrices {
    return Platform.isIOS
        ? (_getConfigValue('show_prices_ios') as bool? ?? true)
        : (_getConfigValue('show_prices_android') as bool? ?? true);
  }

  bool get showPaymentMethods {
    return Platform.isIOS
        ? (_getConfigValue('show_payment_methods_ios') as bool? ?? true)
        : (_getConfigValue('show_payment_methods_android') as bool? ?? true);
  }

  String get storeUrl {
    return Platform.isIOS
        ? (_getConfigValue('app_store_url') as String? ??
            'https://apps.apple.com/app/id1234567890')
        : (_getConfigValue('play_store_url') as String? ??
            'https://play.google.com/store/apps/details?id=com.sadiqali.naattulink');
  }

  Future<void> launchStore() async {
    final url = Uri.parse(storeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Could not open the store.");
    }
  }
}

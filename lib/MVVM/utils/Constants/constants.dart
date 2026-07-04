import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

const String appName = 'Naattu Link';
const String appFullName = 'Naattu Link';

const String iosVersion = '1.0.0';
const String androidVersion = '1.0.0';

class LocalStorage {
  static final GetStorage _storage = GetStorage();

  static String getIosURL() {
    return _storage.read('ios_url') ?? 'https://apps.apple.com/app/id';
  }

  static String getAndroidURL() {
    return _storage.read('android_url') ?? 'https://play.google.com/store/apps/details?id=com.example.swiftclean_project';
  }
}

String shareDescription =
    'Let me recommend you $appName Application. \n\nDownload Now 👇\n\n📱 iOS :  ${LocalStorage.getIosURL()}  \n\n📱 Android : ${LocalStorage.getAndroidURL()} \n\n';

// Colors
const Color primaryColor = Color(0xFF4F8108); // Matches gradientgreen2
const Color primaryDarkColor = Color(0xFF387A02); // Matches gradientgreen1

// Font Families (matching pubspec.yaml)
const String fontMedium = 'Poppins-Medium';
const String fontSemiBold = 'Poppins-SemiBold';
const String fontRegular = 'poppins_regular';
const String fontBold = 'poppins_bold';
const String fontLight = 'poppins_light';

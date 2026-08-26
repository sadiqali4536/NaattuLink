import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:naattulink/MVVM/View/Authentication/SplashScreen.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/recommendation_controller.dart';
import 'package:naattulink/MVVM/Viewmodel/themes_bloc.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/common_controller.dart';
import 'package:naattulink/firebase_options.dart';
import 'package:naattulink/MVVM/model/services/notification_service.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_details_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/vehicles_auto_taxi_bookings/auto_taxi_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/education_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/public_services_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/transportation_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/shops_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/healthcare_bookings/healthcare_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/helpline_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/tuition_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/generic_listing_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/food_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/internet_cafe_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/pickup_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/jcbs_page.dart';

import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

late Size mq;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isAndroid) {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  HttpOverrides.global = MyHttpOverrides();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  await NotificationService.instance.initialize();
  await Hive.initFlutter();
  await Hive.openBox('saved_routes_box');

  // Register CommonController
  Get.put(CommonController(), permanent: true);

  // Register AuthController globally
  Get.put(AuthController(), permanent: true);

  // Register LocationController globally before the app starts
  Get.put(LocationController(), permanent: true);

  // Register RecommendationController globally
  Get.put(RecommendationController(), permanent: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return BlocProvider(
      create: (context) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(builder: (context, state) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NaattuLink',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: state.themeMode,
          home: SplashScreen(),
          getPages: [
            GetPage(
              name: '/service/:id',
              page: () {
                final args = Get.arguments as Map<String, dynamic>? ?? {};
                return ServiceDetailsPage(
                  serviceId: Get.parameters['id'],
                  category: args['category'] ?? '',
                  serviceName: args['serviceName'] ?? '',
                  rating: (args['rating'] ?? 0.0).toDouble(),
                  originalPrice: args['originalPrice'] ?? 0,
                  discount: args['discount'] ?? 0,
                  image: args['image'] ?? '',
                  discountPrice: args['discountPrice'] ?? 0,
                );
              },
            ),
            GetPage(name: '/auto-taxi', page: () => const AutoTaxiPage()),
            GetPage(name: '/education', page: () => const EducationCategoriesPage()),
            GetPage(name: '/public-services', page: () => const PublicServicesCategoriesPage()),
            GetPage(name: '/transportation', page: () => const TransportationCategoriesPage()),
            GetPage(name: '/shops', page: () => const ShopsCategoriesPage()),
            GetPage(name: '/healthcare', page: () => const HealthcareCategoriesPage()),
            GetPage(name: '/helpline', page: () => const HelplinePage()),
            GetPage(name: '/tuition', page: () => const TuitionPage()),
            GetPage(name: '/generic-listing', page: () => const GenericListingPage(title: "Listing")),
            GetPage(name: '/food', page: () => const FoodPage()),
            GetPage(name: '/internet-cafe', page: () => const InternetCafePage()),
            GetPage(name: '/pickup', page: () => const PickupPage()),
            GetPage(name: '/truck-jcb', page: () => const JcbsPage()),
          ],
          //  Bottomnvigationbar(),
          // ExteriorBookingpage(),
          // InteriorBookingPage(),
          //VehicleBookingPage(),
          //WorkerDashboard(),
          //PetCleaning()
          //  HomeBookingPage()
          //Registrationpage()
        );
      }),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:swiftclean_project/MVVM/View/Authentication/SplashScreen.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/controller/recommendation_controller.dart';
import 'package:swiftclean_project/MVVM/Viewmodel/themes_bloc.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/controller/common_controller.dart';
import 'package:swiftclean_project/firebase_options.dart';

late Size mq;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
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
          title: 'Naattu Link',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: state.themeMode,
          home: SplashScreen(),
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

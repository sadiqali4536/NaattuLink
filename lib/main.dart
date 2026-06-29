import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:swiftclean_project/MVVM/View/Authentication/SplashScreen.dart';
import 'package:swiftclean_project/MVVM/Viewmodel/themes_bloc.dart';
import 'package:swiftclean_project/firebase_options.dart';

late Size mq;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  bool isDarkMode = false;
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

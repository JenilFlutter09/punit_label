import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'apis/apiWrapper.dart';
import 'constants/colors.dart';
import 'features/internetChecker/internetCheckerController.dart';

import 'features/internetChecker/offlineBanner.dart';
import 'features/splash/splash.dart';
import 'navigation/appPages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return GetMaterialApp(
          builder: (context, child) {
            return Stack(
              children: [
                child!, // All your app screens
                const Align(
                  alignment: Alignment.bottomCenter,
                ),
              ],
            );
          },
          theme: ThemeData(
            fontFamily: "Montserrat",
            brightness: Brightness.light,
            textTheme: Typography.blackMountainView,
            useMaterial3: true,

            colorScheme: ColorScheme.fromSeed(
              seedColor: ColorsValue.primaryColor,
             // brightness: Brightness.light,
            ),
          ),themeMode: ThemeMode.light,
          getPages: AppPages.pages,
          debugShowCheckedModeBanner: false,
          home: SplashView(), // Only your routing starts here
        );
      },
    );
  }
}

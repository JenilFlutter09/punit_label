import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/splash/tryPrintPage.dart';
import '../../apis/sharedPreference.dart';
import '/constants/colors.dart';
import '/constants/sizes.dart';
import '/constants/styles.dart';
import '/navigation/appPages.dart';
import '/navigation/routesManagement.dart';

class SplashView extends StatelessWidget {
  SplashView({super.key});
  final controller = Get.put(SplashController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(
          color: ColorsValue.whiteColor,
        ),
        child: Column(
          children: [

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/splash-removebg-preview.png'),
                  ),
                ),
              ),
            ),
            // Expanded(
            //   flex: 3,
            //   child: Text(
            //     'Punit Industries\nPrivate Limited',
            //     style: Styles.primaryBold25,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
class SplashController extends GetxController{
  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }
  Future<void> checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        RouteManagement.goToDashboardScreen();
      } else {
        RouteManagement.goToLogin();
      }
    } catch (_) {
      await TokenStorage.clearAll();
      RouteManagement.goToLogin();
    }
  }

}
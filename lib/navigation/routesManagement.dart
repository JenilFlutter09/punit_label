
import 'package:get/get.dart';

import 'appPages.dart';

abstract class RouteManagement {
  static void goToDashboardScreen() {
    Get.offAllNamed<void>(Routes.dashBoardView);
  }


  static goToSplash() {
    Get.offAllNamed<void>(Routes.splashScreen);
  }

  static goToLogin(){
    Get.toNamed<void>(Routes.login);
  }
  static offToLogin(){
    Get.offAllNamed<void>(Routes.login);
  }
}

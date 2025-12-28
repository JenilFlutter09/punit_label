import 'package:get/get.dart';
import '../features/bluetooth/bluetoothView.dart';
import '../features/dashboard/dashboard.dart';
import '../features/login/login.dart';
import '../features/splash/splash.dart';

import '../features/splash/splash.dart';

part 'appRoutes.dart';

class AppPages {
  static var transitionDuration = const Duration(milliseconds: 300);

  static final pages = <GetPage<dynamic>>[
    GetPage<SplashView>(
      name: _Paths.splash,
      page: SplashView.new,
      transition: Transition.cupertino,
      transitionDuration: transitionDuration,
    ),
    GetPage<DashBoardView>(
      name: _Paths.dashboardview,
      page: DashBoardView.new,
      transition: Transition.cupertino,
      transitionDuration: transitionDuration,
    ),
    GetPage<LoginView>(
      name: _Paths.login,
      page: LoginView.new,
      transition: Transition.cupertino,
      transitionDuration: transitionDuration,
    ),
  ];
}

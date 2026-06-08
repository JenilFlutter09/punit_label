part of 'appPages.dart';

abstract class Routes {
  static const splashScreen = _Paths.splash;
  static const gameScreen = _Paths.game;
  static const blueTooth = _Paths.bluetooth;
  static const dashBoardView = _Paths.dashboardview;
  static const login = _Paths.login;
  static const settings = _Paths.settings;
}

abstract class _Paths {
  static const splash = '/SplashView';
  static const game = '/GameView';
  static const bluetooth = '/BluetoothView';
  static const dashboardview = '/DashBoardView';
  static const login = '/LoginView';
  static const settings = '/SettingsScreen';
}

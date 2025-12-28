// import 'package:elegant_mechanic/apis/sharedPreference.dart';
// import 'package:elegant_mechanic/features/dashboard/dashboardController.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart';
//
// import 'localNotification.dart';
//
// Future<void> requestNotificationPermissions() async {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//
//   NotificationSettings settings = await messaging.requestPermission(
//     alert: true,
//     announcement: false,
//     badge: true,
//     carPlay: false,
//     criticalAlert: false,
//     provisional: false,
//     sound: true,
//   );
//
//   print('User granted permission: ${settings.authorizationStatus}');
// }
//
// void setupMessageListeners() {
//   final dashboardController = Get.find<DashboardController>();
//   // When the app is in the foreground
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//     print('Got a message whilst in the foreground!');
//     if (message.notification != null) {
//       print('Message also contained a notification: ${message.notification}');
//       // Handle the notification (e.g., show a dialog, update UI)
//       showNotification(message);
//       String isLoggedIn = await TokenStorage.checkLoggedIn() ?? "";
//       if (isLoggedIn == 'true') {
//         dashboardController.fetchMechanicTasks();
//       }
//     }
//   });
//
//   // When the app is in the background (or terminated)
//   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
//     print('A new onMessageOpenedApp event was published!');
//     print('App resumed from background by notif');
//     String isLoggedIn = await TokenStorage.checkLoggedIn() ?? "";
//     if (isLoggedIn == 'true') {
//       dashboardController.fetchMechanicTasks();
//     }
//     // Handle the notification (e.g., navigate to a specific screen)
//   });
// }
//
// Future<void> handleInitialMessage() async {
//   RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
//
//   if (message != null) {
//     print("App launched from terminated state by a notification");
//     if (message.notification != null) {
//       print('Notification on cold start: ${message.notification}');
//     }
//
//     String isLoggedIn = await TokenStorage.checkLoggedIn() ?? "";
//     if (isLoggedIn == 'true') {
//       final dashboardController = Get.find<DashboardController>();
//       dashboardController.fetchMechanicTasks();
//     }
//   }
// }

import 'package:firebase_messaging/firebase_messaging.dart';

Future<String?> getFCMToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
  return token;
}

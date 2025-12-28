//
//
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();
//
// Future<void> initLocalNotifications() async {
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const InitializationSettings settings = InitializationSettings(
//     android: androidSettings,
//   );
//
//   await flutterLocalNotificationsPlugin.initialize(settings);
// }
//
// Future<void> showNotification(RemoteMessage message) async {
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'default_channel',
//     'Default',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//     autoCancel: true,
//     enableVibration: true,
//   );
//
//   const NotificationDetails platformDetails = NotificationDetails(
//     android: androidDetails,
//   );
//
//   await flutterLocalNotificationsPlugin.show(
//     message.notification.hashCode,
//     message.notification?.title,
//     message.notification?.body,
//     platformDetails,
//   );
// }

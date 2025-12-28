// import 'dart:convert';
//
// import '/apis/connectHelper.dart';
// import '/apis/sharedPreference.dart';
// import '/constants/colors.dart';
// import '/constants/sizes.dart';
// import '/constants/styles.dart';
// import '/features/qrCode/verifyModel.dart';
// import '/navigation/routesManagement.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class QRScanController extends GetxController with GetTickerProviderStateMixin {
//   final cameraController = MobileScannerController();
//   final scannedCode = ''.obs;
//   final isFrontCamera = false.obs;
//   final isScannerStarted = false.obs;
//   final connectHelper = ConnectHelper();
//   String empId = "0";
//   final isPermissionGranted = false.obs;
//
//   late AnimationController laserAnimationController;
//   late Animation<double> laserPosition;
//
//   bool _hasProcessedScan = false;
//
//   @override
//   void onInit() {
//     super.onInit();
//     cameraController.stop();
//     _checkCameraPermissionLoop();
//   }
//
//   Future<void> _checkCameraPermissionLoop() async {
//     while (true) {
//       final status = await Permission.camera.status;
//
//       if (status.isGranted) {
//         isPermissionGranted.value = true;
//         await _startScanner();
//         break;
//       } else if (status.isPermanentlyDenied) {
//         _showGoToSettingsDialog();
//         break;
//       } else {
//         final result = await Permission.camera.request();
//         if (result.isGranted) {
//           isPermissionGranted.value = true;
//           await _startScanner();
//           break;
//         }
//       }
//     }
//   }
//
//   Future<void> _startScanner() async {
//     if (!isScannerStarted.value) {
//       await cameraController.start();
//       isScannerStarted.value = true;
//       _setupLaserAnimation();
//     }
//   }
//
//   void _setupLaserAnimation() {
//     laserAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//
//     laserPosition = Tween<double>(begin: 0.1, end: 0.9).animate(
//       CurvedAnimation(
//         parent: laserAnimationController,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }
//
//   Future<void> onDetect(String value) async {
//     if (_hasProcessedScan || value.isEmpty) return;
//
//     _hasProcessedScan = true;
//     scannedCode.value = value;
//
//     // Get.snackbar('QR Code Scanned', value, snackPosition: SnackPosition.BOTTOM);
//
//     final isValid = await verifyMechanic(scannedValue: value);
//
//     if (isValid.isVerified == true) {
//       // await TokenStorage.saveUser(isValid.mechanicId.toString());
//       RouteManagement.goToDashboardScreen();
//     } else {
//       var message = isValid.message ?? 'Mechanic Not Verified';
//       Get.snackbar(
//         'Invalid Mechanic',
//         message,
//         titleText: Text(
//           'Please Scan Again...',
//           style: Styles.primary15.copyWith(color: Colors.white),
//         ),
//         messageText: Text(
//           message,
//           style: Styles.primary12.copyWith(color: Colors.white),
//         ),
//         snackPosition: SnackPosition.BOTTOM,
//         snackStyle: SnackStyle.GROUNDED,
//         backgroundColor: ColorsValue.primaryColor,
//         colorText: Colors.white,
//         icon: Icon(Icons.error, color: Colors.white),
//         margin: Dimens.edgeInsets0,
//       );
//     }
//
//     await Future.delayed(
//       const Duration(seconds: 2),
//     ); // Prevents re-triggering too fast
//     _hasProcessedScan = false;
//   }
//
//   /*Future<verifyModel> verifyMechanic({required String scannedValue}) async {
//     final result = await connectHelper.verifyMechanic(
//       scannedValue: scannedValue,
//     );
//     final verify = verifyModel.fromJson(jsonDecode(result.data));
//     if (verify.isVerified == true) {
//       empId = verify.mechanicId?.toString() ?? "0";
//       //await TokenStorage.saveUser(empId);
//       await TokenStorage.saveLoggedIn('true');
//       return verify;
//     }
//     return verify;
//   }
// */
//   void toggleCamera() async {
//     await cameraController.switchCamera();
//     isFrontCamera.toggle();
//   }
//
//   void _showGoToSettingsDialog() {
//     Get.defaultDialog(
//       title: "Permission Required",
//       middleText:
//           "Camera access is permanently denied. Please enable it from settings to scan QR codes.",
//       textConfirm: "Open Settings",
//       textCancel: "Exit",
//       confirmTextColor: Colors.white,
//       onConfirm: () async {
//         Get.back();
//         await openAppSettings();
//       },
//       onCancel: () {
//         Get.back();
//         Get.back(); // Exit the QRScanView
//       },
//     );
//   }
//
//   @override
//   void onClose() {
//     cameraController.dispose();
//     if (laserAnimationController.isCompleted ||
//         laserAnimationController.isAnimating) {
//       laserAnimationController.dispose();
//     }
//     isScannerStarted.value = false;
//     super.onClose();
//   }
// }

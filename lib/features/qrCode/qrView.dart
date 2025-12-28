// import '/apis/connectHelper.dart';
// import '/constants/colors.dart';
// import '/constants/sizes.dart';
// import '/features/qrCode/qrController.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// class QRScanView extends StatelessWidget {
//   QRScanView({super.key});
//   final connectHelper = ConnectHelper();
//   @override
//   Widget build(BuildContext context) {
//     final QRScanController controller = Get.put(QRScanController());
//
//     return WillPopScope(
//       onWillPop: () => connectHelper.showExitConfirmationDialog(context),
//       child: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: SystemUiOverlayStyle(
//           statusBarColor: ColorsValue.primaryColor,
//           statusBarIconBrightness: Brightness.light,
//           systemStatusBarContrastEnforced: false,
//         ),
//         child: Scaffold(
//           backgroundColor: Colors.black,
//           appBar: AppBar(
//             title: Text(
//               'Scan Your ID',
//               // style: GoogleFonts.roboto(
//               //   color: ColorsValue.whiteColor,
//               //   fontWeight: FontWeight.w500,
//               // ),
//             ),
//             centerTitle: true,
//             automaticallyImplyLeading: false,
//             backgroundColor: ColorsValue.primaryColor,
//             surfaceTintColor: ColorsValue.primaryColor,
//           ),
//           body: Obx(() {
//             if (!controller.isPermissionGranted.value) {
//               return const Center(
//                 child: Text(
//                   "Waiting for camera permission...",
//                   style: TextStyle(color: Colors.white70),
//                 ),
//               );
//             }
//
//             return Stack(
//               children: [
//                 // Camera view
//                 MobileScanner(
//                   controller: controller.cameraController,
//                   startDelay: true,
//                   errorBuilder:
//                       (_, error, __) => const Center(
//                         child: Text(
//                           "Camera error occurred",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                   onDetect: (capture) {
//                     controller.onDetect(capture.barcodes.first.rawValue ?? "");
//                   },
//                 ),
//
//                 // Overlay with transparent hole and corner borders
//                 Center(
//                   child: CustomPaint(
//                     size: Size(Get.width, Get.height),
//                     painter: HoleOverlayPainter(
//                       holeSize: Get.width * 0.7,
//                       borderRadius: Dimens.twentyFive,
//                     ),
//                   ),
//                 ),
//
//                 // Red laser animation
//                 Obx(() {
//                   if (controller.isScannerStarted.value &&
//                       controller.laserAnimationController.isAnimating) {
//                     return AnimatedBuilder(
//                       animation: controller.laserAnimationController,
//                       builder: (_, __) {
//                         final double topPosition =
//                             (Get.height / 2.25 - Get.width * 0.35) +
//                             (controller.laserPosition.value * Get.width * 0.7);
//
//                         return Positioned(
//                           top: topPosition,
//                           left: Get.width * 0.15,
//                           child: Container(
//                             width: Get.width * 0.7,
//                             height: 2,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.white.withOpacity(0.6),
//                                   blurRadius: 8,
//                                   spreadRadius: 1,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }
//                   return const SizedBox.shrink();
//                 }),
//
//                 // Instructions
//                 Positioned(
//                   top: Dimens.hundred,
//                   left: 0,
//                   right: 0,
//                   child: Text(
//                     "Place the QR inside the frame to scan",
//                     textAlign: TextAlign.center,
//                     // style: GoogleFonts.roboto(
//                     //   fontSize: 20,
//                     //   color: Colors.white,
//                     // ),
//                   ),
//                 ),
//               ],
//             );
//           }),
//           floatingActionButton: FloatingActionButton(
//             onPressed: controller.toggleCamera,
//             backgroundColor: ColorsValue.primaryColor,
//             child: const Icon(Icons.cameraswitch, color: Colors.white),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class HoleOverlayPainter extends CustomPainter {
//   final double holeSize;
//   final double borderRadius;
//
//   HoleOverlayPainter({required this.holeSize, required this.borderRadius});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint =
//         Paint()
//           ..color = Colors.black.withOpacity(0.5)
//           ..style = PaintingStyle.fill;
//
//     final background =
//         Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
//
//     final holeRect = Rect.fromCenter(
//       center: Offset(size.width / 2, size.height / 2),
//       width: holeSize,
//       height: holeSize,
//     );
//
//     final hole =
//         Path()..addRRect(
//           RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)),
//         );
//
//     final finalPath = Path.combine(PathOperation.difference, background, hole);
//
//     canvas.drawPath(finalPath, paint);
//
//     // Draw white corner border
//     //final cornerPainter = _FramePainter();
//     //cornerPainter.paint(canvas, Size(holeSize, holeSize));
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
//
// class _FramePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     const borderLength = 30.0;
//     const borderWidth = 4.0;
//     final paint =
//         Paint()
//           ..color = Colors.white
//           ..strokeWidth = borderWidth
//           ..style = PaintingStyle.stroke;
//
//     // Top-left
//     canvas.drawLine(Offset(0, 0), Offset(borderLength, 0), paint);
//     canvas.drawLine(Offset(0, 0), Offset(0, borderLength), paint);
//
//     // Top-right
//     canvas.drawLine(
//       Offset(size.width, 0),
//       Offset(size.width - borderLength, 0),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(size.width, 0),
//       Offset(size.width, borderLength),
//       paint,
//     );
//
//     // Bottom-left
//     canvas.drawLine(
//       Offset(0, size.height),
//       Offset(0, size.height - borderLength),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(0, size.height),
//       Offset(borderLength, size.height),
//       paint,
//     );
//
//     // Bottom-right
//     canvas.drawLine(
//       Offset(size.width, size.height),
//       Offset(size.width - borderLength, size.height),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(size.width, size.height),
//       Offset(size.width, size.height - borderLength),
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

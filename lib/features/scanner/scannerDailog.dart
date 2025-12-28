
import'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../constants/colors.dart';
import 'barcodeController.dart';
import 'package:get/get.dart';

import 'barcodeScanner.dart';
Future<String?> showBarcodeScannerDialog(BuildContext context) async {
  String? scannedCode;

  await Get.dialog(
    Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 320,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Scanner View
                MobileScanner(
                  //controller: controller.scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null && scannedCode == null) {
                        scannedCode = code;
                        Get.back(result: code);
                      }
                    }
                  },
                ),

                // Overlay + laser
                const BarcodeOverlayDialog(),

                // Cancel button
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                      label: const Text("Cancel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: false,
    useSafeArea: false,
  );

  return scannedCode;
}

class BarcodeOverlayDialog extends StatefulWidget {
  const BarcodeOverlayDialog({super.key});

  @override
  State<BarcodeOverlayDialog> createState() => _BarcodeOverlayDialogState();
}

class _BarcodeOverlayDialogState extends State<BarcodeOverlayDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = 320.0; // match dialog height
    final width = MediaQuery.of(context).size.width * 0.9;

    // Define cutout area relative to dialog container
    final cutOutWidth = width * 0.90;
    const cutOutHeight = 180.0;

    final centerY = containerSize / 2 - 20; // center the window nicely

    final cutOutRect = Rect.fromCenter(
      center: Offset(width / 2, centerY),
      width: cutOutWidth,
      height: cutOutHeight,
    );

    return Stack(
      children: [
        // Dark overlay with transparent scanner window
        Container(
          width: width,
          height: containerSize,
          decoration: ShapeDecoration(
            shape: BarcodeScannerOverlay(
              borderColor: ColorsValue.primaryColor,
              cutOutWidth: cutOutWidth,
              cutOutHeight: cutOutHeight,
            ),
          ),
        ),

        // Laser line animation (moves inside the cutout)
        AnimatedBuilder(
          animation: _laserController,
          builder: (_, __) {
            final yPos =
                cutOutRect.top + (cutOutRect.height * _laserController.value);
            return Positioned(
              left: cutOutRect.left,
              width: cutOutRect.width,
              top: yPos + 20,
              child: Container(
                height: 2,
                color: Colors.white.withOpacity(0.8),
              ),
            );
          },
        ),
      ],
    );
  }
}

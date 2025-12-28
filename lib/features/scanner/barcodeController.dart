import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../constants/utility.dart';

class BarcodeController extends GetxController {
  var scannedCode = RxnString();
  var isScanning = true.obs;

  /// Handle detection from MobileScanner
  void onDetect(BarcodeCapture capture) {
    if (!isScanning.value) return; // prevent multiple triggers

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        scannedCode.value = code;
        isScanning.value = false;

        Utility.showDialog("Scanned: $code");

        // Auto-reset after 2 sec to allow next scan
        Future.delayed(const Duration(seconds: 2), () {
          reset();
        });
        break;
      }
    }
  }

  void reset() {
    scannedCode.value = null;
    isScanning.value = true;
  }
}

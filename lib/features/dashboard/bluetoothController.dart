import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
class BluetoothController extends GetxController {
  RxList<ScanResult> devices = <ScanResult>[].obs;
  RxBool isScanning = false.obs;
  RxBool isConnected = false.obs;
  RxnString connectingDeviceId = RxnString();
  RxInt selectedPaperSize = 80.obs; // default 80mm

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSub;

  /// 1️⃣ Scan Devices
  Future<void> scanDevices() async {
    if (!(await FlutterBluePlus.isSupported)) {
      Get.snackbar("Error", "Bluetooth not supported");
      return;
    }

    devices.clear();

    isScanning.value = true;

    // Listen to scan results
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      devices.value = results;
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      androidScanMode: AndroidScanMode.lowLatency,
    );

    await Future.delayed(const Duration(seconds: 5));

    isScanning.value = false;
    await FlutterBluePlus.stopScan();
  }

  String formatRow(String left, String right, int totalWidth) {
    final space = totalWidth - left.length - right.length;
    if (space <= 0) return "$left $right";
    return left + (" " * space) + right;
  }


  /*Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connectingDeviceId.value = device.remoteId.str;

      await device.connect(autoConnect: false);
      connectedDevice = device;

      final services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            break;
          }
        }
      }

      isConnected.value = true;
      connectingDeviceId.value = null;

      Get.snackbar("Connected", device.platformName);

    } catch (e) {
      connectingDeviceId.value = null;
      Get.snackbar("Error", e.toString());
    }
  }
*/

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connectingDeviceId.value = device.remoteId.str;

      await Future.delayed(Duration(milliseconds: 50));
      // Let UI rebuild and show loader

      await device.connect(autoConnect: false);

      connectedDevice = device;
      final services = await device.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            break;
          }
        }
      }

      isConnected.value = true;
      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }
      Get.snackbar("Connected", device.platformName);
      await _showPaperSizeSelector();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      connectingDeviceId.value = null;
    }
  }
  Future<void> _showPaperSizeSelector() async {
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Paper Size",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            RadioListTile<int>(
              value: 58,
              groupValue: selectedPaperSize.value,
              title: const Text("2 Inch (58mm)"),
              onChanged: (val) {
                selectedPaperSize.value = val!;
              },
            ),

            RadioListTile<int>(
              value: 80,
              groupValue: selectedPaperSize.value,
              title: const Text("3 Inch (80mm)"),
              onChanged: (val) {
                selectedPaperSize.value = val!;
              },
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                Get.back();
              },
              child: const Text("Confirm"),
            ),
          ],
        )),
      ),
      isDismissible: false,
    );
  }

  Future<void> printReceipt({
    required String companyName,
    required List<String?> companyContact,
    required List<Map<String, dynamic>> items,
    required String barcodeData,
   // required int paperSize, // 58 or 80
  }) async
  {
    if (writeCharacteristic == null) {
      Get.snackbar("Error", "Printer not connected");
      return;
    }
    final now = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy  HH:mm').format(now);

    final int paperSize = selectedPaperSize.value;
    final int lineWidth = paperSize == 80 ? 48 : 32;

    List<int> bytes = [];

    bytes += [27, 64]; // init
    bytes += [27, 97, 1]; // center

   // bytes += utf8.encode("$companyName\n");
    for (final line in wrapText(companyName, lineWidth)) {
      bytes += utf8.encode(line + "\n");
    }

    for(var item in companyContact)
      {
        if (item == null) continue;
        for (final line in wrapText(item, lineWidth)) {
          bytes += utf8.encode(line + "\n");
        }
      }
    bytes += utf8.encode("\n");
    bytes += [27, 97, 0];
    bytes += utf8.encode(formatRow("Date", formattedDate, lineWidth) + "\n");

    bytes += utf8.encode("-" * lineWidth + "\n");

    //bytes += [27, 97, 0]; // left

    bytes += utf8.encode(formatRow("Attribute", "Value", lineWidth) + "\n");
    bytes += utf8.encode("-" * lineWidth + "\n");

    for (var item in items) {
      bytes += utf8.encode(
        formatRow(
          item['key'].toString(),
          item['value'].toString(),
          lineWidth,
        ) +
            "\n",
      );
    }

    bytes += utf8.encode("-" * lineWidth + "\n");

    /// BARCODE
    bytes += [27, 97, 1];
    bytes += [29, 104, 100];
    bytes += [29, 119, paperSize == 80 ? 3 : 2];
    bytes += [29, 72, 2];

    bytes += [29, 107, 73, barcodeData.length];
    bytes += utf8.encode(barcodeData);

    bytes += [27, 100, 6]; // feed
    bytes += [29, 86, 66, 0]; // cut

    await _writeInChunks(bytes);
  }

  Future<void> _writeInChunks(List<int> bytes) async {
    if (writeCharacteristic == null) return;

    const int chunkSize = 180; // safe for BLE

    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end =
      (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;

      final chunk = bytes.sublist(i, end);

      await writeCharacteristic!.write(
        chunk,
        withoutResponse:
        writeCharacteristic!.properties.writeWithoutResponse,
      );

      // small delay for printer buffer stability
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  void openDeviceBottomSheet() {
    Get.bottomSheet(
      Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Text(
              "Select Bluetooth Device",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Obx(() {
                if (isScanning.value && devices.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (devices.isEmpty) {
                  return const Center(child: Text("No Devices Found"));
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index].device;
                    final isConnectingNow =
                        connectingDeviceId.value == device.remoteId.str;

                    return ListTile(
                      title: Text(
                        device.platformName.isEmpty
                            ? "Unknown Device"
                            : device.platformName,
                      ),
                      subtitle: Text(device.remoteId.str),

                      trailing: isConnectingNow
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : ElevatedButton(
                        onPressed: () => connectToDevice(device),
                        child: const Text("Connect"),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );

    // Start scanning AFTER sheet opens
    scanDevices();
  }

  List<String> wrapText(String text, int maxWidth) {
    List<String> lines = [];
    while (text.length > maxWidth) {
      lines.add(text.substring(0, maxWidth));
      text = text.substring(maxWidth);
    }
    lines.add(text);
    return lines;
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      isConnected.value = false;
    }
  }

  @override
  void onClose() {
    _scanSub?.cancel();
    super.onClose();
  }
}

// ble/ble_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../apis/bluetooth_device_store.dart';
import '../constants/bluetooth_device_display.dart';
import '../constants/enums.dart';
import '../constants/strings.dart';

String buildPayload(WeightStatus status) {
  return jsonEncode({"status": status == WeightStatus.inRange ? "0" : "1"});
}

class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;

  Future<void> startScan({
    required Function(ScanResult) onResult,
    required Function() onDone,
  }) async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        onResult(r);
      }
    });

    Future.delayed(const Duration(seconds: 5), () async {
      await FlutterBluePlus.stopScan();
      onDone();
    });
  }

  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    await _device!.connect(autoConnect: false);

    final services = await _device!.discoverServices();
    for (final service in services) {
      if (service.uuid.toString() == BleConstants.serviceUUID) {
        for (final c in service.characteristics) {
          if (c.uuid.toString() == BleConstants.characteristicUUID) {
            _writeChar = c;
            return;
          }
        }
      }
    }
    throw Exception("Write characteristic not found");
  }

  Future<void> write(String payload) async {
    if (_writeChar == null) return;

    await _writeChar!.write(payload.codeUnits, withoutResponse: true);
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
  }
}

class TowerLightController extends GetxController {
  final BleService _ble = BleService();

  // UI state
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxString connectingDeviceId = ''.obs;

  // BLE scan results
  final RxList<ScanResult> scanResults = <ScanResult>[].obs;

  // Business state (ONLY thing that matters)
  final Rx<WeightStatus?> currentStatus = Rx<WeightStatus?>(null);

  /// 🔍 Scan when bottom sheet opens
  Future<void> startScan() async {
    scanResults.clear();
    isScanning.value = true;

    await _ble.startScan(
      onResult: (result) {
        final exists = scanResults.any(
          (r) =>
              BluetoothDeviceDisplay.deviceIdFromResult(r) ==
              BluetoothDeviceDisplay.deviceIdFromResult(result),
        );
        if (!exists) {
          scanResults.add(result);
        }
      },
      onDone: () {
        isScanning.value = false;
      },
    );
  }

  /// 🔗 Connect to selected tower light
  Future<void> connectToDevice(ScanResult result) async {
    await connectToDeviceWithOptions(
      result,
      closeBottomSheetOnSuccess: true,
      showErrorSnackbar: true,
    );
  }

  Future<void> connectToDeviceWithOptions(
    ScanResult result, {
    required bool closeBottomSheetOnSuccess,
    required bool showErrorSnackbar,
  }) async {
    connectingDeviceId.value = BluetoothDeviceDisplay.deviceIdFromResult(
      result,
    );

    try {
      await _ble.connect(result.device);
      isConnected.value = true;
      await BluetoothDeviceStore.saveDevice(
        BluetoothDeviceStore.towerLightKey,
        BluetoothDeviceDisplay.deviceIdFromResult(result),
      );
      if (closeBottomSheetOnSuccess && (Get.isBottomSheetOpen ?? false)) {
        Get.back(); // close sheet on success
      }
    } catch (e) {
      if (showErrorSnackbar) {
        Get.snackbar('Connection Failed', e.toString());
      }
    } finally {
      connectingDeviceId.value = '';
    }
  }

  Future<void> tryAutoReconnectFromSaved() async {
    if (isConnected.value) return;

    final savedDeviceId = await BluetoothDeviceStore.getDevice(
      BluetoothDeviceStore.towerLightKey,
    );
    if (savedDeviceId == null || savedDeviceId.isEmpty) return;

    await startScan();

    ScanResult? matched;
    for (final result in scanResults) {
      if (BluetoothDeviceDisplay.deviceIdFromResult(result) == savedDeviceId) {
        matched = result;
        break;
      }
    }

    if (matched == null) return;

    await connectToDeviceWithOptions(
      matched,
      closeBottomSheetOnSuccess: false,
      showErrorSnackbar: false,
    );
  }

  /// ⚖️ THIS is what your weighing logic should call
  Future<void> updateWeightStatus(WeightStatus newStatus) async {
    if (!isConnected.value) return;

    // Send ONLY if status changes (PDF requirement)
    if (currentStatus.value == newStatus) return;

    final payload = buildPayload(newStatus);
    await _ble.write(payload);

    currentStatus.value = newStatus;
  }

  Future<void> disconnect() async {
    await _ble.disconnect();
    isConnected.value = false;
    connectingDeviceId.value = '';
    await BluetoothDeviceStore.clearDevice(BluetoothDeviceStore.towerLightKey);
  }

  @override
  void onClose() {
    _ble.disconnect();
    super.onClose();
  }
}

Future<void> showTowerLightSheet(
  BuildContext context,
  TowerLightController controller,
) async {
  await controller.startScan();

  Get.bottomSheet(
    Container(
      height: Get.height / 2,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Obx(
        () => Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const Text(
              "Nearby Tower Lights",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (!controller.isScanning.value && controller.scanResults.isEmpty)
              Column(
                children: [
                  const Text(
                    "No devices found\nMake sure Bluetooth is ON",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.startScan,
                    child: const Text("Re-Scan"),
                  ),
                ],
              ),

            Flexible(
              child: ListView.separated(
                itemCount: controller.scanResults.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final result = controller.scanResults[i];
                  final deviceName = BluetoothDeviceDisplay.displayName(result);
                  final deviceId = BluetoothDeviceDisplay.deviceIdFromResult(
                    result,
                  );

                  return ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(deviceName),
                    subtitle: Text(deviceId),
                    trailing: Obx(() {
                      if (controller.connectingDeviceId.value == deviceId) {
                        return const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      return ElevatedButton(
                        onPressed: () => controller.connectToDevice(result),
                        child: const Text("Connect"),
                      );
                    }),
                  );
                },
              ),
            ),

            if (controller.isScanning.value)
              Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

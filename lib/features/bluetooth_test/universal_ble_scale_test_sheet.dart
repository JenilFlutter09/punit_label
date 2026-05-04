import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_ble/universal_ble.dart';

import '../../apis/bluetooth_device_store.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../constants/styles.dart';
import '../dashboard/dashboardController.dart';

class UniversalBleScaleTestController extends GetxController {
  static const String savedDeviceKey = 'universal_ble_scale_test';

  final RxList<BleDevice> devices = <BleDevice>[].obs;
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxnString connectingDeviceId = RxnString();
  final RxnString connectedDeviceId = RxnString();
  final RxString statusMessage = ''.obs;

  final Map<String, BleDevice> _deviceMap = {};
  StreamSubscription<BleDevice>? _scanSub;
  StreamSubscription<Uint8List>? _valueSub;
  BleCharacteristic? _activeCharacteristic;
  BleDevice? _activeDevice;

  static UniversalBleScaleTestController ensureRegistered() {
    if (Get.isRegistered<UniversalBleScaleTestController>()) {
      return Get.find<UniversalBleScaleTestController>();
    }
    return Get.put(UniversalBleScaleTestController(), permanent: true);
  }

  Future<void> prepareBle() async {
    UniversalBle.timeout = const Duration(seconds: 12);
    await UniversalBle.requestPermissions(withAndroidFineLocation: false);

    final availability = await UniversalBle.getBluetoothAvailabilityState();
    if (availability != AvailabilityState.poweredOn) {
      throw Exception('Bluetooth is off.');
    }
  }

  Future<void> scanDevices() async {
    try {
      await prepareBle();
    } catch (e) {
      isScanning.value = false;
      statusMessage.value = '';
      Get.snackbar(
        'Scan Failed',
        _userFacingReason(e, fallback: 'Unable to scan.'),
      );
      return;
    }

    await _scanSub?.cancel();
    await UniversalBle.stopScan();
    _deviceMap.clear();
    devices.clear();
    isScanning.value = true;
    statusMessage.value = '';

    _scanSub = UniversalBle.scanStream.listen((device) {
      _deviceMap[device.deviceId] = device;
      final sorted = _deviceMap.values.toList()
        ..sort((a, b) {
          final aName = _displayName(a).toLowerCase();
          final bName = _displayName(b).toLowerCase();
          return aName.compareTo(bName);
        });
      devices.assignAll(sorted);
    });

    try {
      await UniversalBle.startScan(
        platformConfig: PlatformConfig(
          android: AndroidOptions(requestLocationPermission: false),
        ),
      );
    } catch (e) {
      isScanning.value = false;
      statusMessage.value = '';
      Get.snackbar(
        'Scan Failed',
        _userFacingReason(e, fallback: 'Unable to scan.'),
      );
    }
  }

  Future<void> connect(
    BleDevice device,
    DashboardController dashboardController,
  ) async {
    try {
      await prepareBle();
    } catch (e) {
      Get.snackbar(
        'Connection Failed',
        _userFacingReason(e, fallback: 'Unable to connect to the scale.'),
      );
      return;
    }

    connectingDeviceId.value = device.deviceId;
    statusMessage.value = '';

    try {
      await UniversalBle.stopScan();
      isScanning.value = false;
      await _teardownSubscription();
      await _disconnectActiveSilently();

      await device.connect(timeout: const Duration(seconds: 12));
      _activeDevice = device;

      final services = await device.discoverServices(
        timeout: const Duration(seconds: 12),
      );
      final selected = _selectCharacteristic(services);

      if (selected == null) {
        _logDiscoveredServices(device, services);
        throw Exception('No compatible scale characteristic found.');
      }

      _activeCharacteristic = selected;
      _valueSub = selected.onValueReceived.listen(
        (value) => _syncScaleData(value, dashboardController),
      );

      if (selected.notifications.isSupported) {
        await selected.notifications.subscribe();
      } else if (selected.indications.isSupported) {
        await selected.indications.subscribe();
      } else if (_supportsRead(selected)) {
        final initialValue = await selected.read(
          timeout: const Duration(seconds: 8),
        );
        _syncScaleData(initialValue, dashboardController);
      } else {
        _logDiscoveredServices(device, services);
        throw Exception('No compatible scale characteristic found.');
      }

      isConnected.value = true;
      connectedDeviceId.value = device.deviceId;
      dashboardController.isWeightScaleConnected.value = true;
      dashboardController.isUniversalBleScaleConnected.value = true;

      await BluetoothDeviceStore.saveDevice(savedDeviceKey, device.deviceId);
    } catch (e) {
      await _disconnectActiveSilently();
      dashboardController.isWeightScaleConnected.value = false;
      dashboardController.isUniversalBleScaleConnected.value = false;
      dashboardController.receivedData.value = '';
      statusMessage.value = '';
      Get.snackbar(
        'Connection Failed',
        _userFacingReason(e, fallback: 'Unable to connect to the scale.'),
      );
    } finally {
      connectingDeviceId.value = null;
    }
  }

  BleCharacteristic? _selectCharacteristic(List<BleService> services) {
    BleCharacteristic? firstReadable;

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.notifications.isSupported ||
            characteristic.indications.isSupported) {
          return characteristic;
        }
        firstReadable ??= _supportsRead(characteristic) ? characteristic : null;
      }
    }

    return firstReadable;
  }

  bool _supportsRead(BleCharacteristic characteristic) {
    return characteristic.properties.any((property) => property.name == 'read');
  }

  void _syncScaleData(
    Uint8List bytes,
    DashboardController dashboardController,
  ) {
    final raw = String.fromCharCodes(bytes);
    dashboardController.receivedData.value = raw;

    final weight = dashboardController.parseWeight(raw);
    if (weight == null) return;

    final formatted = weight.toStringAsFixed(2);
    dashboardController.manualBatchWeights.manualGross.value = formatted;
    dashboardController.manualBatchWeights.calculateManualNet();
    dashboardController.manualNonBatchWeights.manualGross.value = formatted;
    dashboardController.manualNonBatchWeights.calculateManualNet();
    dashboardController.manualTareWeights.manualGross.value = formatted;
  }

  Future<void> disconnect(
    DashboardController dashboardController, {
    bool clearSavedDevice = true,
    bool showSnackbar = true,
  }) async {
    await _disconnectActiveSilently();

    dashboardController.isWeightScaleConnected.value = false;
    dashboardController.isUniversalBleScaleConnected.value = false;
    dashboardController.receivedData.value = '';

    if (clearSavedDevice) {
      await BluetoothDeviceStore.clearDevice(savedDeviceKey);
    }

    if (showSnackbar) {
      Get.snackbar('Scale', 'Disconnected');
    }
  }

  Future<void> _disconnectActiveSilently() async {
    await _teardownSubscription();

    final deviceId = _activeDevice?.deviceId ?? connectedDeviceId.value;
    if (deviceId != null) {
      try {
        await UniversalBle.disconnect(
          deviceId,
          timeout: const Duration(seconds: 8),
        );
      } catch (_) {}
    }

    _activeDevice = null;
    _activeCharacteristic = null;
    isConnected.value = false;
    connectedDeviceId.value = null;
  }

  Future<void> _teardownSubscription() async {
    await _valueSub?.cancel();
    _valueSub = null;

    if (_activeCharacteristic != null) {
      try {
        await _activeCharacteristic!.unsubscribe(
          timeout: const Duration(seconds: 5),
        );
      } catch (_) {}
    }
  }

  void _logDiscoveredServices(BleDevice device, List<BleService> services) {
    final buffer = StringBuffer(
      'No scale characteristic for ${device.deviceId}',
    );
    for (final service in services) {
      buffer.write('\nService ${service.uuid}');
      for (final characteristic in service.characteristics) {
        final props = characteristic.properties.map((e) => e.name).join(', ');
        buffer.write('\n - ${characteristic.uuid} [$props]');
      }
    }
    debugPrint(buffer.toString());
  }

  String _displayName(BleDevice device) {
    final name = (device.name ?? '').trim();
    if (name.isNotEmpty) return name;

    final suffix = device.deviceId.length > 5
        ? device.deviceId.substring(device.deviceId.length - 5)
        : device.deviceId;
    return 'Unknown Device ($suffix)';
  }

  String _userFacingReason(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    final cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^ConnectionException:\s*'), '')
        .replaceFirst(RegExp(r'^UniversalBleException:\s*'), '')
        .replaceFirst(RegExp(r'^PlatformException\([^,]+,\s*'), '')
        .replaceFirst(RegExp(r',\s*null,\s*null\)$'), '')
        .trim();

    final lower = cleaned.toLowerCase();
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'Timed out while connecting.';
    }

    if (cleaned.isEmpty) {
      return fallback;
    }

    if (cleaned.length > 80) {
      return fallback;
    }

    return cleaned;
  }

  @override
  void onClose() {
    _scanSub?.cancel();
    _valueSub?.cancel();
    UniversalBle.stopScan();
    super.onClose();
  }
}

Future<void> showUniversalBleScaleTestSheet(
  BuildContext context,
  DashboardController dashboardController,
) async {
  final controller = UniversalBleScaleTestController.ensureRegistered();
  await controller.scanDevices();

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
          mainAxisSize: MainAxisSize.min,
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
            Text(
              "Nearby Devices",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "BLE scale test flow",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!controller.isScanning.value && controller.devices.isEmpty)
              Column(
                children: [
                  const Text(
                    "No devices found \n Check if Bluetooth is on and the scale is nearby",
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight20,
                  ElevatedButton(
                    onPressed: controller.scanDevices,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        ColorsValue.primaryColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, color: Colors.white),
                        Dimens.boxWidth8,
                        const Text(
                          'Re-Scan',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.devices.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final device = controller.devices[i];
                  final deviceId = device.deviceId;
                  final isConnectingNow =
                      controller.connectingDeviceId.value == deviceId;
                  final isConnectedNow =
                      controller.connectedDeviceId.value == deviceId &&
                      controller.isConnected.value;

                  return ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(controller._displayName(device)),
                    subtitle: Text(deviceId),
                    trailing: isConnectingNow
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              if (isConnectedNow) {
                                await controller.disconnect(
                                  dashboardController,
                                );
                                return;
                              }

                              await controller.connect(
                                device,
                                dashboardController,
                              );
                              if (controller.connectedDeviceId.value ==
                                      deviceId &&
                                  (Get.isBottomSheetOpen ?? false)) {
                                Get.back();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isConnectedNow
                                  ? ColorsValue.primaryColor
                                  : Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isConnectedNow ? "Disconnect" : "Connect",
                              style: Styles.primary14.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
            if (controller.isScanning.value) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

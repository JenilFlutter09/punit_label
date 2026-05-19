import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart'
    as classic;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../apis/bluetooth_device_store.dart';
import '../constants/enums.dart';

String buildPayload(WeightStatus status) {
  return status == WeightStatus.inRange ? "0" : "1";
}

class TowerLightController extends GetxController {
  final classic.FlutterBluetoothClassic _bluetooth =
      classic.FlutterBluetoothClassic();

  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxnString connectingAddress = RxnString();
  final RxnString connectedAddress = RxnString();
  final RxList<classic.BluetoothDevice> devices =
      <classic.BluetoothDevice>[].obs;
  final Rx<WeightStatus?> currentStatus = Rx<WeightStatus?>(null);

  StreamSubscription<classic.BluetoothConnectionState>? _connectionSub;
  StreamSubscription<classic.BluetoothState>? _stateSub;
  StreamSubscription<classic.BluetoothDevice>? _discoverySub;
  final Map<String, classic.BluetoothDevice> _deviceMap = {};

  @override
  void onInit() {
    super.onInit();
    _ensureListeners();
  }

  Future<void> _ensureListeners() async {
    _connectionSub ??= _bluetooth.onConnectionChanged.listen((state) {
      final connected = state.isConnected;
      isConnected.value = connected;
      connectedAddress.value = connected ? state.deviceAddress : null;

      if (!connected) {
        currentStatus.value = null;
        connectingAddress.value = null;
      }
    });

    _stateSub ??= _bluetooth.onStateChanged.listen((state) {
      if (!state.isEnabled) {
        isScanning.value = false;
        isConnected.value = false;
        connectedAddress.value = null;
        currentStatus.value = null;
      }
    });
  }

  Future<void> prepareBluetooth() async {
    await _ensureListeners();

    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        throw Exception(
          '${permission.toString().split(".").last} permission is required.',
        );
      }
    }

    final supported = await _bluetooth.isBluetoothSupported();
    if (!supported) {
      throw Exception('Bluetooth is not supported.');
    }

    var enabled = await _bluetooth.isBluetoothEnabled();
    if (!enabled) {
      enabled = await _bluetooth.enableBluetooth();
    }

    if (!enabled) {
      throw Exception('Bluetooth is off.');
    }
  }

  Future<void> startScan() async {
    await prepareBluetooth();

    devices.clear();
    _deviceMap.clear();
    isScanning.value = true;

    final pairedDevices = await _bluetooth.getPairedDevices();
    for (final device in pairedDevices) {
      _deviceMap[device.address] = device;
    }
    _publishDevices();

    await _discoverySub?.cancel();

    try {
      final discoveryStarted = await _bluetooth.startDiscovery();
      if (!discoveryStarted) {
        isScanning.value = false;
        return;
      }

      _discoverySub = _bluetooth.onDeviceDiscovered.listen((device) {
        _deviceMap[device.address] = device;
        _publishDevices();
      });

      await Future.delayed(const Duration(seconds: 5));
    } finally {
      try {
        await _bluetooth.stopDiscovery();
      } catch (_) {}
      isScanning.value = false;
    }
  }

  Future<void> connectToDevice(classic.BluetoothDevice device) async {
    await connectToDeviceWithOptions(
      device,
      closeBottomSheetOnSuccess: true,
      showErrorSnackbar: true,
    );
  }

  Future<void> connectToDeviceWithOptions(
    classic.BluetoothDevice device, {
    required bool closeBottomSheetOnSuccess,
    required bool showErrorSnackbar,
  }) async {
    try {
      await prepareBluetooth();
    } catch (e) {
      if (showErrorSnackbar) {
        Get.snackbar(
          'Connection Failed',
          _userFacingReason(
            e,
            fallback: 'Unable to prepare Bluetooth for tower light.',
          ),
        );
      }
      return;
    }

    connectingAddress.value = device.address;

    try {
      await _bluetooth.stopDiscovery();
    } catch (_) {}
    isScanning.value = false;

    try {
      final connected = await _bluetooth.connect(device.address);
      if (!connected) {
        throw Exception('Device rejected the connection.');
      }

      isConnected.value = true;
      connectedAddress.value = device.address;
      currentStatus.value = null;

      await BluetoothDeviceStore.saveDevice(
        BluetoothDeviceStore.towerLightKey,
        device.address,
      );

      if (closeBottomSheetOnSuccess && (Get.isBottomSheetOpen ?? false)) {
        Get.back();
      }
    } catch (e) {
      isConnected.value = false;
      connectedAddress.value = null;
      currentStatus.value = null;

      if (showErrorSnackbar) {
        Get.snackbar(
          'Connection Failed',
          _userFacingReason(
            e,
            fallback: 'Unable to connect to the tower light.',
          ),
        );
      }
    } finally {
      connectingAddress.value = null;
    }
  }

  Future<void> tryAutoReconnectFromSaved() async {
    if (isConnected.value) return;

    final savedAddress = await BluetoothDeviceStore.getDevice(
      BluetoothDeviceStore.towerLightKey,
    );
    if (savedAddress == null || savedAddress.isEmpty) return;

    try {
      await startScan();
    } catch (_) {
      return;
    }

    final matched = _deviceMap[savedAddress];
    if (matched == null) return;

    await connectToDeviceWithOptions(
      matched,
      closeBottomSheetOnSuccess: false,
      showErrorSnackbar: false,
    );
  }

  Future<void> updateWeightStatus(WeightStatus newStatus) async {
    if (!isConnected.value) return;
    if (currentStatus.value == newStatus) return;

    final payload = buildPayload(newStatus);

    try {
      final sent = await _bluetooth.sendString(payload);
      if (!sent) {
        throw Exception('Tower light did not accept payload.');
      }

      currentStatus.value = newStatus;
    } catch (e) {
      debugPrint('Tower light write failed: $e');
      isConnected.value = false;
      connectedAddress.value = null;
      currentStatus.value = null;
    }
  }

  Future<void> disconnect({bool clearSavedDevice = true}) async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}

    isConnected.value = false;
    connectingAddress.value = null;
    connectedAddress.value = null;
    currentStatus.value = null;

    if (clearSavedDevice) {
      await BluetoothDeviceStore.clearDevice(
        BluetoothDeviceStore.towerLightKey,
      );
    }
  }

  String displayName(classic.BluetoothDevice device) {
    final name = device.name.trim();
    if (name.isNotEmpty) return name;

    final suffix = device.address.length > 5
        ? device.address.substring(device.address.length - 5)
        : device.address;
    return 'Unknown Device ($suffix)';
  }

  void _publishDevices() {
    final sorted = _deviceMap.values.toList()
      ..sort((a, b) {
        final aPaired = a.paired ? 0 : 1;
        final bPaired = b.paired ? 0 : 1;
        if (aPaired != bPaired) return aPaired.compareTo(bPaired);

        final aName = a.name.trim().toLowerCase();
        final bName = b.name.trim().toLowerCase();
        return aName.compareTo(bName);
      });

    devices.assignAll(sorted);
  }

  String _userFacingReason(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    final cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^BluetoothException:\s*'), '')
        .replaceFirst(RegExp(r'^PlatformException\([^,]+,\s*'), '')
        .replaceFirst(RegExp(r',\s*null,\s*null\)$'), '')
        .trim();

    final lower = cleaned.toLowerCase();
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'Timed out while connecting.';
    }

    if (cleaned.isEmpty || cleaned.length > 80) {
      return fallback;
    }

    return cleaned;
  }

  @override
  void onClose() {
    _connectionSub?.cancel();
    _stateSub?.cancel();
    _discoverySub?.cancel();
    _bluetooth.dispose();
    super.onClose();
  }
}

Future<void> showTowerLightSheet(
  BuildContext context,
  TowerLightController controller,
) async {
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
            if (!controller.isScanning.value && controller.devices.isEmpty)
              Column(
                children: [
                  const Text(
                    "No tower lights found\nCheck if the device is paired and nearby",
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
                itemCount: controller.devices.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final device = controller.devices[i];
                  final address = device.address;
                  final isConnectingNow =
                      controller.connectingAddress.value == address;
                  final isConnectedNow =
                      controller.connectedAddress.value == address &&
                      controller.isConnected.value;

                  return ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(controller.displayName(device)),
                    subtitle: Text(
                      device.paired ? '$address • Paired' : address,
                    ),
                    trailing: isConnectingNow
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              if (isConnectedNow) {
                                await controller.disconnect();
                                return;
                              }

                              await controller.connectToDevice(device);
                            },
                            child: Text(
                              isConnectedNow ? "Disconnect" : "Connect",
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

  controller.devices.clear();
  controller.isScanning.value = true;

  unawaited(
    controller.startScan().catchError((e) {
      controller.isScanning.value = false;
      Get.snackbar(
        'Scan Failed',
        controller._userFacingReason(
          e,
          fallback: 'Unable to scan for tower lights.',
        ),
      );
    }),
  );
}

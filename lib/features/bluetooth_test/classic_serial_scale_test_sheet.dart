import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:synchronized/synchronized.dart';

import '../../apis/bluetooth_device_store.dart';
import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../constants/styles.dart';
import '../../services/classic_bluetooth_bridge.dart';
import '../dashboard/dashboardController.dart';

class ClassicSerialScaleTestController extends GetxController {
  static const String savedDeviceKey = 'classic_serial_scale_test';

  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();

  final RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final RxnString connectingAddress = RxnString();
  final RxnString connectedAddress = RxnString();

  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<BluetoothData>? _dataSub;
  StreamSubscription<BluetoothState>? _stateSub;
  StreamSubscription<BluetoothDevice>? _discoverySub;
  final Map<String, BluetoothDevice> _deviceMap = {};
  final Lock _operationLock = Lock(reentrant: true);
  DashboardController? _dashboardController;
  bool _listenersInitialized = false;

  static ClassicSerialScaleTestController ensureRegistered() {
    if (Get.isRegistered<ClassicSerialScaleTestController>()) {
      return Get.find<ClassicSerialScaleTestController>();
    }
    return Get.put(ClassicSerialScaleTestController(), permanent: true);
  }

  Future<void> initialize(DashboardController dashboardController) async {
    _dashboardController = dashboardController;
    if (_listenersInitialized) return;

    _connectionSub = _bluetooth.onConnectionChanged.listen((state) {
      final controller = _dashboardController;
      final connected = state.isConnected;
      if (connected && controller != null) {
        _markConnected(state.deviceAddress, controller);
      } else {
        isConnected.value = false;
        connectedAddress.value = null;
      }

      if (!connected && controller != null) {
        controller.isWeightScaleConnected.value = false;
        controller.isExperimentalScaleConnected.value = false;
        controller.receivedData.value = '';
      }
    });

    _dataSub = _bluetooth.onDataReceived.listen((data) {
      final controller = _dashboardController;
      if (controller == null) return;
      _syncScaleData(data.asString(), controller);
    });

    _stateSub = _bluetooth.onStateChanged.listen((state) {
      if (!state.isEnabled) {
        isScanning.value = false;
      }
    });

    _listenersInitialized = true;
  }

  Future<void> prepareBluetooth() async {
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

  Future<void> refreshDevices(DashboardController dashboardController) async {
    await _operationLock.synchronized(() async {
      await initialize(dashboardController);
      await prepareBluetooth();

      isScanning.value = true;
      _deviceMap.clear();

      final pairedDevices = await _bluetooth.getPairedDevices();
      for (final device in pairedDevices) {
        _deviceMap[device.address] = device;
      }
      _publishDevices();

      await _discoverySub?.cancel();
      try {
        final discoveryStarted = await _bluetooth.startDiscovery();
        if (discoveryStarted) {
          _discoverySub = _bluetooth.onDeviceDiscovered.listen((device) {
            _deviceMap[device.address] = device;
            _publishDevices();
          });

          Future.delayed(const Duration(seconds: 5), () async {
            try {
              await _bluetooth.stopDiscovery();
            } catch (_) {}
            isScanning.value = false;
          });
        } else {
          isScanning.value = false;
        }
      } catch (_) {
        isScanning.value = false;
      }
    });
  }

  Future<void> connect(
    BluetoothDevice device,
    DashboardController dashboardController,
  ) async {
    await _operationLock.synchronized(() async {
      if (isConnected.value && connectedAddress.value == device.address) {
        return;
      }
      if (connectingAddress.value == device.address) {
        return;
      }

      try {
        await initialize(dashboardController);
        await prepareBluetooth();
      } catch (e) {
        Get.snackbar(
          'Connection Failed',
          _userFacingReason(e, fallback: 'Unable to connect to the scale.'),
        );
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
        _markConnected(device.address, dashboardController);
        await BluetoothDeviceStore.saveDevice(savedDeviceKey, device.address);
      } catch (e) {
        isConnected.value = false;
        connectedAddress.value = null;
        dashboardController.isWeightScaleConnected.value = false;
        dashboardController.isExperimentalScaleConnected.value = false;
        dashboardController.receivedData.value = '';
        await disconnect(
          dashboardController,
          clearSavedDevice: false,
          showSnackbar: false,
        );
        Get.snackbar(
          'Connection Failed',
          _userFacingReason(e, fallback: 'Unable to connect to the scale.'),
        );
      } finally {
        connectingAddress.value = null;
      }
    });
  }

  Future<void> tryAutoReconnectFromSaved(
    DashboardController dashboardController, {
    bool force = false,
  }) async {
    await _operationLock.synchronized(() async {
      if (isConnected.value && !force) return;
      if (force && isConnected.value) return;

      final savedAddress = await BluetoothDeviceStore.getDevice(savedDeviceKey);
      if (savedAddress == null || savedAddress.isEmpty) return;

      if (force) {
        await disconnect(
          dashboardController,
          clearSavedDevice: false,
          showSnackbar: false,
        );
      }

      try {
        await initialize(dashboardController);
        await prepareBluetooth();
      } catch (_) {
        return;
      }

      isScanning.value = true;
      _deviceMap.clear();

      final pairedDevices = await _bluetooth.getPairedDevices();
      for (final device in pairedDevices) {
        _deviceMap[device.address] = device;
      }
      _publishDevices();

      var matched = _deviceMap[savedAddress];
      if (matched != null) {
        isScanning.value = false;
        await connect(matched, dashboardController);
        return;
      }

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

        final until = DateTime.now().add(const Duration(seconds: 5));
        while (DateTime.now().isBefore(until)) {
          matched = _deviceMap[savedAddress];
          if (matched != null) break;
          await Future.delayed(const Duration(milliseconds: 250));
        }
      } catch (_) {
        isScanning.value = false;
        return;
      } finally {
        try {
          await _bluetooth.stopDiscovery();
        } catch (_) {}
        isScanning.value = false;
      }

      if (matched != null) {
        await connect(matched, dashboardController);
      }
    });
  }

  Future<void> handleAppResumed(DashboardController dashboardController) async {
    await initialize(dashboardController);

    final savedAddress = await BluetoothDeviceStore.getDevice(savedDeviceKey);
    if (savedAddress == null || savedAddress.isEmpty) return;
    if (isConnected.value && connectedAddress.value == savedAddress) {
      dashboardController.isWeightScaleConnected.value = true;
      dashboardController.isExperimentalScaleConnected.value = true;
      dashboardController.isUniversalBleScaleConnected.value = false;
      return;
    }

    await tryAutoReconnectFromSaved(dashboardController);
  }

  Future<void> disconnect(
    DashboardController dashboardController, {
    bool clearSavedDevice = true,
    bool showSnackbar = true,
  }) async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}

    isConnected.value = false;
    connectedAddress.value = null;
    dashboardController.isWeightScaleConnected.value = false;
    dashboardController.isExperimentalScaleConnected.value = false;
    dashboardController.receivedData.value = '';

    if (clearSavedDevice) {
      await BluetoothDeviceStore.clearDevice(savedDeviceKey);
    }

    if (showSnackbar) {
      Get.snackbar('Scale', 'Disconnected');
    }
  }

  void _syncScaleData(String raw, DashboardController dashboardController) {
    final address = connectedAddress.value;
    if (address != null && !isConnected.value) {
      _markConnected(address, dashboardController);
    }

    dashboardController.receivedData.value = raw;

    final weight = dashboardController.parseWeight(raw);
    if (weight == null) return;

    final formatted = weight.toStringAsFixed(3);
    dashboardController.manualBatchWeights.manualGross.value = formatted;
    dashboardController.manualBatchWeights.calculateManualNet();
    dashboardController.manualNonBatchWeights.manualGross.value = formatted;
    dashboardController.manualNonBatchWeights.calculateManualNet();
    dashboardController.manualTareWeights.manualGross.value = formatted;
  }

  void _markConnected(String address, DashboardController dashboardController) {
    isConnected.value = true;
    connectedAddress.value = address;
    dashboardController.isWeightScaleConnected.value = true;
    dashboardController.isExperimentalScaleConnected.value = true;
    dashboardController.isUniversalBleScaleConnected.value = false;
  }

  void _publishDevices() {
    final sorted = _deviceMap.values.toList()
      ..sort((a, b) {
        final aPaired = a.paired ? 0 : 1;
        final bPaired = b.paired ? 0 : 1;
        if (aPaired != bPaired) return aPaired.compareTo(bPaired);

        final aName = (a.name).trim().toLowerCase();
        final bName = (b.name).trim().toLowerCase();
        return aName.compareTo(bName);
      });
    devices.assignAll(sorted);
  }

  String displayName(BluetoothDevice device) {
    final name = device.name.trim();
    if (name.isNotEmpty) return name;

    final suffix = device.address.length > 5
        ? device.address.substring(device.address.length - 5)
        : device.address;
    return 'Unknown Device ($suffix)';
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
    _connectionSub?.cancel();
    _dataSub?.cancel();
    _stateSub?.cancel();
    _discoverySub?.cancel();
    _dashboardController = null;
    _listenersInitialized = false;
    super.onClose();
  }
}

Future<void> showClassicSerialScaleTestSheet(
  BuildContext context,
  DashboardController dashboardController,
) async {
  final controller = ClassicSerialScaleTestController.ensureRegistered();

  try {
    await controller.refreshDevices(dashboardController);
  } catch (e) {
    controller.isScanning.value = false;
    Get.snackbar(
      'Scan Failed',
      controller._userFacingReason(e, fallback: 'Unable to scan.'),
    );
  }

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
              "Classic Bluetooth scale test flow",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!controller.isScanning.value && controller.devices.isEmpty)
              Column(
                children: [
                  const Text(
                    "No paired devices found \n Check if the scale is paired and nearby",
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight20,
                  ElevatedButton(
                    onPressed: () =>
                        controller.refreshDevices(dashboardController),
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
                                await controller.disconnect(
                                  dashboardController,
                                );
                                return;
                              }

                              await controller.connect(
                                device,
                                dashboardController,
                              );
                              if (controller.connectedAddress.value ==
                                      address &&
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

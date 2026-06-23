import 'dart:async';

import 'package:get/get.dart';

import '../../apis/bluetooth_device_store.dart';
import '../models/scale_models.dart';
import '../services/android_scale_service.dart';

class AndroidScaleConnectionController extends GetxController {
  AndroidScaleConnectionController({
    AndroidScaleService? service,
  }) : _service = service ?? AndroidScaleService();

  final AndroidScaleService _service;

  final RxList<DiscoveredScaleDevice> devices = <DiscoveredScaleDevice>[].obs;
  final Rx<ScaleConnectionSnapshot> connection =
      const ScaleConnectionSnapshot.disconnected().obs;
  final Rxn<ScaleReading> latestReading = Rxn<ScaleReading>();
  final Rxn<ScalePacket> latestPacket = Rxn<ScalePacket>();
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  static AndroidScaleConnectionController ensureRegistered() {
    if (Get.isRegistered<AndroidScaleConnectionController>()) {
      return Get.find<AndroidScaleConnectionController>();
    }
    return Get.put(AndroidScaleConnectionController(), permanent: true);
  }

  bool get isConnected =>
      connection.value.status == ScaleConnectionStatus.connected;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _service.initialize();

    _subscriptions.add(
      _service.scanResults.listen((items) {
        devices.assignAll(items);
      }),
    );
    _subscriptions.add(
      _service.connectionState.listen((snapshot) async {
        connection.value = snapshot;
        if (snapshot.status == ScaleConnectionStatus.connected &&
            snapshot.device != null) {
          await BluetoothDeviceStore.saveDevice(
            BluetoothDeviceStore.scaleKey,
            _serializeDevice(snapshot.device!),
          );
        }
      }),
    );
    _subscriptions.add(
      _service.rawPackets.listen((packet) {
        latestPacket.value = packet;
      }),
    );
    _subscriptions.add(
      _service.readings.listen((reading) {
        latestReading.value = reading;
      }),
    );
  }

  Future<void> refreshDevices() async {
    errorMessage.value = '';
    isScanning.value = true;
    try {
      await _service.startScan();
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      Future.delayed(const Duration(seconds: 5), () {
        isScanning.value = false;
      });
    }
  }

  Future<void> connect(DiscoveredScaleDevice device) async {
    errorMessage.value = '';
    try {
      await _service.connect(device);
    } catch (error) {
      errorMessage.value = error.toString();
    }
  }

  Future<void> disconnect({bool clearSavedDevice = true}) async {
    errorMessage.value = '';
    try {
      await _service.disconnect();
    } catch (error) {
      errorMessage.value = error.toString();
    }
    if (clearSavedDevice) {
      await BluetoothDeviceStore.clearDevice(BluetoothDeviceStore.scaleKey);
    }
  }

  Future<void> tryAutoReconnectFromSaved() async {
    if (isConnected) return;

    final saved = await BluetoothDeviceStore.getDevice(
      BluetoothDeviceStore.scaleKey,
    );
    final savedDevice = _deserializeDevice(saved);
    if (savedDevice == null) return;

    await refreshDevices();

    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(deadline)) {
      final match = devices.firstWhereOrNull(
        (item) =>
            item.id == savedDevice.id &&
            item.transportType == savedDevice.transportType,
      );
      if (match != null) {
        await connect(match);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> handleAppResumed() async {
    if (isConnected) return;
    await tryAutoReconnectFromSaved();
  }

  @override
  Future<void> onClose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _service.dispose();
    super.onClose();
  }

  String _serializeDevice(DiscoveredScaleDevice device) {
    return '${device.transportType.name}|${device.id}|${device.name}';
  }

  DiscoveredScaleDevice? _deserializeDevice(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('|');
    if (parts.length < 2) return null;

    final type = ScaleTransportType.values.firstWhereOrNull(
      (item) => item.name == parts[0],
    );
    if (type == null) return null;

    return DiscoveredScaleDevice(
      id: parts[1],
      name: parts.length > 2 ? parts.sublist(2).join('|') : '',
      transportType: type,
      isBonded: type == ScaleTransportType.classic,
    );
  }
}

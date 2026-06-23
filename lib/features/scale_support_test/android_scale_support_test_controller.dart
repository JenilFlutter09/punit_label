import 'dart:async';

import 'package:get/get.dart';

import '../../scale_support/scale_support.dart';

class AndroidScaleSupportTestController extends GetxController {
  final AndroidScaleService service = AndroidScaleService();

  final RxList<DiscoveredScaleDevice> devices = <DiscoveredScaleDevice>[].obs;
  final Rx<ScaleConnectionSnapshot> connection =
      const ScaleConnectionSnapshot.disconnected().obs;
  final Rxn<ScaleReading> latestReading = Rxn<ScaleReading>();
  final Rxn<ScalePacket> latestPacket = Rxn<ScalePacket>();
  final RxBool isScanning = false.obs;
  final RxString errorMessage = ''.obs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  static AndroidScaleSupportTestController ensureRegistered() {
    if (Get.isRegistered<AndroidScaleSupportTestController>()) {
      return Get.find<AndroidScaleSupportTestController>();
    }
    return Get.put(AndroidScaleSupportTestController());
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await service.initialize();

    _subscriptions.add(
      service.scanResults.listen((items) {
        devices.assignAll(items);
      }),
    );
    _subscriptions.add(
      service.connectionState.listen((snapshot) {
        connection.value = snapshot;
      }),
    );
    _subscriptions.add(
      service.rawPackets.listen((packet) {
        latestPacket.value = packet;
      }),
    );
    _subscriptions.add(
      service.readings.listen((reading) {
        latestReading.value = reading;
      }),
    );
  }

  Future<void> refreshDevices() async {
    errorMessage.value = '';
    isScanning.value = true;
    try {
      await service.startScan();
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
      await service.connect(device);
    } catch (error) {
      errorMessage.value = error.toString();
    }
  }

  Future<void> disconnect() async {
    errorMessage.value = '';
    try {
      await service.disconnect();
    } catch (error) {
      errorMessage.value = error.toString();
    }
  }

  @override
  Future<void> onClose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await service.dispose();
    super.onClose();
  }
}

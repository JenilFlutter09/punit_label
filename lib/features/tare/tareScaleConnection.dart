import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../constants/styles.dart';
import '../dashboard/dashboardController.dart';
import '../../widgets/bluetooth_bottomsheet.dart';
import '../bluetooth_test/classic_serial_scale_test_sheet.dart';

class TareScaleConnectionController extends GetxController {
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final ClassicSerialScaleTestController classicScaleController =
      ClassicSerialScaleTestController.ensureRegistered();

  final RxDouble liveWeight = 0.0.obs;

  Worker? _weightWorker;
  Worker? _connectionWorker;

  static TareScaleConnectionController ensureRegistered() {
    if (Get.isRegistered<TareScaleConnectionController>()) {
      return Get.find<TareScaleConnectionController>();
    }
    return Get.put(TareScaleConnectionController());
  }

  bool get isConnected =>
      classicScaleController.isConnected.value ||
      dashboardController.isWeightScaleConnected.value;

  @override
  void onInit() {
    super.onInit();
    _syncLiveWeight(dashboardController.manualTareWeights.manualGross.value);
    _weightWorker = ever<String?>(
      dashboardController.manualTareWeights.manualGross,
      _syncLiveWeight,
    );
    _connectionWorker = ever<bool>(dashboardController.isWeightScaleConnected, (
      connected,
    ) {
      if (!connected) {
        liveWeight.value = 0.0;
        return;
      }
      _syncLiveWeight(dashboardController.manualTareWeights.manualGross.value);
    });
  }

  void _syncLiveWeight(String? rawWeight) {
    liveWeight.value = double.tryParse(rawWeight ?? '') ?? 0.0;
  }

  Future<void> connect(BuildContext context) async {
    await showScaleConnectionSheet(context, dashboardController);
  }

  Future<void> disconnect() async {
    if (classicScaleController.isConnected.value) {
      await classicScaleController.disconnect(dashboardController);
    } else {
      await dashboardController.disconnectDevice();
    }
    liveWeight.value = 0.0;
  }

  @override
  void onClose() {
    _weightWorker?.dispose();
    _connectionWorker?.dispose();
    super.onClose();
  }
}

class TareScaleConnectionCard extends StatelessWidget {
  const TareScaleConnectionCard({
    super.key,
    required this.controller,
    required this.isTablet,
  });

  final TareScaleConnectionController controller;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connected = controller.isConnected;
      final liveWeight = controller.liveWeight.value;

      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: Dimens.edgeInsets20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bluetooth_searching,
                    size: 28,
                    color: ColorsValue.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text("Tare Scale", style: Styles.blackBold18),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: connected
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      connected ? "Connected" : "Disconnected",
                      style: TextStyle(
                        color: connected ? Colors.green[700] : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Dimens.boxHeight16,
              Text(
                connected
                    ? "Live scale feed is active for tare weight."
                    : "Use the tare scale connection here without changing the existing dashboard flow.",
                style: Styles.black12,
              ),
              if (connected) ...[
                Dimens.boxHeight16,
                Text(
                  "${liveWeight.toStringAsFixed(3)} kg",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 34 : 28,
                    fontWeight: FontWeight.w800,
                    color: ColorsValue.primaryColor,
                  ),
                ),
              ],
              Dimens.boxHeight16,
              ElevatedButton.icon(
                onPressed: () async {
                  if (connected) {
                    await controller.disconnect();
                    return;
                  }
                  await controller.connect(context);
                },
                icon: Icon(
                  connected ? Icons.bluetooth_disabled : Icons.bluetooth,
                ),
                label: Text(connected ? "Disconnect Scale" : "Connect Scale"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: connected
                      ? ColorsValue.primaryColor
                      : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

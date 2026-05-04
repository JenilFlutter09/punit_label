import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../constants/bluetooth_device_display.dart';
import '../constants/sizes.dart';
import '../constants/strings.dart';
import '../constants/styles.dart';
import '../features/dashboard/dashboardController.dart';

Future<void> showBluetoothSheet(
  BuildContext context,
  DashboardController controller,
  String role,
) async {
  await controller.startScan(roles: role);

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
            const SizedBox(height: 16),

            // List / Loader / No devices
            if (!controller.isScanning.value && controller.scanResults.isEmpty)
              Column(
                children: [
                  const Text(
                    "No devices found \n Check If your Location service is ON \n Check your Bluetooth should also be ON",
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight20,
                  ElevatedButton(
                    onPressed: () async =>
                        await controller.startScan(roles: role),
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                        ColorsValue.primaryColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        Dimens.boxWidth8,
                        Text(
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

                    /* trailing: ElevatedButton(
                      onPressed: () {
                        controller.connectToDevice(result.device);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Connect",
                        style: Styles.primary14.copyWith(color: Colors.white),
                      ),
                    ),*/
                    trailing: Obx(() {
                      if (controller.connectingDeviceId.value == deviceId) {
                        return const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      return ElevatedButton(
                        onPressed: () async {
                          await controller.connectToDevice(result.device);
                          if (controller.connectedDevice.value?.remoteId ==
                              result.device.remoteId) {
                            Get.back(); // close only if connected ✅
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Connect",
                          style: Styles.primary14.copyWith(color: Colors.white),
                        ),
                      );
                    }),
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

Future<void> showBluetoothPrinterSheet(
  BuildContext context,
  DashboardController controller,
  String role,
) async {
  await controller.startScan(roles: SStringConstants.role_printer);

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
            const SizedBox(height: 16),

            // List / Loader / No devices
            if (!controller.isScanning.value && controller.scanResults.isEmpty)
              Column(
                children: [
                  const Text(
                    "No devices found \n Check If your location service is ON \n Connect printer to your device using password 1234 ",
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight20,
                  ElevatedButton(
                    onPressed: () async => await controller.startScan(
                      roles: SStringConstants.role_printer,
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                        ColorsValue.primaryColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        Dimens.boxWidth8,
                        Text(
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
                        onPressed: () async {
                          String mac = deviceId; // MAC address
                          Get.snackbar('Mac Address', mac);

                          try {
                            //await controller.initPrinter(); // make sure SDK is ready
                            await controller.connectPrinterWithMac(mac);
                            //controller.connectedPrinter.value = result.device;

                            // wait a bit or listen to SDK event for connection
                            Future.delayed(Duration(seconds: 2), () {
                              if (controller.isPrinterConnected.value) {
                                Get.back(); // close sheet only on success
                              } else {
                                Get.snackbar(
                                  'Status',
                                  controller.statusMessage.value,
                                );
                              }
                            });
                          } catch (e) {
                            Get.snackbar('Error', e.toString());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Connect",
                          style: Styles.primary14.copyWith(color: Colors.white),
                        ),
                      );
                    }),
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

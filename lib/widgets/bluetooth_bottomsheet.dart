import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/bluetooth_device_display.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../constants/strings.dart';
import '../constants/styles.dart';
import '../features/dashboard/dashboardController.dart';
import '../features/scale_support_test/android_scale_support_test_sheet.dart';
import '../scale_support/scale_support.dart';

enum BluetoothDeviceSheetType { scale, printer }

Future<void> showScaleConnectionSheet(
  BuildContext context,
  DashboardController controller,
) async {
  final scaleController = controller.androidScaleController;

  try {
    await scaleController.refreshDevices();
  } catch (e) {
    scaleController.isScanning.value = false;
    Get.snackbar(
      'Scan Failed',
      _userFacingReason(e, fallback: 'Unable to scan for scales.'),
    );
  }

  return _showDeviceConnectionSheet(
    context: context,
    title: 'Scale Connection',
    subtitle: 'Connect a paired scale to stream live weight into the app.',
    extraHeaderAction: TextButton.icon(
      onPressed: () async {
        Get.back();
        await showAndroidScaleSupportTestSheet(context);
      },
      icon: const Icon(Icons.science_outlined, size: 18),
      label: const Text('Open New Android Scale Tester'),
    ),
    rescan: () => scaleController.refreshDevices(),
    statusBanner: Obx(
      () => scaleController.devices.isEmpty
          ? _emptyInfoBanner(
              'No scale found.\nMake sure the device is nearby, paired if Classic, and Bluetooth is on.',
            )
          : const SizedBox.shrink(),
    ),
    child: Obx(
      () => _ConnectionListShell(
        isScanning: scaleController.isScanning.value,
        hasItems: scaleController.devices.isNotEmpty,
        emptyActionLabel: 'Scan Again',
        emptyAction: () => scaleController.refreshDevices(),
        emptyMessage:
            'No scale found.\nMake sure the device is nearby, paired if Classic, and Bluetooth is on.',
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: scaleController.devices.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final device = scaleController.devices[index];
            final connectedId = scaleController.connection.value.device?.id;
            final isConnectingNow =
                scaleController.connection.value.status ==
                    ScaleConnectionStatus.connecting &&
                connectedId == device.id;
            final isConnectedNow =
                scaleController.connection.value.status ==
                    ScaleConnectionStatus.connected &&
                connectedId == device.id;

            return _ConnectionTile(
              title: device.displayName,
              subtitle:
                  '${device.id} • ${device.transportType.name.toUpperCase()}${device.isBonded ? ' • Bonded' : ''}',
              icon: device.transportType == ScaleTransportType.classic
                  ? Icons.bluetooth
                  : Icons.settings_input_antenna,
              connected: isConnectedNow,
              loading: isConnectingNow,
              actionLabel: isConnectedNow ? 'Disconnect' : 'Connect',
              actionColor: isConnectedNow ? Colors.red : Colors.green,
              onPressed: () async {
                if (isConnectedNow) {
                  await scaleController.disconnect();
                  return;
                }

                await scaleController.connect(device);
                if (scaleController.connection.value.status ==
                    ScaleConnectionStatus.connected) {
                  Get.back();
                }
              },
            );
          },
        ),
      ),
    ),
  );
}

Future<void> showPrinterConnectionSheet(
  BuildContext context,
  DashboardController controller,
) async {
  await controller.startScan(roles: SStringConstants.role_printer);

  return _showDeviceConnectionSheet(
    context: context,
    title: controller.isLabelPrinterMode.value
        ? 'Printer Connection'
        : 'Receipt Printer Connection',
    subtitle: controller.isLabelPrinterMode.value
        ? 'Choose a paired printer. Use Bluetooth password 1234 if prompted.'
        : 'Choose a paired receipt printer for non-label mode.',
    rescan: () => controller.startScan(roles: SStringConstants.role_printer),
    statusBanner: Obx(
      () => controller.scanResults.isEmpty
          ? _emptyInfoBanner(
              'No printers found.\nTurn Bluetooth on and keep the printer nearby.',
            )
          : const SizedBox.shrink(),
    ),
    child: Obx(
      () => _ConnectionListShell(
        isScanning: controller.isScanning.value,
        hasItems: controller.scanResults.isNotEmpty,
        emptyActionLabel: 'Scan Again',
        emptyAction: () =>
            controller.startScan(roles: SStringConstants.role_printer),
        emptyMessage:
            'No printers found.\nTurn Bluetooth on and keep the printer nearby.',
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: controller.scanResults.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = controller.scanResults[index];
            final deviceName = BluetoothDeviceDisplay.displayName(result);
            final deviceId = BluetoothDeviceDisplay.deviceIdFromResult(result);

            return _ConnectionTile(
              title: deviceName,
              subtitle: deviceId,
              icon: controller.isLabelPrinterMode.value
                  ? Icons.print_rounded
                  : Icons.receipt_long_rounded,
              connected: false,
              loading: controller.connectingDeviceId.value == deviceId,
              actionLabel: 'Connect',
              actionColor: Colors.green,
              onPressed: () async {
                controller.connectingDeviceId.value = deviceId;
                try {
                  if (controller.isLabelPrinterMode.value) {
                    await controller.connectPrinterWithMac(deviceId);
                    if (controller.isPrinterConnected.value) {
                      Get.back();
                    } else {
                      Get.snackbar('Printer', controller.statusMessage.value);
                    }
                  } else {
                    await controller.bluetoothController.connectToDevice(
                      result.device,
                    );
                    if (controller.bluetoothController.isConnected.value) {
                      Get.back();
                    }
                  }
                } catch (e) {
                  Get.snackbar('Connection Failed', e.toString());
                } finally {
                  controller.connectingDeviceId.value = null;
                }
              },
            );
          },
        ),
      ),
    ),
  );
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

Future<void> showBluetoothSheet(
  BuildContext context,
  DashboardController controller,
  String role,
) async {
  if (role == SStringConstants.role_scale) {
    return showScaleConnectionSheet(context, controller);
  }

  return showPrinterConnectionSheet(context, controller);
}

Future<void> showBluetoothPrinterSheet(
  BuildContext context,
  DashboardController controller,
  String role,
) async {
  return showPrinterConnectionSheet(context, controller);
}

Future<void> _showDeviceConnectionSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Future<void> Function() rescan,
  required Widget child,
  Widget? statusBanner,
  Widget? extraHeaderAction,
}) async {
  await Get.bottomSheet(
    Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.72,
        minHeight: Get.height * 0.42,
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorsValue.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.bluetooth_searching_rounded,
                    color: ColorsValue.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Styles.blackBold18),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Styles.black12),
                      if (extraHeaderAction != null) ...[
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: extraHeaderAction,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Scan Again',
                  onPressed: rescan,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: ColorsValue.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (statusBanner != null) statusBanner,
            Flexible(child: child),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

Widget _emptyInfoBanner(String message) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorsValue.shadowColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: ColorsValue.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Styles.black12)),
        ],
      ),
    ),
  );
}

class _ConnectionListShell extends StatelessWidget {
  const _ConnectionListShell({
    required this.isScanning,
    required this.hasItems,
    required this.emptyActionLabel,
    required this.emptyAction,
    required this.emptyMessage,
    required this.child,
  });

  final bool isScanning;
  final bool hasItems;
  final String emptyActionLabel;
  final Future<void> Function() emptyAction;
  final String emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isScanning && !hasItems) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: Styles.black12,
                textAlign: TextAlign.center,
              ),
              Dimens.boxHeight20,
              ElevatedButton.icon(
                onPressed: emptyAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsValue.primaryColor,
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  emptyActionLabel,
                  style: Styles.whiteBold12.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: child),
        if (isScanning)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Scanning...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.connected,
    required this.loading,
    required this.actionLabel,
    required this.actionColor,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool connected;
  final bool loading;
  final String actionLabel;
  final Color actionColor;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorsValue.shadowColor),
        color: connected ? Colors.green.withValues(alpha: 0.06) : Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ColorsValue.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ColorsValue.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Styles.blackBold14),
                const SizedBox(height: 4),
                Text(subtitle, style: Styles.black11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

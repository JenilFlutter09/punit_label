import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/bluetooth_device_display.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../constants/strings.dart';
import '../features/dashboard/dashboardController.dart';
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
    _DeviceConnectionSheet(
      title: title,
      subtitle: subtitle,
      rescan: rescan,
      statusBanner: statusBanner,
      extraHeaderAction: extraHeaderAction,
      child: child,
    ),
    isScrollControlled: true,
  );
}

class _DeviceConnectionSheet extends StatelessWidget {
  const _DeviceConnectionSheet({
    required this.title,
    required this.subtitle,
    required this.rescan,
    required this.child,
    this.statusBanner,
    this.extraHeaderAction,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() rescan;
  final Widget child;
  final Widget? statusBanner;
  final Widget? extraHeaderAction;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isTablet = size.shortestSide >= 600;
    final isHorizontalTablet =
        isTablet && media.orientation == Orientation.landscape;

    final maxWidth = isHorizontalTablet
        ? size.width
        : isTablet
        ? math.min(size.width * 0.86, 760.0)
        : size.width;
    final maxHeight = isHorizontalTablet
        ? size.height * 0.82
        : size.height * 0.72;
    final minHeight = isHorizontalTablet
        ? size.height * 0.58
        : size.height * 0.42;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(maxHeight: maxHeight, minHeight: minHeight),
        padding: EdgeInsets.fromLTRB(
          isHorizontalTablet ? 28 : 18,
          12,
          isHorizontalTablet ? 28 : 18,
          isHorizontalTablet ? 24 : 18,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: isHorizontalTablet
              ? _buildHorizontalTabletLayout()
              : _buildVerticalLayout(),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetGrabHandle(),
        const SizedBox(height: 16),
        _SheetHeader(
          title: title,
          subtitle: subtitle,
          rescan: rescan,
          extraHeaderAction: extraHeaderAction,
          compact: true,
        ),
        const SizedBox(height: 16),
        if (statusBanner != null) statusBanner!,
        Flexible(child: child),
      ],
    );
  }

  Widget _buildHorizontalTabletLayout() {
    return Column(
      children: [
        const _SheetGrabHandle(),
        const SizedBox(height: 18),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sideWidth = (constraints.maxWidth * 0.32).clamp(
                230.0,
                320.0,
              );
              final gutter = constraints.maxWidth < 720 ? 16.0 : 24.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: sideWidth,
                    child: _SheetHeader(
                      title: title,
                      subtitle: subtitle,
                      rescan: rescan,
                      extraHeaderAction: extraHeaderAction,
                      compact: false,
                    ),
                  ),
                  SizedBox(width: gutter),
                  VerticalDivider(width: 1, color: ColorsValue.shadowColor),
                  SizedBox(width: gutter),
                  Expanded(
                    child: Column(
                      children: [
                        if (statusBanner != null) statusBanner!,
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SheetTextStyles {
  static const compactTitle = TextStyle(
    color: Colors.black,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const tabletTitle = TextStyle(
    color: Colors.black,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const body = TextStyle(
    color: Colors.black87,
    fontSize: 13,
    height: 1.35,
  );

  static const bodySmall = TextStyle(
    color: Colors.black54,
    fontSize: 12,
    height: 1.3,
  );

  static const tileTitle = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const button = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
}

class _SheetGrabHandle extends StatelessWidget {
  const _SheetGrabHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.rescan,
    required this.compact,
    this.extraHeaderAction,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() rescan;
  final Widget? extraHeaderAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: compact ? 44 : 56,
      height: compact ? 44 : 56,
      decoration: BoxDecoration(
        color: ColorsValue.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Icon(
        Icons.bluetooth_searching_rounded,
        size: compact ? 24 : 30,
        color: ColorsValue.primaryColor,
      ),
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compact
              ? _SheetTextStyles.compactTitle
              : _SheetTextStyles.tabletTitle,
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: _SheetTextStyles.body),
      ],
    );

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
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
            icon: Icon(Icons.refresh_rounded, color: ColorsValue.primaryColor),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(height: 18),
        titleBlock,
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: rescan,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsValue.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Scan Again', style: _SheetTextStyles.button),
          ),
        ),
        if (extraHeaderAction != null) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: extraHeaderAction),
        ],
      ],
    );
  }
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
          Expanded(child: Text(message, style: _SheetTextStyles.body)),
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
                style: _SheetTextStyles.body,
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
                  style: _SheetTextStyles.button.copyWith(color: Colors.white),
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
                Text(title, style: _SheetTextStyles.tileTitle),
                const SizedBox(height: 4),
                Text(subtitle, style: _SheetTextStyles.bodySmall),
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
              child: Text(actionLabel, style: _SheetTextStyles.button),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../scale_support/models/scale_models.dart';
import 'android_scale_support_test_controller.dart';

Future<void> showAndroidScaleSupportTestSheet(BuildContext context) async {
  final controller = AndroidScaleSupportTestController.ensureRegistered();
  await controller.refreshDevices();

  await Get.bottomSheet(
    Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.88,
        minHeight: Get.height * 0.60,
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Android Scale Tester',
                      style: Styles.blackBold18,
                    ),
                  ),
                  IconButton(
                    onPressed: controller.refreshDevices,
                    icon: controller.isScanning.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
              Text(
                'Tests the new Android-only Classic + BLE scale support layer.',
                style: Styles.black12,
              ),
              const SizedBox(height: 12),
              _StatusCard(controller: controller),
              if (controller.errorMessage.value.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text('Detected Devices', style: Styles.blackBold14),
              const SizedBox(height: 8),
              Expanded(
                child: controller.devices.isEmpty
                    ? Center(
                        child: Text(
                          controller.isScanning.value
                              ? 'Scanning for Classic and BLE scale devices...'
                              : 'No devices found yet. Tap refresh to rescan.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: controller.devices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final device = controller.devices[index];
                          final connectedId =
                              controller.connection.value.device?.id;
                          final isConnected =
                              controller.connection.value.status ==
                                  ScaleConnectionStatus.connected &&
                              connectedId == device.id;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: ColorsValue.primaryColor
                                  .withValues(alpha: 0.10),
                              child: Icon(
                                device.transportType == ScaleTransportType.classic
                                    ? Icons.bluetooth
                                    : Icons.settings_input_antenna,
                                color: ColorsValue.primaryColor,
                              ),
                            ),
                            title: Text(device.displayName),
                            subtitle: Text(
                              '${device.id}\n${device.transportType.name.toUpperCase()}${device.isBonded ? ' • Bonded' : ''}',
                            ),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isConnected ? Colors.red : Colors.green,
                              ),
                              onPressed: () async {
                                if (isConnected) {
                                  await controller.disconnect();
                                  return;
                                }
                                await controller.connect(device);
                              },
                              child: Text(
                                isConnected ? 'Disconnect' : 'Connect',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});

  final AndroidScaleSupportTestController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.connection.value;
    final reading = controller.latestReading.value;
    final packet = controller.latestPacket.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusRow(
            label: 'Connection',
            value: snapshot.status.name.toUpperCase(),
          ),
          _StatusRow(
            label: 'Active Device',
            value: snapshot.device?.displayName ?? '--',
          ),
          _StatusRow(
            label: 'Transport',
            value: reading?.transportType.name.toUpperCase() ??
                snapshot.device?.transportType.name.toUpperCase() ??
                '--',
          ),
          _StatusRow(
            label: 'Parsed Weight',
            value: reading == null ? '--' : '${reading.weight.toStringAsFixed(3)} kg',
          ),
          _StatusRow(
            label: 'Raw Packet',
            value: packet?.asString.trim().isNotEmpty == true
                ? packet!.asString.trim()
                : '--',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

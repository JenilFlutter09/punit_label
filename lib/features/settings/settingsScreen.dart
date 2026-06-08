import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/constants/styles.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';
import 'package:punit_label/widgets/bluetooth_bottomsheet.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import 'package:punit_label/widgets/customDrawer.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final DashboardController dashController = Get.find();

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Settings',
        showScale: false,
        showPrinter: false,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: AdaptiveWorkflowShell(
        title: 'Settings',
        subtitle:
            'Manage label preferences and device connections here so the drawer stays focused on navigation and quick configuration.',
        compactContent: Column(
          children: [
            _LabelPreferencesCard(dashController: dashController),
            SizedBox(height: layout.sectionSpacing),
            _DeviceConnectionsCard(dashController: dashController),
          ],
        ),
        leftPanel: _LabelPreferencesCard(dashController: dashController),
        rightPanel: _DeviceConnectionsCard(dashController: dashController),
      ),
    );
  }
}

class _LabelPreferencesCard extends StatelessWidget {
  const _LabelPreferencesCard({required this.dashController});

  final DashboardController dashController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Label Preferences',
      subtitle:
          'Move label defaults and printing preferences out of the drawer so operators can change them deliberately.',
      child: Column(
        children: [
          _labelFormatDropdownTile(),
          _switchTile(
            icon: Icons.label_off,
            title: 'White Label',
            value: dashController.isWhiteLabel,
          ),
          _switchTile(
            icon: Icons.numbers,
            title: 'Serial Number',
            value: dashController.printSerialNumberInLabel,
          ),
          _switchTile(
            icon: Icons.timer_rounded,
            title: 'Time Stamp',
            value: dashController.printTimeInLabel,
          ),
          _counterTile(
            icon: Icons.one_x_mobiledata,
            title: 'Label Copies',
            value: dashController.printCopies,
            onDecrement: () => dashController.setPrintCopies(
              dashController.printCopies.value - 1,
            ),
            onIncrement: () => dashController.setPrintCopies(
              dashController.printCopies.value + 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required RxBool value,
  }) {
    return Obx(
      () => SwitchListTile(
        secondary: Icon(icon, color: ColorsValue.primaryColor),
        title: Text(title),
        value: value.value,
        onChanged: (v) => value.value = v,
      ),
    );
  }

  Widget _counterTile({
    required IconData icon,
    required String title,
    required RxInt value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Obx(
      () => ListTile(
        leading: Icon(icon, color: ColorsValue.primaryColor),
        title: Text(title),
        trailing: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: value.value > 1 ? onDecrement : null,
                icon: const Icon(Icons.remove),
                visualDensity: VisualDensity.compact,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                alignment: Alignment.center,
                child: Text(
                  '${value.value}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: value.value < 10 ? onIncrement : null,
                icon: const Icon(Icons.add),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelFormatDropdownTile() {
    return Obx(
      () => ListTile(
        leading: Icon(Icons.label, color: ColorsValue.primaryColor),
        title: const Text('Default Label Format'),
        subtitle: const Text('Used when opening non-batch inward'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 170, maxWidth: 210),
          child: DropdownButtonFormField<int>(
            initialValue:
                dashController.defaultNonBatchLabelFormatObj.value?.id,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: dashController.labelFormats
                .map(
                  (format) => DropdownMenuItem<int>(
                    value: format.id,
                    child: Text(
                      format.nameOfLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (selectedId) {
              if (selectedId == null) return;
              final selected = dashController.labelFormats.firstWhere(
                (format) => format.id == selectedId,
                orElse: () => dashController.labelFormats.first,
              );
              dashController.updateDefaultNonBatchLabelFormat(selected);
            },
          ),
        ),
      ),
    );
  }
}

class _DeviceConnectionsCard extends StatelessWidget {
  const _DeviceConnectionsCard({required this.dashController});

  final DashboardController dashController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Device Connections',
      subtitle:
          'Connect and manage the scale and printer here instead of mixing connection setup into the drawer.',
      child: Column(
        children: [
          Obx(
            () => _connectionTile(
              icon: Icons.scale_rounded,
              title: 'Scale',
              subtitle: dashController.isAnyScaleConnected
                  ? 'Connected and streaming live weight'
                  : 'Tap to connect a weighing scale',
              connected: dashController.isAnyScaleConnected,
              onTap: () async {
                if (dashController.isAnyScaleConnected) {
                  await dashController.disconnectActiveScale();
                } else {
                  await showScaleConnectionSheet(context, dashController);
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => _connectionTile(
              icon: dashController.isLabelPrinterMode.value
                  ? Icons.print_rounded
                  : Icons.receipt_long_rounded,
              title: dashController.isLabelPrinterMode.value
                  ? 'Printer'
                  : 'Receipt Printer',
              subtitle: dashController.isActivePrinterConnected
                  ? 'Connected and ready to print'
                  : 'Tap to connect a printer',
              connected: dashController.isActivePrinterConnected,
              onTap: () async {
                if (dashController.isActivePrinterConnected) {
                  await dashController.disconnectActivePrinter();
                  return;
                }

                if (dashController.isLabelPrinterMode.value) {
                  await showPrinterConnectionSheet(context, dashController);
                } else {
                  dashController.bluetoothController.openDeviceBottomSheet();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool connected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ColorsValue.shadowColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                    Text(subtitle, style: Styles.black12),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: connected
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  connected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    color: connected ? Colors.green[700] : Colors.orange[800],
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

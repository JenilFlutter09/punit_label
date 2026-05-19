import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/enums.dart';
import 'package:punit_label/constants/sizes.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/dispatch/view/dispatchScreen.dart';
import 'package:punit_label/features/inward/view/inwardScreen.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../features/tare/tareView.dart';
import 'bluetooth_bottomsheet.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});

  final DashboardController dashController = Get.find();

  @override
  Widget build(BuildContext context) {
    //final bool isTablet = MediaQuery.of(context).size.width > 600;

    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    return Drawer(
      // width: isTablet ? Dimens.twoHundredFifty : Dimens.hundredFifty,
      width: isMobile
          ? width * 0.75
          : isTablet
          ? 320
          : 360,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _header(dashboardController: dashController),
          Expanded(
            child: ListView(
              padding: Dimens.edgeInsets8_0_8_0,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Obx(
                    () => Row(
                      children: [
                        DrawerQuickAction(
                          icon: Icons.archive,
                          label: "Inward",
                          enabled: dashController.enableInward.value,
                          onTap: () {
                            Get.back();
                            Get.to(() => InwardScreen());
                          },
                        ),
                        DrawerQuickAction(
                          icon: Icons.local_shipping,
                          label: "Dispatch",
                          enabled: dashController.enableDispatch.value,
                          onTap: () {
                            Get.back();
                            Get.to(() => DispatchScreen());
                          },
                        ),
                        DrawerQuickAction(
                          icon: Icons.line_weight,
                          label: "Tare",
                          onTap: () {
                            Get.back();
                            Get.to(() => AddTareProductsView());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Dimens.boxHeight10,
                _sectionTitle("Device Connections"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Obx(
                        () => _connectionTile(
                          icon: Icons.scale_rounded,
                          title: "Scale",
                          subtitle: dashController.isAnyScaleConnected
                              ? "Connected and streaming live weight"
                              : "Tap to connect a weighing scale",
                          connected: dashController.isAnyScaleConnected,
                          onTap: () async {
                            Get.back();
                            if (dashController.isAnyScaleConnected) {
                              await dashController.disconnectActiveScale();
                            } else {
                              await showScaleConnectionSheet(
                                context,
                                dashController,
                              );
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
                              ? "Printer"
                              : "Receipt Printer",
                          subtitle: dashController.isActivePrinterConnected
                              ? "Connected and ready to print"
                              : "Tap to connect a printer",
                          connected: dashController.isActivePrinterConnected,
                          onTap: () async {
                            Get.back();
                            if (dashController.isActivePrinterConnected) {
                              await dashController.disconnectActivePrinter();
                              return;
                            }

                            if (dashController.isLabelPrinterMode.value) {
                              await showPrinterConnectionSheet(
                                context,
                                dashController,
                              );
                            } else {
                              dashController.bluetoothController
                                  .openDeviceBottomSheet();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Dimens.boxHeight10,
                _sectionTitle("Label Configuration"),
                _switchTile(
                  icon: Icons.label_off,
                  title: "White Label",
                  value: dashController.isWhiteLabel,
                ),
                _switchTile(
                  icon: Icons.numbers,
                  title: "Serial Number",
                  value: dashController.printSerialNumberInLabel,
                ),

                _switchTile(
                  icon: Icons.timer_rounded,
                  title: "Time Stamp",
                  value: dashController.printTimeInLabel,
                ),
                _counterTile(
                  icon: Icons.copy_rounded,
                  title: "Sticker Copies",
                  subtitle: "Print each label this many times",
                  value: dashController.printCopies,
                  onDecrement: () => dashController.setPrintCopies(
                    dashController.printCopies.value - 1,
                  ),
                  onIncrement: () => dashController.setPrintCopies(
                    dashController.printCopies.value + 1,
                  ),
                ),
                //  Divider(),
                Dimens.boxHeight10,
                _sectionTitle("Tare Weight Configuration"),
                //Dimens.boxHeight10,
                Obx(
                  () => ThreeLevelSelector(
                    value: dashController.tareState.value,
                    isTablet: isTablet,
                    onChanged: (state) {
                      dashController.tareState.value = state;
                      if (state == TareState.off) {
                        dashController.manualBatchWeights.manualTare.value =
                            '0';
                        dashController.manualBatchWeights.tareCtrl.text = '0';
                        dashController.manualNonBatchWeights.manualTare.value =
                            '0';
                        dashController.manualNonBatchWeights.tareCtrl.text =
                            '0';
                      }
                    },
                  ),
                ),

                //Dimens.boxHeight10,
                // Divider(),
                Dimens.boxHeight10,
                _sectionTitle("Printer Configuration"),
                //Dimens.boxHeight10,
                Obx(
                  () => TwoLevelSelector(
                    value: dashController.labelState.value,
                    isTablet: isTablet,
                    onChanged: (state) {
                      dashController.labelState.value = state;
                      if (state == LabelState.Receipt) {
                        if (dashController.isPrinterConnected.value == true) {
                          dashController.disconnectPrinter();
                        }
                        dashController.isLabelPrinterMode.value = false;
                      } else {
                        dashController.isLabelPrinterMode.value = true;
                      }
                    },
                  ),
                ),
                // Divider(),
                Dimens.boxHeight10,
                _sectionTitle("Tower Light Configuration"),
                //Dimens.boxHeight10,
                Obx(
                  () => TowerLevelSelector(
                    value: dashController.isTowerLight.value,
                    isTablet: isTablet,
                    onChanged: (state) {
                      dashController.isTowerLight.value = state;
                    },
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: dashController.logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsValue.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("Logout"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Header
  Widget _header({required DashboardController dashboardController}) {
    return Container(
      height: Dimens.hundredSixtySeven,
      width: Get.width,
      padding: Dimens.edgeInsets0_0_0_20,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsValue.primaryColor,
            ColorsValue.primaryColor.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 42,
              color: ColorsValue.primaryColor,
            ),
          ),
          Dimens.boxHeight12,
          Text(
            "Welcome ${dashboardController.userDetails.value?.name ?? 'User'}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dashboardController.userDetails.value?.companyCode ??
                'Operator Console',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  /// 🔹 Section title
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text.toUpperCase(), style: Styles.primaryBold14),
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
                  connected ? "Connected" : "Connect",
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

  /// 🔹 Switch row (professional pattern)
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
    required String subtitle,
    required RxInt value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Obx(
      () => ListTile(
        leading: Icon(icon, color: ColorsValue.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
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
                  "${value.value}",
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
}

class ThreeLevelSelector extends StatelessWidget {
  final TareState value;
  final ValueChanged<TareState> onChanged;
  final bool isTablet;

  const ThreeLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 14 : 10,
        horizontal: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _option(
            label: "OFF",
            level: TareState.off,
            selected: value == TareState.off,
          ),
          // Divider(),
          _option(
            label: "ON",
            level: TareState.on,
            selected: value == TareState.on,
          ),
          // Divider(),
          _option(
            label: "Barcode",
            level: TareState.barcode,
            selected: value == TareState.barcode,
          ),
        ],
      ),
    );
  }

  Widget _option({
    required String label,
    required TareState level,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(level),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorsValue.primaryColor.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: selected ? ColorsValue.whiteColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class TwoLevelSelector extends StatelessWidget {
  final LabelState value;
  final ValueChanged<LabelState> onChanged;
  final bool isTablet;

  const TwoLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 14 : 10,
        horizontal: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _option(
            label: "Label",
            level: LabelState.Label,
            selected: value == LabelState.Label,
          ),
          // Divider(),
          _option(
            label: "Receipt",
            level: LabelState.Receipt,
            selected: value == LabelState.Receipt,
          ),
        ],
      ),
    );
  }

  Widget _option({
    required String label,
    required LabelState level,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(level),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorsValue.primaryColor.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: selected ? ColorsValue.whiteColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class TowerLevelSelector extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isTablet;

  const TowerLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 14 : 10,
        horizontal: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _option(label: "ON", level: true, selected: value == true),
          _divider(),
          _option(label: "OFF", level: false, selected: value == false),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 24, width: 1.5, color: Colors.grey.shade300);
  }

  Widget _option({
    required String label,
    required bool level,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(level),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorsValue.primaryColor.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: selected ? ColorsValue.whiteColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class DrawerQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const DrawerQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: enabled
                  ? ColorsValue.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              child: Icon(
                icon,
                color: enabled ? ColorsValue.primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

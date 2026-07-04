import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/inward/batchWise/batchInwardController.dart';
import '../../../constants/sizes.dart';
import '../../../constants/styles.dart';
import '../../../constants/utility.dart';

import '../../../constants/colors.dart';
import '../../../constants/enums.dart';
import '../../scanner/scannerDailog.dart';

class BluetoothWeightSection extends StatelessWidget {
  final bool isTablet;
  final DashboardController dashboardController;
  final BatchInwardController controller;

  const BluetoothWeightSection({
    Key? key,
    required this.isTablet,
    required this.dashboardController,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tareState = dashboardController.tareState.value;
      final isBluetoothConnected =
          dashboardController.isWeightScaleConnected.value &&
          (dashboardController.connectedDevice.value != null ||
              dashboardController.isExperimentalScaleConnected.value);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔵 TARE ON / BARCODE → GROSS + TARE UI
          if (tareState != TareState.off) ...[
            Row(
              children: [
                Expanded(
                  child: Text("Gross Weight", style: Styles.blackBold12),
                ),
                Dimens.boxWidth10,
                Expanded(child: Text("Tare Weight", style: Styles.blackBold12)),
              ],
            ),

            Dimens.boxHeight8,

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: isBluetoothConnected
                      ? _LiveGrossField(
                          manualCtrl: controller.manualCtrl,
                          isTablet: isTablet,
                        )
                      : _ManualGrossField(
                          manualCtrl: controller.manualCtrl,
                          isTablet: isTablet,
                        ),
                ),

                Dimens.boxWidth5,

                Expanded(
                  child: tareState == TareState.on
                      ? _ManualTareField(
                          manualCtrl: controller.manualCtrl,
                          isTablet: isTablet,
                        )
                      : _BarcodeTareField(
                          manualCtrl: controller.manualCtrl,
                          controller: controller,
                          isTablet: isTablet,
                        ),
                ),
              ],
            ),

            Dimens.boxHeight10,
          ],

          /// 🧮 NET WEIGHT CARD (ALWAYS PRESENT)
          NetWeightDisplayCard(
            isTablet: isTablet,
            netWeight: controller.manualCtrl.manualNet,
            isUnitConversion:
                controller.selectedModuleProduct.value?.unitConversion ?? false,
            unitValue: controller.selectedModuleProduct.value?.unitValue ?? 1,

            /// 🔑 SAME LOGIC AS NON-BATCH
            isEditable: tareState == TareState.off,
            isBluetoothConnected: isBluetoothConnected,
            manualCtrl: controller.manualCtrl,
          ),
        ],
      );
    });
  }
}

// Reusable Live Gross (Bluetooth)
class _LiveGrossField extends StatelessWidget {
  final ManualWeightController manualCtrl;
  final bool isTablet;
  const _LiveGrossField({required this.manualCtrl, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final liveValue = manualCtrl.manualGross.value ?? '0';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (manualCtrl.grossCtrl.text != liveValue) {
          manualCtrl.grossCtrl.text = liveValue;
        }
      });

      return Utility.styledInputField(
        label: "Gross Weight",
        icon: Icons.scale,
        enabled: false,
        controller: manualCtrl.grossCtrl,
        suffix: Text('Kg'),
        isTablet: isTablet,
        keyboard: TextInputType.number,
        // suffixIcon: const Padding(
        //   padding: EdgeInsets.all(8.0),
        //   child: Icon(Icons.bluetooth_connected, color: Colors.green),
        // ),
      );
    });
  }
}

// Manual Gross Entry
class _ManualGrossField extends StatelessWidget {
  final ManualWeightController manualCtrl;
  final bool isTablet;
  const _ManualGrossField({required this.manualCtrl, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Utility.styledInputField(
      label: "Gross Weight",
      icon: Icons.scale,
      controller: manualCtrl.grossCtrl,
      suffix: Text('Kg'),
      isTablet: isTablet,
      keyboard: TextInputType.number,
      onChanged: (v) {
        manualCtrl.manualGross.value = v;
        manualCtrl.calculateManualNet();
      },
    );
  }
}

// Normal Tare Field (Manual Entry)
class _ManualTareField extends StatelessWidget {
  final ManualWeightController manualCtrl;
  final bool isTablet;
  const _ManualTareField({required this.manualCtrl, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Utility.styledInputField(
      label: "Tare Weight",
      icon: Icons.line_weight,
      controller: manualCtrl.tareCtrl,
      suffix: Text('Kg'),
      isTablet: isTablet,
      keyboard: TextInputType.number,
      onChanged: (v) {
        manualCtrl.manualTare.value = v;
        manualCtrl.calculateManualNet();
      },
    );
  }
}

// Barcode Tare Field (Custom UI)
class _BarcodeTareField extends StatelessWidget {
  final ManualWeightController manualCtrl;
  final BatchInwardController controller;
  final bool isTablet;
  const _BarcodeTareField({
    required this.manualCtrl,
    required this.isTablet,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Utility.styledInputField(
      label: "Scan Tare Barcode",
      icon: Icons.qr_code_scanner,
      enabled: true,
      readOnly: true,
      controller: manualCtrl.tareCtrl,
      isTablet: isTablet,
      keyboard: TextInputType.text,
      suffix: Text('Kg'),
      onTapPrefixIcon: () async {
        // TODO: Open barcode scanner
        final result = await showBarcodeScannerDialog(context);
        final scanned = result?.trim();
        if (result != null) {
          if (controller.tareProductsListModel.value?.data?.any(
                (b) => b.barCodeString?.trim() == scanned,
              ) ??
              false) {
            controller.selectedBarcode.value = controller
                .tareProductsListModel
                .value
                ?.data
                ?.firstWhere((b) => b.barCodeString?.trim() == scanned);
            Get.snackbar(
              '',
              '',
              titleText: Text('Verified'),
              messageText: Icon(
                Icons.check_circle,
                size: Dimens.fifty,
                color: Colors.green,
              ),
              snackStyle: SnackStyle.FLOATING,
            );
            var data = controller.selectedBarcode.value;
            manualCtrl.manualTare.value = data?.weight.toString();
            manualCtrl.tareCtrl.text = data?.weight.toString() ?? '0';
            manualCtrl.calculateManualNet();
          } else {
            Get.snackbar(
              '',
              '',
              titleText: Text('Unverified'),
              messageText: Icon(
                Icons.cancel,
                size: Dimens.fifty,
                color: Colors.red,
              ),
              snackStyle: SnackStyle.FLOATING,
            );
            manualCtrl.manualTare.value = '0';
            manualCtrl.tareCtrl.text = '0';
          }
        }
        if (result == null) {
          manualCtrl.tareCtrl.text = '0';
          manualCtrl.manualTare.value = '0';
          manualCtrl.calculateManualNet();
        }
      },
    );
  }
}

class NetWeightDisplayCard extends StatelessWidget {
  final bool isTablet;
  final Rxn<String> netWeight;
  final bool isUnitConversion;
  final double unitValue;
  final bool isEditable;
  final bool isBluetoothConnected;
  final ManualWeightController manualCtrl;

  const NetWeightDisplayCard({
    Key? key,
    required this.isTablet,
    required this.netWeight,
    required this.isUnitConversion,
    required this.unitValue,
    required this.isEditable,
    required this.isBluetoothConnected,
    required this.manualCtrl,
  }) : super(key: key);

  double get _netWeightValue => double.tryParse(netWeight.value ?? '0') ?? 0;
  double get _convertedValue => _netWeightValue * unitValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: Obx(() {
        // 🛠️ THE FIX: Explicitly read these observables at the root of the Obx.
        // This guarantees GetX has something to listen to, preventing the crash
        // even if the UI logic below branches into the TextField.
        netWeight.value;
        manualCtrl.manualGross.value;

        /// 🔵 Bluetooth → sync live value
        if (isEditable && isBluetoothConnected) {
          final liveValue = manualCtrl.manualGross.value ?? '0';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (manualCtrl.grossCtrl.text != liveValue) {
              manualCtrl.grossCtrl.text = liveValue;
              manualCtrl.manualNet.value = liveValue;
            }
          });
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Card(
                  margin: Dimens.edgeInsets10_0_0_0,
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: Dimens.edgeInsets10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Net Weight (Kg)",
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        /// 🟢 EDITABLE MODE
                        if (isEditable && !isBluetoothConnected)
                          TextField(
                            controller: manualCtrl.grossCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 34 : 28,
                              fontWeight: FontWeight.w900,
                              color: ColorsValue.primaryColor,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "0",
                            ),
                            onChanged: (v) {
                              manualCtrl.manualGross.value = v;
                              manualCtrl.manualNet.value = v;
                            },
                          )
                        /// 🔵 DISPLAY MODE
                        else
                          Text(
                            _netWeightValue.toStringAsFixed(3),
                            style: TextStyle(
                              fontSize: isTablet ? 34 : 28,
                              fontWeight: FontWeight.w900,
                              color: ColorsValue.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              /// 🟩 Converted Unit
              if (isUnitConversion)
                Expanded(
                  child: Card(
                    margin: Dimens.edgeInsets10_0_10_0,
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: Dimens.edgeInsets10,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Converted Unit",
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _convertedValue.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: isTablet ? 34 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/inward/batchWise/batchInwardController.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchController.dart';
import '../../../constants/sizes.dart';
import '../../../constants/styles.dart';
import '../../../constants/utility.dart';
import '../controller/inwardController.dart';
import '../batchWise/models/batchDetails.dart';

import '../../../constants/colors.dart';
import '../../../constants/enums.dart';
import '../../scanner/scannerDailog.dart';

class NonBatchBluetoothWeightSection extends StatelessWidget {
  final bool isTablet;
  final DashboardController dashboardController;
  final NonBatchInwardController controller;

  const NonBatchBluetoothWeightSection({
    Key? key,
    required this.isTablet,
    required this.dashboardController,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tareState = dashboardController.tareState.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔵 TARE ON → GROSS + TARE UI
          if(tareState != TareState.off) ...[
            Row(
              children: [
                Expanded(child: Text("Gross Weight", style: Styles.blackBold12)),
                Dimens.boxWidth10,
                Expanded(child: Text("Tare Weight", style: Styles.blackBold12)),
              ],
            ),

            Dimens.boxHeight8,

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: dashboardController.isWeightScaleConnected.value
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

          NetWeightDisplayCard(
            isTablet: isTablet,
            netWeight: controller.manualCtrl.manualNet,
            isUnitConversion:
            controller.selectedProduct.value?.unitConversion ?? false,
            unitValue:
            controller.selectedProduct.value?.unitValue ?? 1,

            /// 👇 KEY LOGIC
            isEditable: dashboardController.tareState.value == TareState.off,
            isBluetoothConnected:
            dashboardController.isWeightScaleConnected.value &&
                dashboardController.connectedDevice.value != null,
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
        isTablet: isTablet, keyboard: TextInputType.number,
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
  final NonBatchInwardController controller;
  final bool isTablet;
  const _BarcodeTareField({required this.manualCtrl, required this.isTablet, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Utility.styledInputField(
      label: "Scan Tare Barcode",
      icon: Icons.qr_code_scanner,
      enabled: true,
      readOnly: true,
      controller: manualCtrl.tareCtrl,
      isTablet: isTablet, keyboard: TextInputType.text,
      suffix: Text('Kg'),
      onTapPrefixIcon:() async {
        // TODO: Open barcode scanner
        final result = await showBarcodeScannerDialog(
          context,
        );
        final scanned = result?.trim();
        if (result != null) {

          if (controller.tareProductsListModel.value?.data?.any(
                (b) => b.barCodeString?.trim() == scanned,
          ) ??
              false) {
            controller.selectedBarcode.value = controller
                .tareProductsListModel.value?.data
                ?.firstWhere(
                  (b) =>
              b.barCodeString?.trim() == scanned,
            );
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
            manualCtrl.manualTare.value =
                data?.weight.toString();
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

  final bool isEditable; // 👈 NEW
  final bool isBluetoothConnected; // 👈 NEW
  final ManualWeightController manualCtrl; // 👈 NEW

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

  // double get _netWeightValue =>
  //     double.tryParse(netWeight.value ?? '0') ?? 0;
  //
  // double get _convertedValue => _netWeightValue * unitValue;

  @override
  Widget build(BuildContext context) {
   return IntrinsicHeight(

     child: Obx((){
       final net = double.tryParse(netWeight.value ?? '0') ?? 0;
       final converted = net * unitValue;

       return  Row(
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
                           // helperText: "0"
                         ),
                         onChanged: (v) {
                           manualCtrl.manualGross.value = v;
                           manualCtrl.manualNet.value = v;
                         },
                       )

                     /// 🔵 DISPLAY MODE
                     else
                       Text(
                         net.toStringAsFixed(2),
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
                       Text("Converted Unit", style: TextStyle(
                         fontSize: isTablet ? 22 : 18,
                         fontWeight: FontWeight.w600,
                       ),),

                       Text(
                         converted.toStringAsFixed(2),
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
       );
     })
   );
  }
}


/// Professional, Animated & Reusable Action Bar for Inward/Dispatch
class NonBatchInwardActionBar extends StatelessWidget {
  final NonBatchInwardController controller;
  final bool isTablet;
  final BuildContext context;
  const NonBatchInwardActionBar({
    super.key,
    required this.controller,
    required this.isTablet, required this.context,
  });

  // Define button config based on state
  List<_ActionButtonConfig> _getButtons() {
    final bool isAutoEnabled = controller.isBatchAutoWeightEnabled.value;

    if (!isAutoEnabled) {
      final IconData mainIcon = controller.inwardState.value == InwardState.running
          ? Icons.pause_circle_filled
          : Icons.play_circle_filled;

      final Color mainColor = controller.inwardState.value == InwardState.running
          ? Colors.orange
          : Colors.green;

      final String mainLabel = controller.inwardState.value == InwardState.running
          ? "Pause"
          : (controller.inwardState.value == InwardState.paused ? "Resume" : "Start");
      return [
        _ActionButtonConfig(
          icon: Icons.add_circle,
          color: ColorsValue.primaryColor,
          label: "Add Entry",
          onTap:() async{
            await controller.addToList();}
        ), _ActionButtonConfig(
          icon: mainIcon,
          color: mainColor,
          label: mainLabel,
          onTap: () async {
            if (controller.inwardState.value == InwardState.running) {
              if(!controller.validateTransactionName()) {
                return;
              }else{
                await controller.onPauseOrStop(pauseOrStop: 'pause');
              }
            }
          }
        ),
        _ActionButtonConfig(
          icon: Icons.save,
          color: Colors.red,
          label: "Save",
          onTap: controller.onTapStop,
        ),
      ];
    }

    // Auto mode: Dynamic play/pause based on state
    final IconData mainIcon = controller.inwardState.value == InwardState.running
        ? Icons.pause_circle_filled
        : Icons.play_circle_filled;

    final Color mainColor = controller.inwardState.value == InwardState.running
        ? Colors.orange
        : Colors.green;

    final String mainLabel = controller.inwardState.value == InwardState.running
        ? "Pause"
        : (controller.inwardState.value == InwardState.paused ? "Resume" : "Start Auto");

    return [
      _ActionButtonConfig(
        icon: mainIcon,
        color: mainColor,
        label: mainLabel,
        onTap: controller.onTapMain,
        pulse: controller.inwardState.value == InwardState.running, // Pulse when running
      ),
      _ActionButtonConfig(
        icon: Icons.stop_circle,
        color: Colors.red,
        label: "Stop",
        onTap: controller.onTapStop,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final buttons = _getButtons();

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((config) {
          return AnimatedScaleButton(
            icon: config.icon,
            color: config.color,
            label: config.label,
            isTablet: isTablet,
            onTap: config.onTap,
            pulse: config.pulse,
          );
        }).toList(),
      );
    });
  }
}

// Config class
class _ActionButtonConfig {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool pulse;

  _ActionButtonConfig({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.pulse = false,
  });
}
class AnimatedScaleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isTablet;
  final VoidCallback onTap;
  final bool pulse;

  const AnimatedScaleButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isTablet,
    required this.onTap,
    this.pulse = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double size = isTablet ? 72 : 60;
    final double iconSize = isTablet ? 36 : 30;
    final double fontSize = isTablet ? 14 : 12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: pulse
              ? _PulsingButton(
            size: size,
            iconSize: iconSize,
            icon: icon,
            color: color,
            onTap: onTap,
          )
              : _StaticButton(
            size: size,
            iconSize: iconSize,
            icon: icon,
            color: color,
            onTap: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

// Pulsing effect when auto-weighing is running
class _PulsingButton extends StatefulWidget {
  final double size;
  final double iconSize;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PulsingButton({
    required this.size,
    required this.iconSize,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _StaticButton(
            size: widget.size,
            iconSize: widget.iconSize,
            icon: widget.icon,
            color: widget.color,
            onTap: widget.onTap,
          ),
        );
      },
    );
  }
}

// Reusable static FAB-style button
class _StaticButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StaticButton({
    required this.size,
    required this.iconSize,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

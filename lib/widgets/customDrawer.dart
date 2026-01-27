import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/enums.dart';
import 'package:punit_label/constants/sizes.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/dispatch/view/dispatchScreen.dart';
import 'package:punit_label/features/inward/view/inwardScreen.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/utility.dart';
import '../features/tare/tareView.dart';
class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});

  final DashboardController dashController = Get.find();

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Drawer(
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
                _drawerItem(
                  icon: Icons.archive,
                  title: 'Inward',
                  onTap: () {
                    if (dashController.enableInward.value) {
                      Get.to(() => InwardScreen());
                    } else {
                      Utility.showDialog('Access Denied');
                    }
                  },
                ),

                _drawerItem(
                  icon: Icons.local_shipping,
                  title: 'Dispatch',
                  onTap: () {
                    if (dashController.enableDispatch.value) {
                      Get.to(() => DispatchScreen());
                    } else {
                      Utility.showDialog('Access Denied');
                    }
                  },
                ),

                _drawerItem(
                  icon: Icons.line_weight,
                  title: 'Tare Products',
                  onTap: () => Get.to(() => AddTareProductsView()),
                ),

               Dimens.boxHeight12,
                Divider(),
                _sectionTitle("Tare Weight"),
                Dimens.boxHeight12,
                Obx(
                      () => ThreeLevelSelector(
                    value: dashController.tareState.value,
                    isTablet: isTablet,
                    onChanged: (state) {
                      dashController.tareState.value = state;
                      if (state == TareState.off) {
                        dashController.manualBatchWeights.manualTare.value = '0';
                        dashController.manualBatchWeights.tareCtrl.text = '0';
                        dashController.manualNonBatchWeights.manualTare.value = '0';
                        dashController.manualNonBatchWeights.tareCtrl.text = '0';
                      }
                    },
                  ),
                ),

                Dimens.boxHeight24,
                Divider(),
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

                Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text(
                    "Logout",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Get.offAllNamed('/login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Header
  Widget _header({ required DashboardController dashboardController}) {
    return Container(
      height: 225,
      width: Get.width,
      padding: Dimens.edgeInsets0_0_0_30,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: ColorsValue.primaryColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
           CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 42, color: ColorsValue.primaryColor,),
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
        ],
      ),
    );
  }

  /// 🔹 Drawer item
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ColorsValue.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }

  /// 🔹 Section title
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Styles.primaryBold14,
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
          _divider(),
          _option(
            label: "ON",
            level: TareState.on,
            selected: value == TareState.on,
          ),
          _divider(),
          _option(
            label: "Barcode",
            level: TareState.barcode,
            selected: value == TareState.barcode,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 24, width: 1.5, color: Colors.grey.shade300);
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
              ? ColorsValue.primaryColor.withOpacity(0.8)
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

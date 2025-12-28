import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/enums.dart';
import 'package:punit_label/constants/sizes.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/dispatch/view/dispatchScreen.dart';
import 'package:punit_label/features/inward/view/inwardScreen.dart';

import '../constants/colors.dart';
import '../constants/utility.dart';
import '../features/tare/tareView.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});
  final dashController = Get.find<DashboardController>();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 600;
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: ColorsValue.primaryColor,
              borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: ColorsValue.primaryColor,
                  ),
                ),
                Dimens.boxHeight12,

                Text(
                  "Welcome User",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // MENU ITEMS
          // _drawerItem(
          //   icon: Icons.dashboard,
          //   title: 'Dashboard',
          //   onTap: () => Get.toNamed('/dashboard'),
          // ),
          // _drawerItem(
          //   icon: Icons.inventory,
          //   title: 'Inventory',
          //   onTap: () => Get.toNamed('/inventory'),
          // ),
          _drawerItem(
            icon: Icons.input,
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
            icon: Icons.local_shipping_outlined,
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
          Obx(
            () => ThreeLevelSelector(
              value: dashController.tareState.value,
              onChanged: (newLevel) {
                dashController.tareState.value = newLevel;
                if (dashController.tareState.value == TareState.off) {
                  dashController.manualBatchWeights.manualTare.value = '0';
                  dashController.manualBatchWeights.tareCtrl.text = '0';
                  dashController.manualNonBatchWeights.tareCtrl.text = '0';
                  dashController.manualNonBatchWeights.manualTare.value = '0';

                }
              },
              isTablet: isTablet,
            ),
          ),
          // LOGOUT
          ListTile(
            leading: Icon(Icons.logout, color: ColorsValue.primaryColor),
            title: Text(
              "Logout",
              style: TextStyle(
                color: ColorsValue.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Get.offAllNamed('/login');
            },
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ColorsValue.primaryColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Get.back();
        onTap();
      },
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

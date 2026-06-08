import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/login/loginmodel.dart';
import 'package:punit_label/widgets/usbSerial.dart';

import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../features/dashboard/dashboardController.dart';
import 'bluetooth_bottomsheet.dart';

void _disconnectDialog(BuildContext context, String title, Function onConfirm) {
  Get.defaultDialog(
    title: title,
    titleStyle: const TextStyle(fontWeight: FontWeight.bold),
    middleText: "Are you sure you want to $title?",
    backgroundColor: Colors.white,
    radius: 10,
    confirm: ElevatedButton.icon(
      onPressed: () async {
        Get.back();
        await onConfirm();
      },
      label: const Text("Yes", style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.check, color: Colors.white),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    ),
    cancel: ElevatedButton.icon(
      onPressed: () => Get.back(),
      label: const Text("No", style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.close, color: Colors.white),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsValue.primaryColor,
      ),
    ),
  );
}

void _showUserDetailsDialog(BuildContext context, UserProfile? user) async {
  if (user == null) {
    Get.snackbar("No User", "User details not found");
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              Center(
                child: Text(
                  "USER DETAILS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: ColorsValue.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              /// Name
              _detailRow("Name", user.name ?? "-"),

              /// Email
              _detailRow("Email", user.email ?? "-"),

              /// Inventory User
              _detailRow(
                "Inventory User",
                (user.inventoryUser ?? false) ? "Yes" : "No",
              ),

              /// Dispatch User
              _detailRow(
                "Dispatch User",
                (user.dispatchUser ?? false) ? "Yes" : "No",
              ),

              /// Company Code
              _detailRow("Company Code", user.companyCode ?? "-"),

              const SizedBox(height: 20),

              /// Close Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Small helper widget
Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

class AppBarSizing {
  final double iconSize;
  final double badgeIconSize;
  final double radius;
  final double titleFont;
  final double toolbarHeight;

  AppBarSizing(double width)
    : iconSize = AppLayoutSpec.fromWidth(width).isExpandedTablet
          ? 26
          : AppLayoutSpec.fromWidth(width).isTablet
          ? 24
          : 20,
      badgeIconSize = AppLayoutSpec.fromWidth(width).isTablet ? 16 : 13,
      radius = AppLayoutSpec.fromWidth(width).isTablet ? 22 : 18,
      titleFont = AppLayoutSpec.fromWidth(width).appBarTitleFont,
      toolbarHeight = AppLayoutSpec.fromWidth(width).toolbarHeight;
}

class StatusIconButton extends StatelessWidget {
  final bool connected;
  final IconData icon;
  final VoidCallback onPressed;
  final AppBarSizing size;
  final String tooltip;

  const StatusIconButton({
    super.key,
    required this.connected,
    required this.icon,
    required this.onPressed,
    required this.size,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onPressed,
      icon: Badge(
        alignment: Alignment.topRight,
        backgroundColor: connected ? Colors.green : Colors.red,
        padding: EdgeInsets.zero,
        label: Icon(
          connected ? Icons.check_circle : Icons.dangerous,
          color: Colors.white,
          size: size.badgeIconSize,
        ),
        child: Container(
          width: size.radius * 2,
          height: size.radius * 2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, color: Colors.white, size: size.iconSize),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  CustomAppBar({
    super.key,
    required this.title,
    required this.showScale,
    required this.showPrinter,
    required this.showUser,
    required this.showDrawer,
  });

  final bool showPrinter;
  final bool showUser;
  final bool showDrawer;
  final bool showScale;
  final String title;

  final dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    final sizing = AppBarSizing(MediaQuery.of(context).size.width);

    return AppBar(
      toolbarHeight: sizing.toolbarHeight,
      backgroundColor: ColorsValue.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      titleSpacing: showDrawer ? 4 : 16,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsValue.primaryColor,
              ColorsValue.primaryColor.withValues(alpha: 0.92),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),

      title: Text(
        title.toUpperCase(),
        style: Styles.whiteBold22.copyWith(fontSize: sizing.titleFont),
      ),

      leading: showDrawer
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,

      actions: [
        if (showScale) _scaleButton(sizing),
        if (showPrinter) _printerButton(sizing),
        Obx(() {
          if (!dashboardController.isTowerLight.value) {
            return const SizedBox.shrink();
          }
          return _towerLightButton(sizing);
        }),
        if (showUser) _userButton(sizing),
        _logoutButton(sizing),
        const SizedBox(width: 8),
      ],
    );
  }

  // ---------------- Buttons ----------------

  Widget _scaleButton(AppBarSizing s) {
    return Obx(
      () => StatusIconButton(
        size: s,
        tooltip: 'Scale',
        icon: Icons.scale_rounded,
        connected: dashboardController.isAnyScaleConnected,
        onPressed: () {
          if (dashboardController.isAnyScaleConnected) {
            _disconnectDialog(
              Get.context!,
              "disconnect scale",
              dashboardController.disconnectActiveScale,
            );
            return;
          }

          showScaleConnectionSheet(Get.context!, dashboardController);
        },
      ),
    );
  }

  Widget _printerButton(AppBarSizing s) {
    return Obx(() {
      final isLabelMode = dashboardController.isLabelPrinterMode.value;
      final isConnected = isLabelMode
          ? dashboardController.isPrinterConnected.value
          : dashboardController.bluetoothController.isConnected.value;

      return StatusIconButton(
        size: s,
        tooltip: isLabelMode ? 'Printer' : 'Receipt Printer',
        icon: isLabelMode ? Icons.print_rounded : Icons.receipt_long_rounded,
        connected: isConnected,
        onPressed: () {
          if (isConnected) {
            _disconnectDialog(
              Get.context!,
              isLabelMode ? "disconnect printer" : "disconnect receipt printer",
              dashboardController.disconnectActivePrinter,
            );
            return;
          }

          isLabelMode
              ? showPrinterConnectionSheet(Get.context!, dashboardController)
              : dashboardController.bluetoothController.openDeviceBottomSheet();
        },
      );
    });
  }

  Widget _towerLightButton(AppBarSizing s) {
    return Obx(
      () => StatusIconButton(
        size: s,
        tooltip: 'Tower Light',
        icon: Icons.cell_tower,
        connected: dashboardController.tower_controller.isConnected.value,
        onPressed: () => showTowerLightSheet(
          Get.context!,
          dashboardController.tower_controller,
        ),
      ),
    );
  }

  Widget _userButton(AppBarSizing s) {
    return IconButton(
      tooltip: 'User Details',
      iconSize: s.iconSize,
      onPressed: () => _showUserDetailsDialog(
        Get.context!,
        dashboardController.userDetails.value,
      ),
      icon: Container(
        width: s.radius * 2,
        height: s.radius * 2,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(
          Icons.account_circle_sharp,
          color: Colors.white,
          size: s.iconSize,
        ),
      ),
    );
  }

  Widget _logoutButton(AppBarSizing s) {
    return IconButton(
      tooltip: 'Logout',
      iconSize: s.iconSize,
      icon: Container(
        width: s.radius * 2,
        height: s.radius * 2,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(
          Icons.logout_rounded,
          color: Colors.white,
          size: s.iconSize,
        ),
      ),
      onPressed: () =>
          _disconnectDialog(Get.context!, "logout", dashboardController.logout),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

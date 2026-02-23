import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/login/loginmodel.dart';
import 'package:punit_label/widgets/usbSerial.dart';

import '../apis/sharedPreference.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../constants/strings.dart';
import '../constants/styles.dart';
import '../features/dashboard/dashboardController.dart';
import 'bluetooth_bottomsheet.dart';
/*

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
    final width = MediaQuery.of(context).size.width;

    /// -------------------------------
    /// RESPONSIVE VALUES
    /// -------------------------------
    final bool isTablet = width > 600;
    final double iconSize = isTablet ? 32 : 24;
    final double badgeIconSize = isTablet ? 20 : 15;
    final double circleRadius = isTablet ? 26 : 20;
    final double titleFont = isTablet ? 22 : 16;

    return AppBar(
      title: Text(
        title.toUpperCase(),
        //style: TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w900,color: Colors.white),
        style: Styles.whiteBold22.copyWith(fontSize: titleFont),
      ),

      leading: showDrawer
          ? Builder(
              builder: (context) {
                return IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    // This is the MOST RELIABLE way
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            )
          : null,

      actions: [
        /// ---------------------------
        /// SCALE BUTTON
        /// ---------------------------
        if (showScale)
          IconButton(
            iconSize: iconSize,
            onPressed: () {
              if (dashboardController.isWeightScaleConnected.value) {
                _disconnectDialog(
                  context,
                  "Scale",
                  dashboardController.disconnectDevice,
                );
              } else {
                showBluetoothSheet(
                  context,
                  dashboardController,
                  SStringConstants.role_scale,
                );
              }
            },
            icon: Obx(
              () => Badge(
                alignment: Alignment.topRight,
                label: Icon(
                  dashboardController.isWeightScaleConnected.value
                      ? Icons.check_circle
                      : Icons.dangerous,
                  color: Colors.white,
                  size: badgeIconSize,
                ),
                padding: EdgeInsets.zero,
                backgroundColor:
                    dashboardController.isWeightScaleConnected.value
                    ? Colors.green
                    : Colors.red,
                child: CircleAvatar(
                  radius: circleRadius,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.scale, color: Colors.white, size: iconSize),
                ),
              ),
            ),
          ),

        /// ---------------------------
        /// PRINTER BUTTON
        /// ---------------------------
        // if (showPrinter)
        */
/*IconButton(
            iconSize: iconSize,
            onPressed: () {
              showBluetoothPrinterSheet(
                context,
                dashboardController,
                SStringConstants.role_printer,
              );
            },
            icon: Obx(
              () => Badge(
                alignment: Alignment.topRight,
                label: Icon(
                  dashboardController.isPrinterConnected.value
                      ? Icons.check_circle
                      : Icons.dangerous,
                  color: Colors.white,
                  size: badgeIconSize,
                ),
                padding: EdgeInsets.zero,
                backgroundColor: dashboardController.isPrinterConnected.value
                    ? Colors.green
                    : Colors.red,
                child: CircleAvatar(
                  radius: circleRadius,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.print, color: Colors.white, size: iconSize),
                ),
              ),
            ),
          ),*//*

        if (showPrinter)
          Obx(
            () => dashboardController.isLabelPrinterMode.value
                ? IconButton(
                    iconSize: iconSize,
                    onPressed: () {
                      showBluetoothPrinterSheet(
                        context,
                        dashboardController,
                        SStringConstants.role_printer,
                      );
                    },
                    icon: Obx(
                      () => Badge(
                        alignment: Alignment.topRight,
                        label: Icon(
                          dashboardController.isPrinterConnected.value
                              ? Icons.check_circle
                              : Icons.dangerous,
                          color: Colors.white,
                          size: badgeIconSize,
                        ),
                        padding: EdgeInsets.zero,
                        backgroundColor:
                            dashboardController.isPrinterConnected.value
                            ? Colors.green
                            : Colors.red,
                        child: CircleAvatar(
                          radius: circleRadius,
                          backgroundColor: Colors.white12,
                          child: Icon(
                            Icons.print,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    iconSize: iconSize,
                    onPressed: () {
                      // showBluetoothPrinterSheet(
                      //   context,
                      //   dashboardController,
                      //   SStringConstants.role_printer,
                      // );
                      dashboardController.bluetoothController
                          .openDeviceBottomSheet();
                    },
                    icon: Badge(
                      alignment: Alignment.topRight,
                      label: Icon(
                        dashboardController
                                .bluetoothController
                                .isConnected
                                .value
                            ? Icons.check_circle
                            : Icons.dangerous,
                        color: Colors.white,
                        size: badgeIconSize,
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          dashboardController
                              .bluetoothController
                              .isConnected
                              .value
                          ? Colors.green
                          : Colors.red,
                      child: CircleAvatar(
                        radius: circleRadius,
                        backgroundColor: Colors.white12,
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ),
          ),
        // if (showPrinter)
        */
/*dashboardController.isLabelPrinterMode.value
            ? IconButton(
                iconSize: iconSize,
                onPressed: () {
                  showBluetoothPrinterSheet(
                    context,
                    dashboardController,
                    SStringConstants.role_printer,
                  );
                },
                icon: Obx(
                  () => Badge(
                    alignment: Alignment.topRight,
                    label: Icon(
                      dashboardController.isPrinterConnected.value
                          ? Icons.check_circle
                          : Icons.dangerous,
                      color: Colors.white,
                      size: badgeIconSize,
                    ),
                    padding: EdgeInsets.zero,
                    backgroundColor:
                        dashboardController.isPrinterConnected.value
                        ? Colors.green
                        : Colors.red,
                    child: CircleAvatar(
                      radius: circleRadius,
                      backgroundColor: Colors.white12,
                      child: Icon(
                        Icons.print,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              )
            : IconButton(
                iconSize: iconSize,
                onPressed: () {
                  // showBluetoothPrinterSheet(
                  //   context,
                  //   dashboardController,
                  //   SStringConstants.role_printer,
                  // );
                  dashboardController.bluetoothController.openDeviceBottomSheet();
                },
                icon: Badge(
                  alignment: Alignment.topRight,
                  label: Icon(
                    dashboardController.bluetoothController.isConnected.value
                        ? Icons.check_circle
                        : Icons.dangerous,
                    color: Colors.white,
                    size: badgeIconSize,
                  ),
                  padding: EdgeInsets.zero,
                  backgroundColor:
                  dashboardController.bluetoothController.isConnected.value
                      ? Colors.green
                      : Colors.red,
                  child: CircleAvatar(
                    radius: circleRadius,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                ),
              ),*//*


        /// ---------------------------
        /// TOWER LIGHT BUTTON
        /// ---------------------------
        if (showUser)
          IconButton(
            iconSize: iconSize,
            onPressed: () {
              showTowerLightSheet(context, dashboardController.tower_controller);
            },
            icon: Badge(
              alignment: Alignment.topRight,
              label: Icon(
                dashboardController.tower_controller.isConnected.value
                    ? Icons.check_circle
                    : Icons.dangerous,
                color: Colors.white,
                size: badgeIconSize,
              ),
              padding: EdgeInsets.zero,
              backgroundColor:
                  dashboardController.tower_controller.isConnected.value
                  ? Colors.green
                  : Colors.red,
              child: CircleAvatar(
                radius: circleRadius,
                backgroundColor: Colors.white12,
                child: Icon(
                  Icons.cell_tower,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),

            */
/*Obx(
                  () => Badge(
                alignment: Alignment.topRight,
                label: Icon(
                  dashboardController.isPrinterConnected.value
                      ? Icons.check_circle
                      : Icons.dangerous,
                  color: Colors.white,
                  size: badgeIconSize,
                ),
                padding: EdgeInsets.zero,
                backgroundColor: dashboardController.isPrinterConnected.value
                    ? Colors.green
                    : Colors.red,
                child: CircleAvatar(
                  radius: circleRadius,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.print, color: Colors.white, size: iconSize),
                ),
              ),
            ),*//*

          ),

        /// ---------------------------
        /// USER INFO BUTTON
        /// ---------------------------
        if (showUser)
          IconButton(
            iconSize: iconSize,
            onPressed: () {
              /// Logic to show dailog box with the details of user who logged in
              _showUserDetailsDialog(
                context,
                dashboardController.userDetails.value,
              );
            },
            icon: CircleAvatar(
              radius: circleRadius,
              backgroundColor: Colors.white12,
              child: Icon(
                Icons.account_circle_sharp,
                color: Colors.white,
                size: iconSize,
              ),
            ),

            */
/*Obx(
                  () => Badge(
                alignment: Alignment.topRight,
                label: Icon(
                  dashboardController.isPrinterConnected.value
                      ? Icons.check_circle
                      : Icons.dangerous,
                  color: Colors.white,
                  size: badgeIconSize,
                ),
                padding: EdgeInsets.zero,
                backgroundColor: dashboardController.isPrinterConnected.value
                    ? Colors.green
                    : Colors.red,
                child: CircleAvatar(
                  radius: circleRadius,
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.print, color: Colors.white, size: iconSize),
                ),
              ),
            ),*//*

          ),

        /// ---------------------------
        /// LOGOUT BUTTON
        /// ---------------------------
        IconButton(
          iconSize: iconSize,
          onPressed: () {
            _disconnectDialog(context, "Logout", dashboardController.logout);
          },
          icon: Icon(Icons.logout, color: Colors.white),
        ),
      ],
      elevation: 0,
      backgroundColor: ColorsValue.primaryColor,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56); // Adjusted for tablet
}
*/

void _disconnectDialog(BuildContext context, String title, Function onConfirm) {
  Get.defaultDialog(
    title: title,
    titleStyle: const TextStyle(fontWeight: FontWeight.bold),
    middleText: "Are you sure you want to $title?",
    backgroundColor: Colors.white,
    radius: 10,
    confirm: ElevatedButton.icon(
      onPressed: () {
        Get.back();
        onConfirm();
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

  AppBarSizing(double width)
      : iconSize = width > 600 ? 32 : 24,
        badgeIconSize = width > 600 ? 20 : 15,
        radius = width > 600 ? 26 : 20,
        titleFont = width > 600 ? 22 : 16;
}

class StatusIconButton extends StatelessWidget {
  final bool connected;
  final IconData icon;
  final VoidCallback onPressed;
  final AppBarSizing size;

  const StatusIconButton({
    super.key,
    required this.connected,
    required this.icon,
    required this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: size.iconSize,
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
        child: CircleAvatar(
          radius: size.radius,
          backgroundColor: Colors.white12,
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
      backgroundColor: ColorsValue.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,

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
      ],
    );
  }

  // ---------------- Buttons ----------------

  Widget _scaleButton(AppBarSizing s) {
    return Obx(() => StatusIconButton(
      size: s,
      icon: Icons.scale,
      connected: dashboardController.isWeightScaleConnected.value,
      onPressed: () {
        dashboardController.isWeightScaleConnected.value
            ? _disconnectDialog(
            Get.context!, "Scale", dashboardController.disconnectDevice)
            : showBluetoothSheet(
          Get.context!,
          dashboardController,
          SStringConstants.role_scale,
        );
      },
    ));
  }

  Widget _printerButton(AppBarSizing s) {
    return Obx(() {
      final isLabelMode = dashboardController.isLabelPrinterMode.value;
      final isConnected = isLabelMode
          ? dashboardController.isPrinterConnected.value
          : dashboardController.bluetoothController.isConnected.value;

      return StatusIconButton(
        size: s,
        icon: isLabelMode ? Icons.print : Icons.receipt_long,
        connected: isConnected,
        onPressed: () {
          isLabelMode
              ? showBluetoothPrinterSheet(
            Get.context!,
            dashboardController,
            SStringConstants.role_printer,
          )
              : dashboardController.bluetoothController
              .openDeviceBottomSheet();
        },
      );
    });
  }

  Widget _towerLightButton(AppBarSizing s) {
    return Obx(() => StatusIconButton(
      size: s,
      icon: Icons.cell_tower,
      connected:
      dashboardController.tower_controller.isConnected.value,
      onPressed: () => showTowerLightSheet(
        Get.context!,
        dashboardController.tower_controller,
      ),
    ));
  }

  Widget _userButton(AppBarSizing s) {
    return IconButton(
      iconSize: s.iconSize,
      onPressed: () => _showUserDetailsDialog(
        Get.context!,
        dashboardController.userDetails.value,
      ),
      icon: CircleAvatar(
        radius: s.radius,
        backgroundColor: Colors.white12,
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
      iconSize: s.iconSize,
      icon: const Icon(Icons.logout, color: Colors.white),
      onPressed: () =>
          _disconnectDialog(Get.context!, "Logout", dashboardController.logout),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
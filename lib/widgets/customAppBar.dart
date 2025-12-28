import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/login/loginmodel.dart';

import '../apis/sharedPreference.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../constants/strings.dart';
import '../constants/styles.dart';
import '../features/dashboard/dashboardController.dart';
import 'bluetooth_bottomsheet.dart';

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

      leading: showDrawer ?  Builder(
        builder: (context) {
          return IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // This is the MOST RELIABLE way
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ) : null,

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
        if (showPrinter)
          IconButton(
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
            ),*/
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

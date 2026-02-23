import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:punit_label/apis/connectHelper.dart';
import 'package:punit_label/navigation/routesManagement.dart';
import 'package:share_plus/share_plus.dart';
import '/constants/sizes.dart';
import '/constants/strings.dart';
import '/constants/styles.dart';
import 'package:url_launcher/url_launcher.dart';

import '../apis/responseModel.dart';
import 'colors.dart';
import 'enums.dart';

abstract class Utility {
  /// Print debug log.
  ///
  /// [message] : The message which needed to be print.
  static void printDLog(String message) {
    Logger().d('${SStringConstants.appName}: $message');
  }

  /// Print info log.
  ///
  /// [message] : The message which needed to be print.
  static void printLog(dynamic message) {
    Logger().log(Level.info, message);
  }

  /// Print info log.
  ///
  /// [message] : The message which needed to be print.
  static void printILog(String message) {
    Logger().i('${SStringConstants.appName}: $message');
  }

  /// Print error log.
  ///
  /// [message] : The message which needed to be print.
  static void printELog(String message) {
    Logger().e('${SStringConstants.appName}: $message');
  }

  /// Log writer for get
  ///
  static void localLogWriter(String message, {bool isError = false}) {
    if (isError) {
      printELog(message);
    } else {
      printILog(message);
    }
  }

  /// Returns true if the internet connection is available.
  static Future<bool> isNetworkAvailable() async =>
      await InternetConnectionChecker().hasConnection;

  /// Show loader
  static void showLoader() async {
    await Get.dialog<dynamic>(
      WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Center(
          child: CircularProgressIndicator.adaptive(
            backgroundColor: GetPlatform.isIOS
                ? ColorsValue.primaryColor
                : null,
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(.4),
    );
  }

  /// Close any open dialog.
  static void closeDialog() {
    // if (Get.isDialogOpen ?? false) Get.back<dynamic>();
    debugPrint('Start: Close Dialog ${Get.isDialogOpen}');
    if (Get.isDialogOpen ?? true) {
      //   // Navigator.of(Get.context!, rootNavigator: true);
      Get.back<void>();
    }
    debugPrint('End: Close Dialog ${Get.isDialogOpen}');
  }

  /// Show error dialog from response model
  static Future<void> showInfoDialog(
    ResponseModel data, {
    bool isSuccess = false,
  }) async {
    await Get.dialog<dynamic>(
      CupertinoAlertDialog(
        title: Text(
          isSuccess ? 'SUCCESS' : 'ERROR',
          style: isSuccess
              ? Styles.primaryColouredBold14
              : Styles.blackBold14.copyWith(color: Colors.red),
        ),
        content: Text(
          jsonDecode(data.data)['data'] as String,
          style: Styles.blackMedium14,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: Get.back,
            isDefaultAction: true,
            child: Text('OKAY'.tr, style: Styles.primaryColouredBold14),
          ),
        ],
      ),
    );
  }

  /// Show info dialog
  static Future<void> showDialog(
    String message, {
    Function()? onPress,
    bool barrierDismissible = true,
  }) async {
    await Get.dialog<void>(
      CupertinoAlertDialog(
        title: Text('INFO', style: Styles.primaryColouredBold14),
        content: Text(message, style: Styles.black14),
        actions: [
          CupertinoButton(
            onPressed: onPress ?? Get.back,
            child: Text('Okay', style: Styles.primaryColouredBold14),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }
  static sharePdfFile(String pdfPath){
    //SharePlus.instance.share([XFile(pdfPath)]);
     Share.shareXFiles([XFile(pdfPath)]);
  }
  static String formatTimestamp(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  }

  static double? toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
  static int? toInteger(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static DateTime nowWithoutSeconds() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }
  static Widget styledInputField({
    required String label,
    required IconData icon,
    required TextInputType keyboard,
    required bool isTablet,
    TextEditingController? controller,
    Function(String)? onChanged,
    bool enabled = true,
    bool readOnly = false,
    Widget? suffix,
    VoidCallback? onTapPrefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: TextField(
        enabled: enabled,
        keyboardType: keyboard,
        readOnly: readOnly,
        controller: controller,
        style: TextStyle(fontSize: isTablet ? 24 : 18),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: IconButton(
            icon: Icon(icon, color: ColorsValue.primaryColor),
            color: ColorsValue.primaryColor,
            onPressed: onTapPrefixIcon,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          suffix: suffix,
        ),
        onChanged: onChanged,
      ),
    );
  }
  static Widget styledInputSerialNumberField({
    required String label,
    required IconData icon,
    required TextInputType keyboard,
    required bool isTablet,
    TextEditingController? controller,
    Function(String)? onChanged,
    bool enabled = true,
    bool readOnly = false,
    Widget? suffix,
    VoidCallback? onTapPrefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: TextField(
        enabled: enabled,
        keyboardType: keyboard,
        readOnly: readOnly,
        controller: controller,
        // ✅ BLOCK NON-NUMERIC INPUT
        inputFormatters: keyboard == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style: TextStyle(fontSize: isTablet ? 24 : 18),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: IconButton(
            icon: Icon(icon, color: ColorsValue.primaryColor),
            color: ColorsValue.primaryColor,
            onPressed: onTapPrefixIcon,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          suffix: suffix,
        ),
        onChanged: onChanged,
      ),
    );
  }

  static String generateBarcode({required int id}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final base36 = now.toRadixString(36); // convert timestamp to alphanumeric
    final rand = Random()
        .nextInt(36 * 36)
        .toRadixString(36)
        .padLeft(2, '0'); // 2 random chars
    final barcode = (base36 + rand).substring(base36.length - 4) + id.toString();
    return barcode;
  }

  static Widget styledDropdown({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: child,
      ),
    );
  }

  static Future<void> showErrorDialog(
    String message, {
    Function()? onPress,
    bool barrierDismissible = true,
  }) async {
    await Get.dialog<void>(
      CupertinoAlertDialog(
        title: Text(
          'ERROR',
          style: Styles.primaryColouredBold14.copyWith(color: Colors.red),
        ),
        content: Text(message, style: Styles.black14),
        actions: [
          CupertinoButton(
            onPressed: onPress ?? Get.back,
            child: Text('Okay', style: Styles.primaryColouredBold14),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  // static void showApiErrorSnackbar(ResponseModel response) {
  //   var data = jsonDecode(response.data);
  //   var title = response.data;
  //   if (data['message'] != null) {
  //     title = data['message'];
  //   }
  //   if (response.errorCode == 401) {
  //     title = SStringConstants.tokenExpired;
  //   }
  //   Get.snackbar(
  //     title,
  //     "Status Code :- ${response.errorCode.toString()}",
  //     snackPosition: SnackPosition.BOTTOM,
  //     backgroundColor: Colors.red,
  //     colorText: Colors.white,
  //     animationDuration: Duration(seconds: 3),
  //   );
  // }



  static void showApiErrorSnackbar(ResponseModel response) {
    String message = "Something went wrong";

    try {
      final decoded = jsonDecode(response.data);
      message = decoded['message']?.toString() ?? message;
        } catch (e) {
      // If response is not JSON
      message = response.data.toString() ?? message;
    }

    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }


  static void showCustomApiErrorSnackBar({
    required String title,
    required String body,
  }) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      animationDuration: Duration(seconds: 3),
    );
  }

  ///showing error message in check-in button when driver not reached 300 meters and turn off location
  static Future<void> showDriverDialog({
    String? message1,
    String? message2,
    String? message3,
    String? message4,
    Function()? onPress,
    bool barrierDismissible = true,
  }) async {
    await Get.dialog<void>(
      CupertinoAlertDialog(
        title: Row(
          children: [
            Dimens.boxWidth20,
            Icon(Icons.error_outline, color: Colors.red),
            Dimens.boxWidth10,
            Text(
              message1!,
              style: Styles.blackBold18.copyWith(
                color: ColorsValue.primaryColor,
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align text to the start
          children: [
            Divider(color: ColorsValue.greyDividerColor, thickness: 2),
            Dimens.boxHeight5,
            Text(
              "    ${message2!}",
              style: Styles.blackBold14.copyWith(color: Colors.black),
            ),
            Dimens.boxHeight5,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "\u2022",
                  style: Styles.black14.copyWith(color: Colors.black),
                ),
                Expanded(
                  child: Text(
                    maxLines: 3,
                    "${message3!}",
                    style: Styles.black13.copyWith(color: Colors.black),
                  ),
                ),
              ],
            ),
            Dimens.boxHeight5,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "\u2022 ",
                  style: Styles.black14.copyWith(color: Colors.black),
                ),
                Expanded(
                  child: Text(
                    maxLines: 3,
                    "${message4!}",
                    style: Styles.black13.copyWith(color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          CupertinoButton(
            onPressed: onPress ?? Get.back,
            child: Text(
              'Okay',
              style: TextStyle(color: Theme.of(Get.context!).primaryColor),
            ),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<void> showDialog1(
    String message, {
    Function()? onPress,
    bool barrierDismissible = true,
  }) async {
    await Get.dialog<void>(
      CupertinoAlertDialog(
        title: const Text('Info'),
        content: Text(
          message,
          style: Styles.black14.copyWith(color: ColorsValue.primaryColor),
        ),
        actions: [
          CupertinoButton(
            onPressed: onPress ?? Get.back,
            child: Text(
              'Back to login',
              style: TextStyle(
                color: Theme.of(Get.context!).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show raw snackbar
  static void showToast({
    required String text,
    IconData icon = Icons.plus_one,
    required Color toastColor,
    String type = 'success',
  }) {
    if (!Get.isSnackbarOpen) {
      Get.rawSnackbar(
        messageText: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
            Dimens.boxWidth10,
            Flexible(
              child: Text(
                text,
                style: Styles.black16.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
          ],
        ),

        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,


        backgroundColor: toastColor,
       // (type.toLowerCase() == 'success') ? Colors.green : Colors.black,

        margin: Dimens.edgeInsets50_40_0_0,

        borderRadius: 5,
        duration: const Duration(milliseconds: 1000),
        boxShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],

        isDismissible: false,
      );
    }
  }

  static void showRawSnackbar1(String text, String type) async {
    if (!Get.isSnackbarOpen) {
      Get.rawSnackbar(
        messageText: Text(
          text,
          style: Styles.blackBold16.copyWith(color: Colors.white),
        ),
        backgroundColor: (type == 'success' || type == 'Success')
            ? const Color.fromARGB(255, 6, 182, 0)
            : const Color.fromARGB(255, 212, 14, 0),
        margin: const EdgeInsets.all(16),
        borderRadius: 15,
        //duration: const Duration(seconds: 2)
      );
    }
  }

  /* /// Show toast
  static void showToast(String text, String type) async {
    */ /*Get.rawSnackbar(
          messageText: Text(
            text,
            style: Styles.blackBold16.copyWith(color: Colors.white),
          ),
          backgroundColor: type == 'success'
              ? const Color.fromARGB(255, 6, 182, 0)
              : const Color.fromARGB(255, 212, 14, 0),
          margin: const EdgeInsets.all(16),
          borderRadius: 15,
          duration: const Duration(seconds: 5));*/ /*

    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor:
          (type == 'success' || type == 'Success')
              ? const Color.fromARGB(255, 6, 182, 0)
              : const Color.fromARGB(255, 212, 14, 0),
      textColor: Colors.white,
      fontSize: Dimens.fifteen,
    );
  }
*/
  /// Launch web url in browser
  ///
  static void launchURL(String webUrl) async {
    var url = Uri.parse(webUrl);
    await launchUrl(
      url,
      mode: GetPlatform.isAndroid
          ? LaunchMode.externalNonBrowserApplication
          : LaunchMode.platformDefault,
    );
  }
  /*
  /// Show toast
  static void showFlutterToast(String text, String type) async {
    */ /*Get.rawSnackbar(
          messageText: Text(
            text,
            style: Styles.blackBold16.copyWith(color: Colors.white),
          ),
          backgroundColor: type == 'success'
              ? const Color.fromARGB(255, 6, 182, 0)
              : const Color.fromARGB(255, 212, 14, 0),
          margin: const EdgeInsets.all(16),
          borderRadius: 15,
          duration: const Duration(seconds: 5));*/ /*

    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor:
          (type == 'success' || type == 'Success')
              ? const Color.fromARGB(255, 6, 182, 0)
              : const Color.fromARGB(255, 212, 14, 0),
      textColor: Colors.white,
      fontSize: Dimens.fifteen,
    );
  }*/

  static Future<void> showInternetDialog(
    String message, {
    Function()? onPress,
    bool barrierDismissible = false,
  }) async {
    await Get.dialog<void>(
      CupertinoAlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          CupertinoButton(
            onPressed: onPress ?? Get.back,
            child: Text(
              'Okay',
              style: TextStyle(color: Theme.of(Get.context!).primaryColor),
            ),
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Launch mobile number in dial pad
  ///
  static void launchContactURL(String mobile) async {
    var url = Uri.parse("tel:${mobile}");
    await launchUrl(
      url,
      mode: GetPlatform.isAndroid
          ? LaunchMode.externalNonBrowserApplication
          : LaunchMode.platformDefault,
    );
  }

  /// Launch email
  ///
  static void launchEmailURL(String email) async {
    var url = Uri.parse("mailto:${email}");
    await launchUrl(
      url,
      mode: GetPlatform.isAndroid
          ? LaunchMode.externalNonBrowserApplication
          : LaunchMode.platformDefault,
    );
  }

  static getVersion() {
    if (GetPlatform.isAndroid) {
      return '1.0.69'; // android version
    } else if (GetPlatform.isIOS) {
      return '1.0.51'; // iOS version /*1.0.60*/
    } else {
      return '1.0.69'; // Default version
    }
  }
}

class SSdivider extends StatelessWidget {
  SSdivider({super.key, this.giveMargin});
  EdgeInsetsGeometry? giveMargin;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Dimens.onePointFive,
      width: Get.width,

      margin: giveMargin ?? Dimens.edgeInsets0,
      color: ColorsValue.primaryColor.withOpacity(0.2),
    );
  }
}

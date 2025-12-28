import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/constants/colors.dart';
import '/constants/sizes.dart';

import 'internetCheckerController.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final InternetCheckerController controller = Get.find();

    return Obx(() {
      bool isOnline = controller.isConnected.value;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isOnline ? 0 : Dimens.thirtyFive,
        width: double.infinity,
        color: ColorsValue.primaryColor,
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        child: Opacity(
          opacity: isOnline ? 0 : 1,
          child: Text(
            "No Internet Connection",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    });
  }
}

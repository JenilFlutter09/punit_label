// controllers/tare_product_controller.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/apis/connectHelper.dart';
import 'package:punit_label/apis/sharedPreference.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/tare/tareModel.dart';

import '../../constants/utility.dart';

class TareProductController extends GetxController {
  // List of available tare product names (can be from DB or shared prefs)
  final RxList<String> tareProductNames = <String>[].obs;
  ConnectHelper connectHelper = ConnectHelper();
  // Currently selected product name
  final RxString selectedProductName = RxString('');
  var serialNumberTextController = TextEditingController();
  RxInt serialNumber = RxInt(1);
  // Live weight from scale (from DashboardController)
  final RxDouble currentWeight = 0.0.obs;

  // List of added tare items
  final RxList<TareProducts> addedTareItems = <TareProducts>[].obs;
  var initLoading = false.obs;
  // Text controller for adding new product name
  final TextEditingController newNameController = TextEditingController();
  final dashboardController = Get.find<DashboardController>();
  @override
  Future<void> onReady() async {
    // TODO: implement onReady
    super.onReady();
    await getTareProductsName();
  }

  void addNewProductName() async {
    final name = newNameController.text.trim();
    if (name.isNotEmpty && !tareProductNames.contains(name)) {
      tareProductNames.add(name);
      selectedProductName.value = name;
      newNameController.clear();
      Get.back(); // close dialog
      await TokenStorage.saveTare(tareProductNames);
      Get.snackbar(
        "Success",
        "New tare product added",
        backgroundColor: Colors.green.withOpacity(0.2),
      );
    }
  }

  Future<void> getTareProductsName() async {
    tareProductNames.value = await TokenStorage.getTare() ?? [];
  }

  void addCurrentWeightAsTare() {
    if (selectedProductName.value.isEmpty) {
      Get.snackbar(
        "Error",
        "Please select or add a product name",
        backgroundColor: Colors.red.withOpacity(0.2),
      );
      return;
    }
    if (currentWeight.value <= 0) {
      Get.snackbar(
        "Error",
        "No weight detected",
        backgroundColor: Colors.orange.withOpacity(0.2),
      );
      return;
    }
    String barcodeString = Utility.generateBarcode(id: serialNumber.value);
    print('Tare barcode String = $barcodeString');
    addedTareItems.insert(
      0,
      TareProducts(
        productName: selectedProductName.value,
        weight: currentWeight.value,
        barCodeString: barcodeString,
      ),
    );
    dashboardController.printSmallSticker(
      productName: selectedProductName.value,
      barcodeString: barcodeString,
      labelFields: {
        "Weight": currentWeight.value,
      },
      noAttribute: 1,
    );
  }

  void removeItem(int index) {
    final removed = addedTareItems.removeAt(index);
    Get.snackbar(
      "Removed",
      "${removed.productName}",
      backgroundColor: Colors.red.withOpacity(0.2),
    );
  }

  Future<void> submitAll() async {
    if (addedTareItems.isEmpty) {
      Get.snackbar(
        "Empty",
        "No tare items to submit",
        backgroundColor: Colors.orange.withOpacity(0.2),
      );
      return;
    }
    // TODO: Save to database or pass to next screen
    final data = TareModel(products: addedTareItems);
    var response = await dashboardController.callApi(apiCall: ()=>connectHelper.tareStore(tareModel: data),      isLoading: initLoading,
    );
    if (response.hasError) {
      Utility.showApiErrorSnackbar(response);
    } else {
      Get.snackbar(
        "Success",
        "Tare Products Added Successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        animationDuration: Duration(seconds: 3),
      );
      clearEntries();
    }
  }

  void clearEntries() {
    addedTareItems.clear();
  }
}

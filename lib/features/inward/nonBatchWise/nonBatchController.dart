import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/constants/utility.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/attributesListModel.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/nonBatchDetail.dart';

import '../../../apis/connectHelper.dart';
import '../../../constants/enums.dart';
import '../../../widgets/pdfExcel.dart';
import '../../../widgets/searchableDropdown.dart';
import '../../dashboard/dashboardController.dart';
import '../../tare/tareListModel.dart';
import '../controller/inwardController.dart';
import 'models/nonBatchInwardModel.dart';
import 'models/productListModel.dart';

class NonBatchInwardController extends GetxController {
  var initLoading = false.obs;
  RxBool isTareWeightOff = true.obs;
  ConnectHelper connectHelper = ConnectHelper();
  Rx<InwardState> inwardState = InwardState.idle.obs;
  Rxn<NonBatchDetailModel> nonBatchDetailModel = Rxn<NonBatchDetailModel>();
  var serialNumberTextController = TextEditingController();
  RxInt serialNumber = RxInt(1);
  RxBool isSerialVerified = false.obs;

  Rxn<productListModel> product_list_model = Rxn<productListModel>();

  Rxn<attributesListModel> attributes_list_model = Rxn<attributesListModel>();

  RxList<Attribute> allAttributesList = <Attribute>[].obs;

  Map<String, RxString> selectedAttributes = {};

  RxMap<String, RxBool> attributeEnabled = <String, RxBool>{}.obs;

  //RxList<LabelFormatElement> labelFormats = <LabelFormatElement>[].obs;
  Rxn<LabelFormatElement> selectedLabelFormatObj = Rxn<LabelFormatElement>();

  RxString selectedLabelFormat = "".obs;
  RxInt selectedAttributesCount = 0.obs;

  RxList<module> dropdownProducts = <module>[].obs;
  RxList<NonBatchProducts> productList = <NonBatchProducts>[].obs;
  RxList<NonBatchBarcodes> barcode_list = <NonBatchBarcodes>[].obs;

  TextEditingController transactionName = TextEditingController();
  //TextEditingController serialNumber = TextEditingController();
  //RxInt serialNo = 0.obs;
  final dashboardController = Get.find<DashboardController>();
  final nonInwardController = Get.find<NonInwardController>();
  RxBool isBatchAutoWeightEnabled = true.obs;
  var selectedProduct = Rxn<module>();
  final manualCtrl = Get.find<ManualWeightController>(tag: 'nonbatch');
  Timer? autoWeightTimer;
  int continuousOutOfRangeSeconds = 0;
  Rxn<TareProductListModel> tareProductsListModel = Rxn<TareProductListModel>();
  var selectedBarcode = Rxn<TareBarcode>();
  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchTareProductsList();
    await fetchProductNames();
    await fetchAttributes();

    if (nonInwardController.selectedTransaction.value != null) {
      await fetchNonBatchDetail(
        nonInwardController.selectedTransaction.value?.id.toString() ?? '1',
      );
    }

    serialNumberTextController.text = serialNumber.value.toString();
    validateSerial(serialNumberTextController.text);
  }

  // @override
  // Future<void> onReady() async {
  //   // TODO: implement onReady
  //   super.onReady();
  //   initLoading.value = true;
  //   await _fetchTareProductsList();
  //   if (nonInwardController.selectedTransaction.value != null) {
  //     await fetchNonBatchDetail(
  //       nonInwardController.selectedTransaction.value?.id.toString() ?? '1',
  //     );
  //   }
  //   await fetchProductNames();
  //   await fetchAttributes();
  //   serialNumberTextController.text = serialNumber.value.toString();
  //   validateSerial(serialNumberTextController.text);
  //   initLoading.value = false;
  // }

  void validateSerial(String value) {
    isSerialVerified.value = RegExp(r'^\d+$').hasMatch(value);
    serialNumber.value = int.tryParse(value) ?? 1;
  }

  Future<void> _fetchTareProductsList() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getTareList(),
      isLoading: initLoading,

    );
    tareProductsListModel.value = TareProductListModel.fromJson(
      jsonDecode(response.data),
    );
    print(
      "---------------------------fetched Tare Products--------------------",
    );
  }

  NonBatchProducts convertApiProductToLocal(Products apiModel) {
    return NonBatchProducts(
      productId: apiModel.productId,
      productName: apiModel.productName,
      attributes: apiModel.combinations?.map((combo) {
        return NonBatchAttributes(
          attributeId: combo.attributeId,
          attributeName: combo.attributeName,
          optionId: combo.optionId,
          optionName: combo.optionValue,
        );
      }).toList(),
      barcodes: apiModel.barcodes?.map((b) {
        return NonBatchBarcodes(
          barCodeString: b.barCodeString,
          tareWeightEnable: (b.isTareWeight.toString() == 'true'),
          tareWeight: b.tareWeight ?? 0.0,
          grossWeight: b.grossWeight ?? 0.0,
          netWeight: b.netWeight ?? 0.0,
          time: b.time,
          serialNo: b.serialNo
        );
      }).toList(),
    );
  }

  Future<void> fetchNonBatchDetail(String batchId) async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getNonBatchDetails(batchId),
      isLoading: initLoading,

    );
    nonBatchDetailModel.value = NonBatchDetailModel.fromJson(
      jsonDecode(response.data),
    );
    print(
      "---------------------------fetched batch Details--------------------",
    );
    print(nonBatchDetailModel.value?.status);
    if (nonBatchDetailModel.value?.data?.isPaused == true) {
      inwardState.value = InwardState.paused;

      transactionName.text =
          nonBatchDetailModel.value?.data?.transactionName ?? 'Transaction';

      /// TODO :- NEED TO ADD LOGIC OF ADDING OLD ENTRIES TO EXISITNG ONES
      final apiProducts = nonBatchDetailModel.value?.data?.products ?? [];

      for (var p in apiProducts) {
        productList.add(convertApiProductToLocal(p));
      }
    }
  }

  Future<void> fetchProductNames() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getProductList(),
      isLoading: initLoading,

    );

    product_list_model.value = productListModel.fromJson(
      jsonDecode(response.data),
    );
    final products = product_list_model.value?.data
        ?.map(
          (p) => module(
            id: p.productId ?? 0,
            name: p.productName.toString() ?? "",
            autoWeight: p.autoWeight ?? false,
            minWeight: p.minAutoWeight ?? 0,
            maxWeight: p.maxAutoWeight ?? 0,
            seconds: p.autoWeightSeconds ?? 0,
            //productTareWeight: double.parse(p.tareWeight ?? '0'),
            productTareWeight: p.tareWeight ?? 0,
            unitConversion: p.unitConversion ?? false,
            unitValue: double.parse(p.unit ?? '0'),
          ),
        )
        .where((p) => p.id != 0 && p.name.isNotEmpty)
        .toList();
    print(
      "---------------------------fetched Products Details--------------------",
    );
    print(products?.length);

    dropdownProducts.value = products!;

    if (dropdownProducts.isNotEmpty) {
      selectedProduct.value = dropdownProducts.first;
      isBatchAutoWeightEnabled.value = dropdownProducts.first.autoWeight;
      manualCtrl.manualTare.value = selectedProduct.value?.productTareWeight
          .toString();
      manualCtrl.tareCtrl.text =
          selectedProduct.value?.productTareWeight.toString() ?? '0';
    } else {
      selectedProduct.value = null;
    }
  }

  Future<void> fetchAttributes() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getAttributeList(),
      isLoading: initLoading,

    );
    attributes_list_model.value = attributesListModel.fromJson(
      jsonDecode(response.data),
    );

    /// Directly use the attributes from model
    final attributes = attributes_list_model.value?.data ?? [];

    print("---------------- Attributes Fetched ----------------");
    print(attributes.length);

    allAttributesList.value = attributes
        .where((a) => (a.attributeName ?? "").trim().isNotEmpty)
        .toList();

    /// Reset selected attributes state
    selectedAttributes.clear();
    attributeEnabled.clear();

    for (var a in allAttributesList) {
      selectedAttributes[a.attributeName!] = "".obs; // selected option
      attributeEnabled[a.attributeName!] = false.obs; // checkbox state
    }
  }

  void changeSelectedProductId(int id) {
    final products = product_list_model.value?.data;

    if (products == null) return;

    final product = products.firstWhere(
      (p) => p.productId == id,
      //orElse: () => ,
    );

    selectedProduct.value = module(
      id: product.productId ?? 0,
      name: product.productName ?? 'name',
      autoWeight: product.autoWeight ?? false,
      minWeight: product.minAutoWeight ?? 0,
      maxWeight: product.maxAutoWeight ?? 0,
      seconds: product.autoWeightSeconds ?? 5,
      productTareWeight: product.tareWeight ?? 0,
      /*double.tryParse(product.tareWeight ?? '0') ?? 0*/
      unitConversion: product.unitConversion ?? false,
      unitValue: double.parse(product.unit ?? '0'),
    );
    manualCtrl.manualTare.value = selectedProduct.value?.productTareWeight
        .toString();
    manualCtrl.tareCtrl.text =
        selectedProduct.value?.productTareWeight.toString() ?? '0';
    continuousOutOfRangeSeconds = 0;
    autoWeightTimer?.cancel();
    print('Value of autoWeight => ${selectedProduct.value?.autoWeight}');
    if (selectedProduct.value?.autoWeight == false) {
      isBatchAutoWeightEnabled.value = false;
    } else {
      isBatchAutoWeightEnabled.value = true;
    }
    if (inwardState.value == InwardState.running) {
      _startAutoWeightMonitor();
    }
  }

  bool validateTransactionName() {
    if (transactionName.text.isEmpty) {
      Utility.showCustomApiErrorSnackBar(
        title: 'Empty',
        body: 'Transaction Name is Empty',
      );
      return false;
    } else {
      return true;
    }
  }

  Future<void> onTapMain() async {
    if (!validateTransactionName()) {
      return;
    }
    if (inwardState.value == InwardState.idle) {
      inwardState.value = InwardState.running;
      print("onTapMain pressed. State = ${inwardState.value}");

      /// Start auto weight monitoring
      _startAutoWeightMonitor();
    } else if (inwardState.value == InwardState.running) {
      //inwardState.value = InwardState.paused;
      if (!validateTransactionName()) {
        return;
      }

      /// Pause auto weight
      autoWeightTimer?.cancel();
      await onPauseOrStop(pauseOrStop: 'pause');
    } else if (inwardState.value == InwardState.paused) {
      inwardState.value = InwardState.running;
      print("onTapMain pressed. State = ${inwardState.value}");

      /// Resume auto weight
      _startAutoWeightMonitor();
    }
  }

  Future<void> addToList() async {
    if (!validateTransactionName()) {
      return;
    }
    if (inwardState.value != InwardState.running) {
      inwardState.value = InwardState.running;
    } 
    isTareWeightOff.value =
        dashboardController.tareState.value == TareState.off;

    final product = selectedProduct.value!;
    final double gross =
        double.tryParse(manualCtrl.manualGross.value ?? "0") ?? 0;
    final double tare = isTareWeightOff.value
        ? 0.0
        : double.tryParse(manualCtrl.manualTare.value ?? "0") ?? 0;
    final double net = double.tryParse(manualCtrl.manualNet.value ?? "0") ?? 0;
    final int baseSerial = serialNumber.value;

    // -----------------------------
    // 1. Build selected attributes
    // -----------------------------
    final List<NonBatchAttributes> selectedAttrList = selectedAttributes.entries
        .where((e) => e.value.value.isNotEmpty)
        .map((entry) {
          final modelAttr = allAttributesList.firstWhere(
            (a) => a.attributeName == entry.key,
          );

          final option = modelAttr.options!.firstWhere(
            (o) => o.optionsName == entry.value.value,
          );

          return NonBatchAttributes(
            attributeId: modelAttr.attributeId,
            attributeName: modelAttr.attributeName,
            optionId: option.optionsId,
            optionName: option.optionsName,
          );
        })
        .toList();
    // -----------------------------
    // 3. Check if SAME product+attributes exists
    // -----------------------------
    NonBatchProducts? existing = productList.firstWhereOrNull((p) {
      if (p.productId != product.id) return false;
      if ((p.attributes?.length ?? 0) != selectedAttrList.length) return false;

      // Compare attributes
      return selectedAttrList.every(
        (attr) => p.attributes!.any(
          (a) =>
              a.attributeId == attr.attributeId && a.optionId == attr.optionId,
        ),
      );
    });

    // -----------------------------
    // 4. Insert barcode accordingly
    // -----------------------------
    if (existing != null) {
      final int nextSerial = baseSerial + (existing.barcodes?.length ?? 0);
      final String barcode = Utility.generateBarcode(id: nextSerial);
      final newBarcode = NonBatchBarcodes(
        barCodeString: barcode,
        tareWeightEnable:
            (dashboardController.tareState.value != TareState.off),
        tareWeight: tare,
        grossWeight: gross,
        netWeight: net,
        time: Utility.nowWithoutSeconds().toIso8601String(),
        serialNo: nextSerial, // ✅ SERIAL CONTINUES
      );
      existing.barcodes?.insert(0, newBarcode);
      await configureAndPrintLabel(
        barcodeData: newBarcode,
        productData: existing,
        serialNumber: nextSerial,
      );
      print("🔄 Barcode added to existing group: ${product.name} | $barcode");
    } else {
      final String barcode = Utility.generateBarcode(id: baseSerial);
      final newBarcode = NonBatchBarcodes(
        barCodeString: barcode,
        tareWeightEnable:
            (dashboardController.tareState.value != TareState.off),
        tareWeight: tare,
        grossWeight: gross,
        netWeight: net,
        time: Utility.nowWithoutSeconds().toIso8601String(),
        serialNo: baseSerial, // 🔁 RESET HERE
      );
      var configureProduct = NonBatchProducts(
        productId: product.id,
        productName: product.name,
        attributes: selectedAttrList,
        barcodes: [newBarcode],
      );
      productList.insert(0, configureProduct);
      await configureAndPrintLabel(
        barcodeData: newBarcode,
        productData: configureProduct,
        serialNumber: baseSerial,
      );
      print("🆕 New product group created: ${product.name} | $barcode");
    }

    productList.refresh();
  }

  Future<void> configureAndPrintLabel({
    required NonBatchBarcodes barcodeData,
    required NonBatchProducts productData,
    required int serialNumber,
  }) async
  {
    final LabelFormat selected =
        selectedLabelFormatObj.value?.labelFormat ?? LabelFormat.Large;

    // -------------------------------------------------------------
    // 1️⃣ Convert selected attributes to Map<String, String>
    // -------------------------------------------------------------
    // final Map<String, dynamic> combinationFields = {
    //   for (var attr in (productData.attributes ?? []))
    //     attr.attributeName ?? "Attribute": attr.optionName ?? "",
    // };

    final Map<String, String> combinationFields = {};

    selectedAttributes.forEach((key, value) {
      final isEnabled =
          attributeEnabled[key]?.value ?? false;

      if (isEnabled && value.value.isNotEmpty) {
        combinationFields[key] = value.value;
      }
    });


    // -------------------------------------------------------------
    // 2️⃣ Add weight fields
    // -------------------------------------------------------------
    Map<String, String> manualGTNFields = {
      "Gross Weight": manualCtrl.manualGross.value ?? '0',
      "Tare Weight": manualCtrl.manualTare.value ?? '0',
      "Net Weight": manualCtrl.manualNet.value ?? '0',
    };

    Map<String, String> manualNFields = {
      "Net Weight": manualCtrl.manualNet.value ?? '0',
    };
    // -------------------------------------------------------------
    // 3️⃣ Merge all fields into one labelFields map
    // -------------------------------------------------------------
    Map<String, String> labelFields = isTareWeightOff.value
        ? {...combinationFields, ...manualNFields}
        : {...combinationFields, ...manualGTNFields};
    if (dashboardController.printSerialNumberInLabel.value) {
      labelFields = {"Sr No ": serialNumber.toString(), ...labelFields};
    }

    final String barcodeString = barcodeData.barCodeString ?? "";
    final String productName = productData.productName ?? "Product";
    int noAttr = labelFields.length;
    print("🧾 Printing label for: $productName");
    print("Barcode: $barcodeString");
    print("Fields: $labelFields");

    // -------------------------------------------------------------
    // 4️⃣ Send to the appropriate sticker printer
    // -------------------------------------------------------------
    switch (selected) {
      case LabelFormat.Small:
        // if (dashboardController.printSerialNumberInLabel.value) {
        //   labelFields = {
        //     "Sr No ": serialNumber.toString(),
        //     "Weight": manualCtrl.manualNet.value ?? '0',
        //   };
        // } else {
        //   labelFields = {"Weight": manualCtrl.manualNet.value ?? '0'};
        // }
        await dashboardController.printSmallSticker(
          barcodeString: barcodeString,
          productName: productName,
          noAttribute: noAttr,
          labelFields: labelFields,
        );
        break;

      case LabelFormat.Medium:
        await dashboardController.printMediumSticker(
          barcodeString: barcodeString,
          productName: productName,
          labelFields: labelFields,
          noAttribute: noAttr,
        );
        break;

      case LabelFormat.Large:
        await dashboardController.printLargeSticker(
          barcodeString: barcodeString,
          productName: productName,
          labelFields: labelFields,
          noAttribute: noAttr,
        );
        break;

      case LabelFormat.ExtraLarge:
        await dashboardController.printExtraLargeSticker(
          barcodeString: barcodeString,
          productName: productName,
          labelFields: labelFields,
          noAttribute: noAttr,
        );
        break;

      // case LabelFormat.WholesalePack:
      // // Net Weight comes from attribute dropdown (already in combinationFields)
      // // Gross Weight is the actual measured weight — append it
      // final wholesaleFields = {
      //   ...combinationFields,
      //   "Gross Weight": manualCtrl.manualGross.value ?? '0',
      // };
      // await dashboardController.printWholesalePackSticker(
      //   barcodeString: barcodeString,
      //   productName: productName,
      //   labelFields: wholesaleFields,
      //   noAttribute: wholesaleFields.length,
      // );
      // break;
      case LabelFormat.WholesalePack:
        final wholesaleFields = <String, dynamic>{};
        // Include Sr No if enabled
        if (labelFields.containsKey("Sr No ")) {
          wholesaleFields["Sr No "] = labelFields["Sr No "];
        }
        wholesaleFields.addAll(combinationFields);
        wholesaleFields["Gross Weight"] = manualCtrl.manualGross.value ?? '0';

        await dashboardController.printWholesalePackSticker(
          barcodeString: barcodeString,
          productName: productName,
          labelFields: wholesaleFields,
          noAttribute: wholesaleFields.length,
        );
        break;
    }
  }

  NonBatchProducts buildSelectedProductJson() {
    final product = selectedProduct.value;

    if (product == null) {
      throw Exception("No product selected!");
    }

    // Build attributes list
    List<NonBatchAttributes> attributesJson = [];

    for (var attr in allAttributesList) {
      String attrName = attr.attributeName ?? "";
      int attrId = attr.attributeId ?? 0;

      String selectedOptionName = selectedAttributes[attrName]?.value ?? "";
      int selectedOptionId =
          attr.options
              ?.firstWhere(
                (o) => o.optionsName == selectedOptionName,
                orElse: () => Options(optionsId: 0, optionsName: ""),
              )
              .optionsId ??
          0;

      attributesJson.add(
        NonBatchAttributes(
          attributeId: attrId,
          attributeName: attrName,
          optionId: selectedOptionId,
          optionName: selectedOptionName,
        ),
      );
    }

    // Build barcode list
    List<NonBatchBarcodes> barcodeList = barcode_list;

    return NonBatchProducts(
      productId: product.id ?? 0,
      productName: product.name ?? "",
      attributes: attributesJson,
      barcodes: barcodeList,
    );
  }

  Future<void> onPauseOrStop({required String pauseOrStop}) async {
    if (inwardState.value == InwardState.running) {
      inwardState.value = InwardState.paused;
    }
    var data = NonBatchInwardModel(
      transactionId: nonInwardController.selectedTransaction.value != null
          ? nonBatchDetailModel.value?.data?.transactionId
          : null,
      transactionName: transactionName.text,
      status: pauseOrStop,
      products: productList,
    );
    final body = data.toJson();

    print("📦 REQUEST BODY:");
    print(body);

    // API CALL
    var response = await dashboardController.callApi(
      apiCall: () =>
          connectHelper.nonBatchProductStore(non_batch_inward_model: data),
      isLoading: initLoading,

    );
    if (!response.hasError) {
      if(pauseOrStop == 'stop') {
        Get.snackbar(
          "Successful",
          "Transaction Saved Successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          animationDuration: Duration(seconds: 3),
        );
      }else{
        Get.snackbar(
          "Paused",
          "Transaction Paused Successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          animationDuration: Duration(seconds: 3),
        );
      }
      await generatePdf();
    }
  }

  String formatBarcodeTime(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
  }

  Future<void> generatePdf() async{
    final now = DateTime.now();

    final uniqueSuffix =
        "${DateFormat('ddMMyyyy_HHmmss').format(now)}_${now.microsecondsSinceEpoch}";

    final title = "Transaction_$uniqueSuffix";

    await ExportHelper.generatePDF(
      title: title,
      metaData: {
        "Transaction Name": transactionName.text ?? "Product Name",
        "Generated By": "punitinstrument.com",
        "Date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
      },
      headers: ["Sr No", "Name", "Gross", "Tare", "Net", "Created_at"],
      data: _flattenBarcodesForExport(),
      email: dashboardController.companyDetails.value?.data?.email ?? 'shahjenil9977@gmail.com'
    );
  }

  void onTapPdf(BuildContext context) {
    if (productList.isNotEmpty) {
      ExportHelper.exportReport(
        context: context,
        titlePdf: 'Non Batch Inward  ${transactionName.text}',
        titleExcel: 'Non Batch Inward  ${transactionName.text}',

        /// 🧾 Meta Data
        metaData: {
          "Transaction Name": transactionName.text ?? "Product Name",
          "Generated By": "punitinstrument.com",
          "Date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
        },

        /// 📌 Table Headers
        headers: ["Sr No", "Item", "Gross", "Tare", "Net", "Created_at"],
        data: _flattenBarcodesForExport(),

      );
    }
  }

  List<List<String>> _flattenBarcodesForExport() {
    List<List<String>> rows = [];
    int counter = 1;

    for (var product in productList) {
      if (product.barcodes == null) continue;
      final attributeText = formatAttributes(product.attributes);
      for (var b in product.barcodes!) {
        rows.add([
          counter.toString(),
          product.productName ?? '',
          attributeText,
          "${b.grossWeight ?? 0} kg",
          "${b.tareWeight ?? 0} kg",
          "${b.netWeight ?? 0} kg",
          "${b.time}",
        ]);
        counter++;
      }
    }

    return rows;
  }
  String formatAttributes(List<NonBatchAttributes>? attrs) {
    if (attrs == null || attrs.isEmpty) return "";

    return attrs
        .map((a) => "${a.attributeName}: ${a.optionName}")
        .join(", "); ///If you want multi-line instead of comma: .join("\n");

  }
  void _startAutoWeightMonitor() {
    autoWeightTimer?.cancel();

    autoWeightTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) async {
        // 1️⃣ Auto mode enabled
        if (!isBatchAutoWeightEnabled.value) return;

        // 2️⃣ Product selected
        if (selectedProduct.value == null) return;

        final product = selectedProduct.value!;

        // 3️⃣ Parse weight safely
        final double netWeight =
            double.tryParse(manualCtrl.manualNet.value ?? '') ?? 0.0;

        // 4️⃣ Range check
        final bool isInRange =
            netWeight >= product.minWeight &&
                netWeight <= product.maxWeight;

        // 5️⃣ 🔥 TOWER LIGHT INTEGRATION

        dashboardController.tower_controller.updateWeightStatus(
          isInRange
              ? WeightStatus.inRange   // sends "0"
              : WeightStatus.outOfRange, // sends "1"
        );

        // 6️⃣ Existing batch logic (unchanged)
        if (!isInRange) {
          continuousOutOfRangeSeconds = 0;
          return;
        }

        continuousOutOfRangeSeconds++;

        if (continuousOutOfRangeSeconds >= product.seconds) {
          await addToList();
          print(
            "✔ Auto weight added: ${product.name} | Net = $netWeight",
          );
          continuousOutOfRangeSeconds = 0;
        }
      },
    );
  }

  void deleteBarcode(NonBatchProducts product, NonBatchBarcodes barcode) {
    product.barcodes?.remove(barcode);

    // If no barcode left → remove whole product block
    if (product.barcodes == null || product.barcodes!.isEmpty) {
      productList.remove(product);
    }

    productList.refresh(); // 🔥 Refresh UI
  }

  Future<void> onTapStop() async {
    if (!validateTransactionName()) {
      return;
    }
    inwardState.value = InwardState.idle;

    autoWeightTimer?.cancel();
    dashboardController.tower_controller.updateWeightStatus(
      WeightStatus.outOfRange, // sends "1"
    );
    continuousOutOfRangeSeconds = 0;

    /// API CALL
    await onPauseOrStop(pauseOrStop: 'stop');
    await Get.find<NonInwardController>().fetchNonBatchlist();
    productList.clear();
    Get.back();
    print("Stopped");
  }
  @override
  void onClose() {
    autoWeightTimer?.cancel();
    serialNumberTextController.dispose();
    transactionName.dispose();
    super.onClose();
  }

}

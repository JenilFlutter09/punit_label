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
  Rxn<NonBatchDetailModel> batchDetailModel = Rxn<NonBatchDetailModel>();

  Rxn<productListModel> product_list_model = Rxn<productListModel>();

  Rxn<attributesListModel> attributes_list_model = Rxn<attributesListModel>();

  RxList<Attribute> allAttributesList = <Attribute>[].obs;

  Map<String, RxString> selectedAttributes = {};

  RxMap<String, RxBool> attributeEnabled = <String, RxBool>{}.obs;

  RxList<LabelFormatElement> labelFormats = <LabelFormatElement>[].obs;
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
    initLoading.value = true;
    await _fetchTareProductsList();
    if (nonInwardController.selectedTransaction.value != null) {
      await fetchNonBatchDetail(
        nonInwardController.selectedTransaction.value?.id.toString() ?? '1',
      );
    }
    await fetchProductNames();
    await fetchAttributes();
    loadLabelFormats();
    initLoading.value = false;
  }

  void loadLabelFormats() {
    labelFormats.value = [
      LabelFormatElement(1, "Small Label Select Max (1)", 1, LabelFormat.Small),
      LabelFormatElement(
        2,
        "Medium Label Select Max (4)",
        4,
        LabelFormat.Medium,
      ),
      LabelFormatElement(3, "Large Label Select Max (5)", 5, LabelFormat.Large),
      LabelFormatElement(
        3,
        "Extra Large Label Select Max (7)",
        7,
        LabelFormat.ExtraLarge,
      ),
    ];
  }

  Future<void> _fetchTareProductsList() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getTareList(),
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
          attributeId: int.tryParse(combo.attributeId ?? '0'),
          attributeName: combo.attributeName,
          optionId: int.tryParse(combo.optionId ?? '0'),
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
        );
      }).toList(),
    );
  }

  Future<void> fetchNonBatchDetail(String batchId) async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getNonBatchDetails(batchId),
    );
    batchDetailModel.value = NonBatchDetailModel.fromJson(
      jsonDecode(response.data),
    );
    print(
      "---------------------------fetched batch Details--------------------",
    );
    print(batchDetailModel.value?.status);
    if (batchDetailModel.value?.data?.isPaused == true) {
      inwardState.value = InwardState.paused;

      transactionName.text =
          batchDetailModel.value?.data?.transactionName ?? 'Transaction';

      /// TODO :- NEED TO ADD LOGIC OF ADDING OLD ENTRIES TO EXISITNG ONES
      final apiProducts = batchDetailModel.value?.data?.products ?? [];

      for (var p in apiProducts) {
        productList.add(convertApiProductToLocal(p));
      }
    }
  }

  Future<void> fetchProductNames() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getProductList(),
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

  bool validateTransactionNameAndSerialNumber() {
    if (transactionName.text.isEmpty) {
      Utility.showCustomApiErrorSnackBar(
        title: 'Empty',
        body: 'Transaction Name is Empty',
      );
      return false;
    } else {
      //  serialNo.value = int.parse(serialNumber.text);
      return true;
    }
  }

  Future<void> onTapMain() async {
    if (!validateTransactionNameAndSerialNumber()) {
      return;
    }
    if (inwardState.value == InwardState.idle) {
      inwardState.value = InwardState.running;
      print("onTapMain pressed. State = ${inwardState.value}");

      /// Start auto weight monitoring
      _startAutoWeightMonitor();
    } else if (inwardState.value == InwardState.running) {
      //inwardState.value = InwardState.paused;
      if (!validateTransactionNameAndSerialNumber()) {
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

  DateTime nowWithoutSeconds() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  Future<void> addToList() async {
    if (!validateTransactionNameAndSerialNumber()) {
      return;
    }
    if (inwardState.value == InwardState.idle) {
      inwardState.value = InwardState.running;
    } else if (inwardState.value == InwardState.paused) {
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
    // 2. Generate Barcode
    // -----------------------------
    final String barcode = Utility.generateBarcode();

    final newBarcode = NonBatchBarcodes(
      barCodeString: barcode,
      tareWeightEnable: (dashboardController.tareState.value != TareState.off),
      tareWeight: tare,
      grossWeight: gross,
      netWeight: net,
      time: nowWithoutSeconds(), // 🕒
    );

    barcode_list.insert(0, newBarcode);
    Utility.showToast(
      text: 'Entry Added Successfully',
      toastColor: Colors.green,
    );
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
      existing.barcodes?.insert(0, newBarcode);
      await configureAndPrintLabel(
        barcodeData: newBarcode,
        productData: existing,
      );
      print("🔄 Barcode added to existing group: ${product.name} | $barcode");
    } else {
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
      );
      print("🆕 New product group created: ${product.name} | $barcode");
    }

    productList.refresh();
  }

  Future<void> configureAndPrintLabel({
    required NonBatchBarcodes barcodeData,
    required NonBatchProducts productData,
  }) async {
    final LabelFormat selected =
        selectedLabelFormatObj.value?.labelFormat ?? LabelFormat.Large;

    // -------------------------------------------------------------
    // 1️⃣ Convert selected attributes to Map<String, String>
    // -------------------------------------------------------------
    final Map<String, dynamic> combinationFields = {
      for (var attr in (productData.attributes ?? []))
        attr.attributeName ?? "Attribute": attr.optionName ?? "",
    };

    // -------------------------------------------------------------
    // 2️⃣ Add weight fields
    // -------------------------------------------------------------
    final Map<String, dynamic> manualFields = {
      "Gross Weight": barcodeData.grossWeight,
      "Tare Weight": barcodeData.tareWeight,
      "Net Weight": barcodeData.netWeight,
    };

    // -------------------------------------------------------------
    // 3️⃣ Merge all fields into one labelFields map
    // -------------------------------------------------------------
    final Map<String, dynamic> labelFields = {
      ...combinationFields,
      ...manualFields,
    };

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
        await dashboardController.printSmallSticker(
          barcodeString: barcodeString,
          productName: productName,
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
          ? batchDetailModel.value?.data?.transactionId
          : null,
      transactionName: transactionName.text,
      status: pauseOrStop,
      products: productList,
    );
    final body = data.toJson();

    print("📦 REQUEST BODY:");
    print(body);

    // API CALL
    await dashboardController.callApi(
      apiCall: () =>
          connectHelper.nonBatchProductStore(non_batch_inward_model: data),
    );
    // if (pauseOrStop == 'pause') {
    //   Get.snackbar(
    //     "Paused",
    //     "Transaction Paused Successfully",
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: Colors.green,
    //     colorText: Colors.white,
    //     animationDuration: Duration(seconds: 3),
    //   );
    // } else {
    //   Get.snackbar(
    //     "Success",
    //     "Products Added Successfully",
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: Colors.green,
    //     colorText: Colors.white,
    //     animationDuration: Duration(seconds: 3),
    //   );
    // }
  }

  String formatBarcodeTime(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('dd-MM-yyyy hh:mm a').format(dt);
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

        /// 📌 Data rows generated from productList
        /* data: productList.asMap().entries.map((entry) {
          final int index = entry.key;
          final NonBatchBarcodes e = entry.value;
          return [
            (index + 1).toString(),
            e.batchProductName ?? '',
            "${e.grossWeight} kg",
            "${e.tareWeight} kg",
            "${e.netWeight} kg",
          ];
        }).toList(),*/
      );
    }
  }

  List<List<String>> _flattenBarcodesForExport() {
    List<List<String>> rows = [];
    int counter = 1;

    for (var product in productList) {
      if (product.barcodes == null) continue;

      for (var b in product.barcodes!) {
        rows.add([
          counter.toString(),
          product.productName ?? '',
          "${b.grossWeight ?? 0} kg",
          "${b.tareWeight ?? 0} kg",
          "${b.netWeight ?? 0} kg",
          formatBarcodeTime(b.time),
        ]);
        counter++;
      }
    }

    return rows;
  }

  void _startAutoWeightMonitor() {
    autoWeightTimer?.cancel();

    autoWeightTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!isBatchAutoWeightEnabled.value) return;
      if (selectedProduct.value == null) return;

      final product = selectedProduct.value!;
      final double netWeight =
          double.tryParse(manualCtrl.manualNet.value ?? "0") ?? 0;

      final bool isInRange =
          netWeight >= product.minWeight && netWeight <= product.maxWeight;

      if (!isInRange) {
        continuousOutOfRangeSeconds = 0;
        return;
      }

      continuousOutOfRangeSeconds++;

      if (continuousOutOfRangeSeconds >= product.seconds) {
        await addToList();
        print("✔ Auto weight added: ${product.name} | Net = $netWeight");
        continuousOutOfRangeSeconds = 0;
      }
    });
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
    if (!validateTransactionNameAndSerialNumber()) {
      return;
    }
    inwardState.value = InwardState.idle;

    autoWeightTimer?.cancel();
    continuousOutOfRangeSeconds = 0;

    /// API CALL
    await onPauseOrStop(pauseOrStop: 'stop');
    await Get.find<NonInwardController>().fetchNonBatchlist();
    productList.clear();
    Get.back();
    print("Stopped");
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/constants/utility.dart';
import 'package:punit_label/features/inward/batchWise/models/batchDetails.dart';
import 'package:punit_label/features/inward/batchWise/models/batchInwardModel.dart';
import 'package:punit_label/features/label_preview/models/static_label_preview_models.dart';
import 'package:punit_label/features/label_preview/widgets/static_label_preview_dialog.dart';
import 'package:punit_label/features/label_template/models/label_template_models.dart';
import 'package:punit_label/features/tare/tareListModel.dart';
import 'package:punit_label/widgets/searchableDropdown.dart';

import '../../../apis/connectHelper.dart';
import '../../../apis/responseModel.dart';
import '../../../constants/enums.dart';
import '../../../widgets/pdfExcel.dart';
import '../../dashboard/dashboardController.dart';

class BatchInwardController extends GetxController {
  static const String customLabelSelection = 'Custom';

  var initLoading = false.obs;
  Rx<InwardState> inwardState = InwardState.idle.obs;
  ConnectHelper connectHelper = ConnectHelper();
  Rxn<BatchDetails> batchModel = Rxn<BatchDetails>();
  RxList<module> dropdownProducts = <module>[].obs;
  RxList<Barcodes> productList = <Barcodes>[].obs;
  final dashboardController = Get.find<DashboardController>();
  RxBool isBatchAutoWeightEnabled = true.obs;
  RxBool isTareWeightOff = true.obs;
  var serialNumberTextController = TextEditingController();
  RxInt serialNumber = RxInt(1);
  RxBool isSerialVerified = false.obs;
  var selectedModuleProduct = Rxn<module>();
  final String batchId;
  final manualCtrl = Get.find<ManualWeightController>(tag: 'batch');
  BatchInwardController(this.batchId);
  final RxList<LabelTemplateOption> labelTemplateOptions =
      <LabelTemplateOption>[].obs;
  final Rxn<LabelTemplateOption> selectedLabelTemplateOption =
      Rxn<LabelTemplateOption>();
  final RxString selectedCustomTemplateOptionName = ''.obs;
  final RxString selectedLabelSize = '75x75'.obs;
  final RxBool isTemplateOptionsLoading = false.obs;
  Rxn<LabelFormatElement> selectedLabelFormatObj = Rxn<LabelFormatElement>();
  RxString selectedLabelFormat = "".obs;
  Timer? autoWeightTimer;
  int continuousOutOfRangeSeconds = 0;
  Rxn<TareProductListModel> tareProductsListModel = Rxn<TareProductListModel>();
  var selectedBarcode = Rxn<TareBarcode>();
  var selectedModelProduct = Rxn<Products>();
  RuntimeLabelTemplateData? _cachedRuntimeTemplate;
  String? _cachedRuntimeTemplateKey;

  void _syncSelectedProductTare() {
    final tareValue =
        dashboardController.tareState.value == TareState.off
        ? '0'
        : (selectedModelProduct.value?.tareWeight.toString() ?? '0');
    manualCtrl.manualTare.value = tareValue;
    manualCtrl.tareCtrl.text = tareValue;
    manualCtrl.calculateManualNet();
  }

  String _formatConvertedUnits(double value) {
    final formatted = value.toStringAsFixed(2);
    return formatted.replaceFirst(RegExp(r'\.?0+$'), '');
  }

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
    await _fetchBatchDetail(batchId);
    await _fetchTareProductsList();

    serialNumberTextController.text = serialNumber.value.toString();
    validateSerial(serialNumberTextController.text);
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

  Future<void> _fetchBatchDetail(String batchId) async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getBatchDetails(batchId),
      isLoading: initLoading,
    );
    batchModel.value = BatchDetails.fromJson(jsonDecode(response.data));
    print(
      "---------------------------fetched batch Details--------------------",
    );
    print(batchModel.value?.status);
    final products = batchModel.value?.data?.products
        ?.map(
          (p) => module(
            id: p.batchProductId ?? 0,
            name: p.productName ?? "",
            autoWeight: p.autoWeight ?? false,
            minWeight: p.minAutoWeight ?? 0,
            maxWeight: p.maxAutoWeight ?? 0,
            seconds: p.autoWeightSeconds ?? 5,
            //productTareWeight: double.parse(p.tareWeight ?? '0'),
            productTareWeight: p.tareWeight ?? 0,
            unitConversion: p.unitConversion ?? false,
            unitValue: double.parse(p.unit ?? '0'),
          ),
        )
        .where((p) => p.id != 0 && p.name.isNotEmpty)
        .toList();
    if (products?.isNotEmpty == true) {
      dropdownProducts.value = products!;
    }
    if (dropdownProducts.isNotEmpty) {
      selectedModuleProduct.value = dropdownProducts.first;
      selectedModelProduct.value = batchModel.value?.data?.products?.first;
      isBatchAutoWeightEnabled.value = dropdownProducts.first.autoWeight;
      _syncSelectedProductTare();
      await _loadLabelTemplateOptionsForSelectedProduct();
    } else {
      selectedModuleProduct.value = null;
      selectedModelProduct.value = null;
      labelTemplateOptions.clear();
      _clearLabelSelection();
    }
    if (batchModel.value?.data?.isPaused == true) {
      inwardState.value = InwardState.paused;
      productList.addAll(batchModel.value!.data!.barcodes ?? []);
    }
  }

  void validateSerial(String value) {
    isSerialVerified.value = RegExp(r'^\d+$').hasMatch(value);
    serialNumber.value = int.tryParse(value) ?? 1;
  }

  Future<void> changeSelectedProductId(int id) async {
    // find the product by id
    var product = batchModel.value?.data?.products?.firstWhere(
      (p) => p.batchProductId == id,
      orElse: () => Products(),
    );

    if (product == null || product.batchProductId == null) return;
    selectedModelProduct.value = product;
    selectedModuleProduct.value = module(
      id: product.batchProductId ?? 0,
      name: product.productName ?? 'name',
      autoWeight: product.autoWeight ?? false,
      minWeight: product.minAutoWeight ?? 0,
      maxWeight: product.maxAutoWeight ?? 0,
      seconds: product.autoWeightSeconds ?? 0,
      //productTareWeight: double.parse(product.tareWeight ?? '0'),
      productTareWeight: product.tareWeight ?? 0,
      unitConversion: product.unitConversion ?? false,
      unitValue: double.parse(product.unit ?? '0'),
    );
    _syncSelectedProductTare();

    continuousOutOfRangeSeconds = 0;
    autoWeightTimer?.cancel();
    isBatchAutoWeightEnabled.value =
        selectedModuleProduct.value?.autoWeight ?? false;
    await _loadLabelTemplateOptionsForSelectedProduct();
    if (inwardState.value == InwardState.running) {
      _startAutoWeightMonitor();
    }
  }

  Future<void> changeLabelSize(String labelSize) async {
    selectedLabelSize.value = labelSize;
    _clearRuntimeTemplateCache();
  }

  void selectPrimaryLabelFormat(String optionName) {
    selectedLabelFormat.value = optionName;
    final existingFormat =
        dashboardController.labelFormats.firstWhereOrNull(
          (item) => item.nameOfLabel == optionName,
        ) ??
        dashboardController.resolveExistingLabelFormat();
    selectedLabelFormatObj.value = existingFormat;
    selectedLabelTemplateOption.value = null;
    selectedCustomTemplateOptionName.value = '';
    _clearRuntimeTemplateCache();
  }

  Future<void> _loadLabelTemplateOptionsForSelectedProduct() async {
    final batchProductId = selectedModelProduct.value?.batchProductId;
    if (batchProductId == null) {
      labelTemplateOptions.clear();
      _clearLabelSelection();
      return;
    }

    labelTemplateOptions.clear();
    _applyExistingOnlySelection();
    _clearRuntimeTemplateCache();
  }

  void _clearLabelSelection() {
    selectedLabelTemplateOption.value = null;
    selectedLabelFormatObj.value = null;
    selectedLabelFormat.value = '';
    selectedCustomTemplateOptionName.value = '';
  }

  void _clearRuntimeTemplateCache() {
    _cachedRuntimeTemplate = null;
    _cachedRuntimeTemplateKey = null;
  }

  void _applyExistingOnlySelection() {
    final existingFormat = dashboardController.resolveExistingLabelFormat(
      optionId:
          selectedLabelFormatObj.value?.id.toString() ??
          selectedModelProduct.value?.labelId,
    );
    selectedLabelFormat.value = existingFormat.nameOfLabel;
    selectedLabelFormatObj.value = existingFormat;
    selectedLabelTemplateOption.value = null;
    selectedCustomTemplateOptionName.value = '';
  }

  bool get isCustomTemplateSelected =>
      selectedLabelFormat.value == customLabelSelection;

  List<String> get primaryLabelFormatOptions {
    final options = <String>[];
    for (final format in dashboardController.labelFormats) {
      if (!options.contains(format.nameOfLabel)) {
        options.add(format.nameOfLabel);
      }
    }
    return options;
  }

  Map<String, String> _buildRuntimeAttributeValues(
    List<Combinations> combinations,
  ) {
    final values = <String, String>{};
    for (final item in combinations) {
      if (!item.isPrintable.value) continue;
      final name = item.attrName?.trim() ?? '';
      final value = item.attrValue?.trim() ?? '';
      if (name.isEmpty || value.isEmpty) continue;
      values[_runtimeAttributeFieldKey(name)] = '$name: $value';
    }
    return values;
  }

  String _runtimeAttributeFieldKey(String attrName) {
    final normalized = attrName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'attr_$normalized';
  }

  bool _templateHasExplicitAttributeFields(
    RuntimeLabelTemplateData runtimeTemplate,
  ) {
    return runtimeTemplate.template?.fields.any(
          (field) => field.fieldKey.trim().toLowerCase().startsWith('attr_'),
        ) ??
        false;
  }

  Future<RuntimeLabelTemplateData?>
  _getRuntimeTemplateForSelectedProduct() async {
    final selectedProduct = selectedModelProduct.value;
    final selectedOption = selectedLabelTemplateOption.value;

    if (selectedProduct == null || selectedOption?.isCustom != true) {
      return null;
    }

    final cacheKey =
        '${selectedProduct.batchProductId}:${selectedLabelSize.value}:${selectedOption?.id}';
    if (_cachedRuntimeTemplateKey == cacheKey &&
        _cachedRuntimeTemplate != null) {
      return _cachedRuntimeTemplate;
    }

    try {
      final response = await connectHelper.getRuntimeLabelTemplate(
        batchProductId: selectedProduct.batchProductId,
        labelSize: selectedLabelSize.value,
      );
      _cachedRuntimeTemplate = response.data;
      _cachedRuntimeTemplateKey = cacheKey;
      return _cachedRuntimeTemplate;
    } catch (error) {
      if (error is ResponseModel) {
        Utility.showApiErrorSnackbar(error);
      } else {
        Utility.showCustomApiErrorSnackBar(
          title: 'Runtime Template',
          body: 'Failed to load runtime label template.',
        );
      }
      return null;
    }
  }

  Future<void> onTapMain() async {
    if (inwardState.value == InwardState.idle) {
      inwardState.value = InwardState.running;
      print("onTapMain pressed. State = ${inwardState.value}");

      /// Start auto weight monitoring
      _startAutoWeightMonitor();
    } else if (inwardState.value == InwardState.running) {
      // inwardState.value = InwardState.paused;

      /// Pause auto weight
      autoWeightTimer?.cancel();
      final bool isSuccess = await onPauseOrStop(pauseOrStop: 'pause');
      if (!isSuccess) return;

      _clearLogsAndCloseScreen();
    } else if (inwardState.value == InwardState.paused) {
      inwardState.value = InwardState.running;
      print("onTapMain pressed. State = ${inwardState.value}");

      /// Resume auto weight
      _startAutoWeightMonitor();
    }
  }

  Future<bool> onPauseOrStop({required String pauseOrStop}) async {
    if (inwardState.value == InwardState.running) {
      inwardState.value = InwardState.paused;
    }
    // Group barcodes by batchProductId
    final Map<int, List<BarCodes>> grouped = {};

    for (var item in productList) {
      final pid = item.batchProductId ?? 0;

      // Prepare safe values
      final double tare = item.tareWeight ?? 0;
      final double gross = item.grossWeight ?? 0;

      // If netWeight is null or invalid → auto calculate
      final double net = item.netWeight ?? (gross - tare); // <-- FIXED HERE

      if (!grouped.containsKey(pid)) {
        grouped[pid] = [];
      }

      grouped[pid]!.add(
        BarCodes(
          barCodeString: item.barCodeString,
          tareWeightEnable: item.isTareWeight == "true",
          tareWeight: tare,
          grossWeight: gross,
          netWeight: net, // ALWAYS VALID INTEGER NOW
          serialNo: item.serialNo,
        ),
      );
    }

    // Convert grouped map into product list
    final List<InwardProducts> apiProducts = grouped.entries.map((e) {
      return InwardProducts(batchProductId: e.key, barCodes: e.value);
    }).toList();

    // Sort DESC by batchProductId (optional)
    apiProducts.sort((a, b) => b.batchProductId!.compareTo(a.batchProductId!));
    final connectedDevice = dashboardController.connectedDevice.value;
    final rawScaleName = connectedDevice?.platformName ?? '';
    final scaleName = rawScaleName.trim().isEmpty ? null : rawScaleName;
    final scaleMac = connectedDevice?.remoteId.str;
    final data = batchInwardModel(
      status: pauseOrStop,
      scaleName: scaleName,
      scaleMac: scaleMac,
      products: apiProducts,
    );

    print(jsonEncode(data.toJson())); // DEBUG PRINT

    // API CALL
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.batchProductStore(batch_inward_model: data),
      isLoading: initLoading,
    );

    if (response.hasError) {
      Get.snackbar(
        "Failed Api",
        "Failed to Submit",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        animationDuration: Duration(seconds: 3),
      );
      return false;
    } else {
      final pdfItems = List<Barcodes>.from(productList);
      final batchName =
          batchModel.value?.data?.batch?.batchName ?? "Product Name";
      final attributesText = formatAttributes(
        selectedModelProduct.value?.combinations,
      );
      unawaited(
        generatePdfFromSnapshot(
          entries: pdfItems,
          batchName: batchName,
          attributesText: attributesText,
        ).catchError((e) {
          print("Failed to generate batch inward PDF: $e");
        }),
      );
      Get.snackbar(
        "Success",
        "Products Inward Successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        animationDuration: Duration(seconds: 3),
      );
      return true;
    }
  }

  void _clearLogsAndCloseScreen() {
    autoWeightTimer?.cancel();
    continuousOutOfRangeSeconds = 0;
    productList.clear();

    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.isRegistered<BatchInwardController>()) {
        Get.delete<BatchInwardController>(force: true);
      }
    });
  }

  Future<void> generatePdf() async {
    await generatePdfFromSnapshot(
      entries: List<Barcodes>.from(productList),
      batchName: batchModel.value?.data?.batch?.batchName ?? "Product Name",
      attributesText: formatAttributes(
        selectedModelProduct.value?.combinations,
      ),
    );
  }

  Future<void> generatePdfFromSnapshot({
    required List<Barcodes> entries,
    required String batchName,
    required String attributesText,
  }) async {
    final now = DateTime.now();
    final uniqueSuffix =
        "${DateFormat('ddMMyyyy_HHmmss').format(now)}_${now.microsecondsSinceEpoch}";

    final title = "Batch_Inward_$uniqueSuffix";
    await ExportHelper.generatePDF(
      title: title,
      metaData: {
        "Batch Name": batchName,
        "Generated By": "punitinstrument.com",
        "Date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
      },

      /// 📌 Table Headers
      headers: ["Sr No", "Name", "Gross", "Tare", "Net"],
      email:
          dashboardController.companyDetails.value?.data?.email ??
          'shahjenil9977@gmail.com',

      /// 📌 Data rows generated from productList
      data: entries.asMap().entries.map((entry) {
        final int index = entry.key;
        final Barcodes e = entry.value;
        return [
          (index + 1).toString(),
          e.batchProductName ?? '',
          attributesText,
          "${e.grossWeight} kg",
          "${e.tareWeight} kg",
          "${e.netWeight} kg",
        ];
      }).toList(),
    );
  }

  String formatAttributes(List<Combinations>? combinations) {
    if (combinations == null || combinations.isEmpty) return '';

    final printable = combinations
        .where((c) => c.isPrintable.value == true)
        .map((c) => "${c.attrName}: ${c.attrValue}")
        .toList();

    return printable.join(", ");
  }

  void onTapPdf(BuildContext context) {
    if (productList.isNotEmpty) {
      var batchData = batchModel.value?.data?.batch;
      ExportHelper.exportReport(
        context: context,
        titlePdf:
            'Inward Order ${batchModel.value?.data?.batch?.batchName}-${batchModel.value?.data?.batch?.id}',
        titleExcel:
            'Inward Order ${batchModel.value?.data?.batch?.batchName}-${batchModel.value?.data?.batch?.id}',

        /// 🧾 Meta Data
        metaData: {
          "Batch Name": batchData?.batchName ?? "Product Name",
          "Generated By": "punitinstrument.com",
          "Date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
        },

        /// 📌 Table Headers
        headers: ["Sr No", "Item", "Gross", "Tare", "Net"],

        /// 📌 Data rows generated from productList
        data: productList.asMap().entries.map((entry) {
          final int index = entry.key;
          final Barcodes e = entry.value;
          return [
            (index + 1).toString(),
            e.batchProductName ?? '',
            "${e.grossWeight} kg",
            "${e.tareWeight} kg",
            "${e.netWeight} kg",
          ];
        }).toList(),
      );
    }
  }

  /*void _startAutoWeightMonitor() {
    autoWeightTimer?.cancel(); // reset
    final double nWeight = double.parse(manualCtrl.manualNet.value ?? '0.0');

    print('_startAutoWeightMonitor == $nWeight');

    autoWeightTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      // Condition 1: Auto weight must be enabled
      if (!isBatchAutoWeightEnabled.value) return;

      // Condition 2: Must have selected product
      if (selectedModuleProduct.value == null) return;

      final module product = selectedModuleProduct.value!;

      // Get current weight
      final double netWeight = double.parse(
        manualCtrl.manualNet.value ?? '0.0',
      );

      // Check if weight is out of range
      final bool isOutOfRange =
          netWeight >= product.minWeight && netWeight <= product.maxWeight;

      if (isOutOfRange) {
        continuousOutOfRangeSeconds++;

        if (continuousOutOfRangeSeconds >= product.seconds) {
          // Add product to list
          await addToList();
          // Reset counter
          continuousOutOfRangeSeconds = 0;
        }
      } else {
        // in range → reset timer count
        continuousOutOfRangeSeconds = 0;
      }
    });
  }*/
  void _startAutoWeightMonitor() {
    autoWeightTimer?.cancel(); // reset existing timer

    autoWeightTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // 1️⃣ Auto mode must be enabled
      if (!isBatchAutoWeightEnabled.value) return;

      // 2️⃣ Product must be selected
      if (selectedModuleProduct.value == null) return;

      final module product = selectedModuleProduct.value!;

      // 3️⃣ Parse weight safely
      final double netWeight =
          double.tryParse(manualCtrl.manualNet.value ?? '') ?? 0.0;

      // 4️⃣ Correct range check
      final bool isInRange =
          netWeight >= product.minWeight && netWeight <= product.maxWeight;

      // 5️⃣ 🔥 TOWER LIGHT INTEGRATION
      dashboardController.tower_controller.updateWeightStatus(
        isInRange
            ? WeightStatus
                  .inRange // sends "0"
            : WeightStatus.outOfRange, // sends "1"
      );
      print('tower controller => ' + isInRange.toString());

      // 6️⃣ Existing batch logic (unchanged)
      if (!isInRange) {
        continuousOutOfRangeSeconds++;

        if (continuousOutOfRangeSeconds >= product.seconds) {
          await addToList();
          continuousOutOfRangeSeconds = 0;
        }
      } else {
        continuousOutOfRangeSeconds = 0;
      }
    });
  }

  Future<void> addToList() async {
    final module product = selectedModuleProduct.value!;

    final selected = selectedModuleProduct.value;

    final fetchedProduct = batchModel.value?.data?.products?.firstWhere(
      (p) => p.batchProductId == selected?.id,
    );

    isTareWeightOff.value =
        dashboardController.tareState.value == TareState.off;
    double convertedUnits = 0;
    double net = double.tryParse(manualCtrl.manualNet.value ?? '0') ?? 0.0;
    if (product.unitConversion) {
      convertedUnits = net * product.unitValue;
    } else {
      convertedUnits = 0;
    }
    final int existingCount = productList
        .where((b) => b.batchProductId == product.id)
        .length;
    final int nextSerial = serialNumber.value + existingCount;
    final grossWeight =
        Utility.toDouble(manualCtrl.manualGross.value ?? '0') ?? 0;
    final tareWeight =
        Utility.toDouble(
          isTareWeightOff.value ? '0' : manualCtrl.manualTare.value ?? '0',
        ) ??
        0;
    final netWeight = Utility.toDouble(manualCtrl.manualNet.value ?? '0') ?? 0;
    final printedAt = Utility.nowWithoutSeconds();
    var barcodeString = Utility.generateBarcode(id: nextSerial);
    print('BARCODE --------------------------> $barcodeString');
    productList.insert(
      0,
      Barcodes(
        batchProductId: product.id,
        batchProductName: product.name,
        grossWeight: grossWeight,
        tareWeight: tareWeight,
        netWeight: netWeight,
        isTareWeight: (!(dashboardController.tareState.value == TareState.off)),
        barCodeString: barcodeString,
        unitConversion: product.unitConversion,
        units: convertedUnits.toString(),
        time: printedAt.toString(),
        serialNo: nextSerial,
      ),
    );
    Utility.showToast(
      text: 'Entry Added Successfully',
      toastColor: Colors.green,
    );
    if (inwardState.value != InwardState.running) {
      inwardState.value = InwardState.running;
    }
    final combinations = fetchedProduct?.combinations ?? [];

    if (isCustomTemplateSelected) {
      await _printCustomTemplateLabel(
        productName: product.name,
        barcodeString: barcodeString,
        serialNumberValue: nextSerial,
        printedAt: printedAt,
        grossWeight: grossWeight,
        tareWeight: tareWeight,
        netWeight: netWeight,
        combinations: combinations,
      );

      final double currentNetWeight = double.parse(
        manualCtrl.manualNet.value ?? '0.0',
      );
      print(
        "✔ Auto weight added: ${product.name} , min weight = ${product.minWeight},min weight = ${product.maxWeight}, $currentNetWeight KG",
      );
      return;
    }

    // Convert all printable combinations to Map<String, String>
    final combinationFields = {
      for (final c in combinations)
        if (c.isPrintable.value) c.attrName ?? "": c.attrValue ?? "",
    };
    // Map<String, String> manualGTNFields = {
    //   "Gross Weight": manualCtrl.manualGross.value ?? '0',
    //   "Tare Weight": manualCtrl.manualTare.value ?? '0',
    //   "Net Weight": manualCtrl.manualNet.value ?? '0',
    // };
    // Map<String, String> manualNFields = {
    //   "Net Weight": manualCtrl.manualNet.value ?? '0',
    // };
    Map<String, String> manualGTNFields = {};
    Map<String, String> manualNFields = {};
    if (selectedLabelFormatObj.value == LabelFormat.DryFruit) {
      manualGTNFields = {
        "Gross Weight":
            "${double.tryParse(manualCtrl.manualGross.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
        "Tare Weight":
            "${double.tryParse(manualCtrl.manualTare.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
        "Net Weight":
            "${double.tryParse(manualCtrl.manualNet.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
      };

      manualNFields = {
        "Net Weight":
            "${double.tryParse(manualCtrl.manualNet.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
      };
    } else {
      manualGTNFields = {
        "Gross Weight": manualCtrl.manualGross.value ?? '0',
        "Tare Weight": manualCtrl.manualTare.value ?? '0',
        "Net Weight": manualCtrl.manualNet.value ?? '0',
      };

      manualNFields = {"Net Weight": manualCtrl.manualNet.value ?? '0'};
    }
    final Map<String, String> unitFields = product.unitConversion
        ? {"Units": _formatConvertedUnits(convertedUnits)}
        : {};
    int number = 3;
    Map<String, String> labelFields = isTareWeightOff.value
        ? {...combinationFields, ...manualNFields}
        : {...combinationFields, ...manualGTNFields};
    LabelFormat selectedLabelFormat = LabelFormat.Large;
    number =
        selectedLabelFormatObj.value?.id ??
        dashboardController
            .resolveExistingLabelFormat(
              optionId:
                  selectedLabelTemplateOption.value?.id ??
                  selectedLabelFormatObj.value?.id.toString(),
              fallbackId:
                  int.tryParse(selectedModelProduct.value?.labelId ?? '3') ?? 3,
            )
            .id;
    print('Label Format Number ----------> $number');
    switch (number) {
      case 0:
        selectedLabelFormat = LabelFormat.MajedarTea;
        labelFields = {...combinationFields};
        break;
      case 1:
        selectedLabelFormat = LabelFormat.Small;
        labelFields = {"Weight": manualCtrl.manualNet.value ?? '0'};
        break;
      case 2:
        selectedLabelFormat = LabelFormat.Medium;
        break;
      case 3:
        selectedLabelFormat = LabelFormat.Large;
        break;
      case 4:
        selectedLabelFormat = LabelFormat.ExtraLarge;
        break;
      case 5:
        selectedLabelFormat = LabelFormat.WholesalePack;
        labelFields = {
          ...combinationFields,
          "Gross Weight": manualCtrl.manualGross.value ?? '0',
        };
        break;
      case 6:
        selectedLabelFormat = LabelFormat.SmallSeven;
        labelFields = isTareWeightOff.value
            ? {...combinationFields, ...unitFields, ...manualNFields}
            : {...combinationFields, ...unitFields, ...manualGTNFields};
        break;
    }

    if (dashboardController.printSerialNumberInLabel.value) {
      labelFields = {"Sr No ": nextSerial.toString(), ...labelFields};
    }
    await configureAndPrintLabel(
      barcodeString: barcodeString,
      productName: product.name,
      labelFields: labelFields,
      selectedLabelFormat: selectedLabelFormat,
    );

    // Get current weight
    final double finalnetWeight = double.parse(
      manualCtrl.manualNet.value ?? '0.0',
    );
    print(
      "✔ Auto weight added: ${product.name} , min weight = ${product.minWeight},min weight = ${product.maxWeight}, $finalnetWeight KG",
    );
  }

  Future<void> configureAndPrintLabel({
    required String barcodeString,
    required String productName,
    required Map<String, String?> labelFields,
    required LabelFormat selectedLabelFormat,
  }) async {
    final int noAttr = labelFields.length;

    switch (selectedLabelFormat) {
      case LabelFormat.Small:
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
          noAttribute: noAttr,
          labelFields: labelFields,
        );
        break;

      case LabelFormat.Large:
        await dashboardController.printLargeSticker(
          barcodeString: barcodeString,
          productName: productName,
          noAttribute: noAttr,
          labelFields: labelFields,
        );
        break;

      case LabelFormat.ExtraLarge:
        await dashboardController.printExtraLargeSticker(
          barcodeString: barcodeString,
          productName: productName,
          noAttribute: noAttr,
          labelFields: labelFields,
        );
        break;

      case LabelFormat.WholesalePack:
        await dashboardController.printWholesalePackSticker(
          barcodeString: barcodeString,
          productName: productName,
          labelFields: labelFields,
          noAttribute: labelFields.length,
        );
        break;
      // case LabelFormat.neoLabel:
      //   await dashboardController.printNeoLabelSticker(
      //     barcodeString: barcodeString,
      //     productName: productName,
      //     labelFields: labelFields,
      //   );
      //   break;

      case LabelFormat.MajedarTea:
        // TODO: Handle this case.
        final double netWeight = double.parse(
          manualCtrl.manualNet.value ?? '0.0',
        );
        await dashboardController.printTeaSmallSticker(
          productName: productName,
          noAttribute: labelFields.length,
          netweight: netWeight,
          barcodeString: barcodeString,
        );
        break;
      case LabelFormat.DryFruit:
        // TODO: Handle this case.
        final double netWeight = double.parse(
          manualCtrl.manualNet.value ?? '0.0',
        );
        await dashboardController.printDryFruitSmallSticker(
          productName: productName,
          noAttribute: labelFields.length,
          netweight: netWeight,
          barcodeString: barcodeString,
          labelFields: labelFields,
        );
        break;

      case LabelFormat.SmallSeven:
        await dashboardController.printSmallSevenLabelSticker(
          barcodeString: barcodeString,
          productName: productName,
          labelFields: labelFields,
        );
        break;
    }
  }

  Future<void> _printCustomTemplateLabel({
    required String productName,
    required String barcodeString,
    required int serialNumberValue,
    required DateTime printedAt,
    required double grossWeight,
    required double tareWeight,
    required double netWeight,
    required List<Combinations> combinations,
  }) async {
    final runtimeTemplate = await _getRuntimeTemplateForSelectedProduct();
    if (runtimeTemplate == null) {
      return;
    }

    if (runtimeTemplate.isExisting) {
      final fallbackFormat = dashboardController.resolveExistingLabelFormat(
        optionId: selectedModelProduct.value?.labelId,
      );
      selectedLabelFormatObj.value = fallbackFormat;

      final combinationFields = {
        for (final c in combinations)
          if (c.isPrintable.value) c.attrName ?? "": c.attrValue ?? "",
      };
      Map<String, String> labelFields = isTareWeightOff.value
          ? {
              ...combinationFields,
              "Net Weight": manualCtrl.manualNet.value ?? '0',
            }
          : {
              ...combinationFields,
              "Gross Weight": manualCtrl.manualGross.value ?? '0',
              "Tare Weight": manualCtrl.manualTare.value ?? '0',
              "Net Weight": manualCtrl.manualNet.value ?? '0',
            };

      if (dashboardController.printSerialNumberInLabel.value) {
        labelFields = {"Sr No ": serialNumberValue.toString(), ...labelFields};
      }

      await configureAndPrintLabel(
        barcodeString: barcodeString,
        productName: productName,
        labelFields: labelFields,
        selectedLabelFormat: fallbackFormat.labelFormat,
      );
      return;
    }

    final printableAttributes = combinations
        .where((item) => item.isPrintable.value)
        .map(
          (item) => PrintableAttributeEntry(
            name: item.attrName ?? '',
            value: item.attrValue ?? '',
          ),
        )
        .where(
          (item) => item.name.trim().isNotEmpty && item.value.trim().isNotEmpty,
        )
        .toList();
    final attributeValues = _buildRuntimeAttributeValues(combinations);
    final useExplicitAttributeFields = _templateHasExplicitAttributeFields(
      runtimeTemplate,
    );

    await dashboardController.printRuntimeTemplateLabel(
      labelSize: selectedLabelSize.value,
      runtimeData: runtimeTemplate,
      productName: productName,
      grossWeight: grossWeight,
      tareWeight: tareWeight,
      netWeight: netWeight,
      barcodeString: barcodeString,
      serialNumber: serialNumberValue.toString(),
      printedAt: printedAt,
      attributeValues: attributeValues,
      attributePairs: useExplicitAttributeFields
          ? const []
          : printableAttributes,
    );
  }

  StaticLabelPreviewData? _buildExistingLabelPreviewData() {
    final product = selectedModuleProduct.value;
    final selected = selectedModelProduct.value;
    if (product == null || selected == null) return null;

    final combinationFields = {
      for (final c in selected.combinations ?? const <Combinations>[])
        if (c.isPrintable.value) c.attrName ?? '': c.attrValue ?? '',
    };

    Map<String, String> manualGTNFields = {};
    Map<String, String> manualNFields = {};
    final selectedFormat =
        selectedLabelFormatObj.value?.labelFormat ?? LabelFormat.Large;

    if (selectedFormat == LabelFormat.DryFruit) {
      manualGTNFields = {
        'Gross Weight':
            "${double.tryParse(manualCtrl.manualGross.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
        'Tare Weight':
            "${double.tryParse(manualCtrl.manualTare.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
        'Net Weight':
            "${double.tryParse(manualCtrl.manualNet.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
      };
      manualNFields = {
        'Net Weight':
            "${double.tryParse(manualCtrl.manualNet.value ?? '0')?.toStringAsFixed(3) ?? '0.000'} Kg",
      };
    } else {
      manualGTNFields = {
        'Gross Weight': manualCtrl.manualGross.value ?? '0',
        'Tare Weight': manualCtrl.manualTare.value ?? '0',
        'Net Weight': manualCtrl.manualNet.value ?? '0',
      };
      manualNFields = {'Net Weight': manualCtrl.manualNet.value ?? '0'};
    }

    final unitFields = (product.unitConversion)
        ? {
            'Units': _formatConvertedUnits(
              (Utility.toDouble(manualCtrl.manualNet.value ?? '0') ?? 0) *
                  product.unitValue,
            ),
          }
        : <String, String>{};

    Map<String, dynamic> labelFields = isTareWeightOff.value
        ? {...combinationFields, ...manualNFields}
        : {...combinationFields, ...manualGTNFields};

    final previewSerial =
        serialNumber.value +
        productList.where((item) => item.batchProductId == product.id).length;
    if (dashboardController.printSerialNumberInLabel.value) {
      labelFields = {'Sr No ': previewSerial.toString(), ...labelFields};
    }

    final barcodeString = Utility.generateBarcode(id: previewSerial);
    final noAttr = labelFields.length;

    switch (selectedFormat) {
      case LabelFormat.Small:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selectedFormat,
          width: 600,
          height: 410,
          isGrid: noAttr > 1,
          productName: product.name,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.smallLabelLayout,
        );
      case LabelFormat.Medium:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selectedFormat,
          width: 600,
          height: 600,
          isGrid: noAttr > 5,
          productName: product.name,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.largeLabelLayout,
        );
      case LabelFormat.Large:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selectedFormat,
          width: 700,
          height: 600,
          isGrid: noAttr > 5,
          productName: product.name,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.largeLabelLayout,
        );
      case LabelFormat.ExtraLarge:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selectedFormat,
          width: 700,
          height: 700,
          isGrid: noAttr > 5,
          productName: product.name,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.largeLabelLayout,
        );
      case LabelFormat.WholesalePack:
        final wholesaleFields = <String, dynamic>{};
        if (labelFields.containsKey('Sr No ')) {
          wholesaleFields['Sr No '] = labelFields['Sr No '];
        }
        wholesaleFields.addAll(combinationFields);
        wholesaleFields['Gross Weight'] = manualCtrl.manualGross.value ?? '0';
        return dashboardController.buildGenericStaticLabelPreview(
          format: selectedFormat,
          width: 700,
          height: 1200,
          isGrid: false,
          productName: product.name,
          barcodeString: barcodeString,
          labelFields: wholesaleFields,
          layout: dashboardController.wholesalePackLayout,
          businessHours: 'On working day 11:00AM - 6:00PM',
        );
      case LabelFormat.MajedarTea:
        return dashboardController.buildTeaStaticLabelPreview(
          productName: product.name,
          barcodeString: barcodeString,
          grossWeight: double.parse(
            manualCtrl.manualNet.value ?? '0.0',
          ).toStringAsFixed(3),
          labelFields: labelFields,
        );
      case LabelFormat.DryFruit:
        return dashboardController.buildDryFruitStaticLabelPreview(
          productName: product.name,
          barcodeString: barcodeString,
          grossWeight: double.parse(
            manualCtrl.manualNet.value ?? '0.0',
          ).toStringAsFixed(3),
          labelFields: labelFields,
        );
      case LabelFormat.SmallSeven:
        Map<String, dynamic> smallSevenFields = Map<String, dynamic>.from(
          labelFields,
        );
        if (unitFields.isNotEmpty) {
          final serialValue = smallSevenFields.remove('Sr No ');
          smallSevenFields = {
            if (serialValue != null) 'Sr No ': serialValue,
            ...combinationFields,
            ...unitFields,
            if (isTareWeightOff.value) ...manualNFields else ...manualGTNFields,
          };
        }
        return dashboardController.buildSmallSevenStaticLabelPreview(
          productName: product.name,
          barcodeString: barcodeString,
          labelFields: smallSevenFields,
        );
    }
  }

  Future<void> previewCurrentLabel(BuildContext context) async {
    final previewData = _buildExistingLabelPreviewData();
    if (previewData == null) {
      Utility.showCustomApiErrorSnackBar(
        title: 'Preview',
        body: 'Select a product before opening label preview.',
      );
      return;
    }
    await showStaticLabelPreviewDialog(context: context, data: previewData);
  }

  Future<void> onTapStop() async {
    inwardState.value = InwardState.idle;

    autoWeightTimer?.cancel();
    dashboardController.tower_controller.updateWeightStatus(
      WeightStatus.outOfRange, // sends "1"
    );
    continuousOutOfRangeSeconds = 0;

    /// API CALL
    final bool isSuccess = await onPauseOrStop(pauseOrStop: 'stop');
    if (!isSuccess) return;

    _clearLogsAndCloseScreen();
    print("Stopped");
  }

  @override
  void onClose() {
    autoWeightTimer?.cancel();
    serialNumberTextController.dispose();
    super.onClose();
  }
}

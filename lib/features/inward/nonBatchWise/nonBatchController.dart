import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/constants/utility.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/attributesListModel.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/nonBatchDetail.dart';
import 'package:punit_label/features/label_preview/models/static_label_preview_models.dart';
import 'package:punit_label/features/label_preview/widgets/static_label_preview_dialog.dart';
import 'package:punit_label/features/label_template/models/label_template_models.dart';
import 'package:punit_label/features/label_template/widgets/runtime_label_preview_dialog.dart';

import '../../../apis/connectHelper.dart';
import '../../../apis/responseModel.dart';
import '../../../constants/enums.dart';
import '../../../widgets/pdfExcel.dart';
import '../../../widgets/searchableDropdown.dart';
import '../../dashboard/dashboardController.dart';
import '../../tare/tareListModel.dart';
import '../controller/inwardController.dart';
import 'models/nonBatchInwardModel.dart';
import 'models/productListModel.dart';

class NonBatchInwardController extends GetxController {
  static const String customLabelSelection = 'Custom';

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

  final RxList<LabelTemplateOption> labelTemplateOptions =
      <LabelTemplateOption>[].obs;
  final Rxn<LabelTemplateOption> selectedLabelTemplateOption =
      Rxn<LabelTemplateOption>();
  final RxString selectedCustomTemplateOptionName = ''.obs;
  final RxString selectedLabelSize = '75x75'.obs;
  final RxBool isTemplateOptionsLoading = false.obs;
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
  RuntimeLabelTemplateData? _cachedRuntimeTemplate;
  String? _cachedRuntimeTemplateKey;

  void _syncSelectedProductTare() {
    final tareValue = dashboardController.tareState.value == TareState.off
        ? '0'
        : (selectedProduct.value?.productTareWeight.toString() ?? '0');
    manualCtrl.manualTare.value = tareValue;
    manualCtrl.tareCtrl.text = tareValue;
    manualCtrl.calculateManualNet();
  }

  String _formatConvertedUnits(double value) {
    final formatted = value.toStringAsFixed(2);
    return formatted.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  double _autoWeightSecondsOrDefault(double? seconds) {
    return seconds != null && seconds > 0 ? seconds : 5;
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

  bool get isCustomLabelFeatureEnabled =>
      connectHelper.supportsCustomLabelTemplates;

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
          tareWeightEnable: Utility.toBool(b.isTareWeight) ?? false,
          tareWeight: b.tareWeight ?? 0.0,
          grossWeight: b.grossWeight ?? 0.0,
          netWeight: b.netWeight ?? 0.0,
          time: b.time,
          serialNo: b.serialNo,
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
            name: p.productName ?? "",
            autoWeight: p.autoWeight ?? false,
            minWeight: p.minAutoWeight ?? 0,
            maxWeight: p.maxAutoWeight ?? 0,
            seconds: _autoWeightSecondsOrDefault(p.autoWeightSeconds),
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
      _syncSelectedProductTare();
      await _loadLabelTemplateOptionsForSelectedProduct();
    } else {
      selectedProduct.value = null;
      labelTemplateOptions.clear();
      _clearLabelSelection();
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
    _syncSelectedAttributesCount();
    if (isCustomTemplateSelected) {
      unawaited(_applyCustomTemplateAttributeDefaults());
    }
  }

  Future<void> changeSelectedProductId(int id) async {
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
      seconds: _autoWeightSecondsOrDefault(product.autoWeightSeconds),
      productTareWeight: product.tareWeight ?? 0,
      /*double.tryParse(product.tareWeight ?? '0') ?? 0*/
      unitConversion: product.unitConversion ?? false,
      unitValue: double.parse(product.unit ?? '0'),
    );
    _syncSelectedProductTare();
    continuousOutOfRangeSeconds = 0;
    autoWeightTimer?.cancel();
    print('Value of autoWeight => ${selectedProduct.value?.autoWeight}');
    if (selectedProduct.value?.autoWeight == false) {
      isBatchAutoWeightEnabled.value = false;
    } else {
      isBatchAutoWeightEnabled.value = true;
    }
    _resetAttributeSelections();
    await _loadLabelTemplateOptionsForSelectedProduct();
    if (inwardState.value == InwardState.running) {
      _startAutoWeightMonitor();
    }
  }

  Future<void> changeLabelSize(String labelSize) async {
    if (!isCustomLabelFeatureEnabled) return;
    selectedLabelSize.value = labelSize;
    _clearRuntimeTemplateCache();
    if (isCustomTemplateSelected) {
      _applySelectedCustomTemplateOption(
        _resolvePreferredCustomTemplateOption(),
      );
    }
  }

  void selectPrimaryLabelFormat(String optionName) {
    if (optionName == customLabelSelection && !isCustomLabelFeatureEnabled) {
      _applyExistingOnlySelection();
      _clearRuntimeTemplateCache();
      _syncSelectedAttributesCount();
      return;
    }

    selectedLabelFormat.value = optionName;
    if (optionName == customLabelSelection) {
      selectedLabelFormatObj.value = null;
      _applySelectedCustomTemplateOption(
        _resolvePreferredCustomTemplateOption(),
      );
    } else {
      final existingFormat =
          dashboardController.labelFormats.firstWhereOrNull(
            (item) => item.nameOfLabel == optionName,
          ) ??
          dashboardController.resolveExistingLabelFormat();
      selectedLabelFormatObj.value = existingFormat;
      selectedLabelTemplateOption.value = labelTemplateOptions.firstWhereOrNull(
        (item) => item.isExisting && item.id == existingFormat.id.toString(),
      );
      selectedCustomTemplateOptionName.value = '';
    }
    _clearRuntimeTemplateCache();
    _syncSelectedAttributesCount();
  }

  void selectCustomTemplateOptionByName(String optionName) {
    final option = labelTemplateOptions.firstWhereOrNull(
      (item) =>
          item.isCustom &&
          item.name == optionName &&
          _matchesSelectedCustomLabelSize(item),
    );
    _applySelectedCustomTemplateOption(option);
    _clearRuntimeTemplateCache();
  }

  Future<void> _loadLabelTemplateOptionsForSelectedProduct({
    bool retainCustomSelection = false,
  }) async {
    final productId = selectedProduct.value?.id;
    if (productId == null) {
      labelTemplateOptions.clear();
      _clearLabelSelection();
      return;
    }

    if (!isCustomLabelFeatureEnabled) {
      labelTemplateOptions.clear();
      _applyExistingOnlySelection();
      _clearRuntimeTemplateCache();
      return;
    }

    try {
      final response = await dashboardController.callTypedApi(
        apiCall: () =>
            connectHelper.getLabelTemplateOptions(productId: productId),
        isLoading: isTemplateOptionsLoading,
      );
      labelTemplateOptions.assignAll(response.data?.options ?? const []);

      final availableSizes = customTemplateSizeOptions;
      if (availableSizes.isNotEmpty &&
          !availableSizes.contains(selectedLabelSize.value)) {
        selectedLabelSize.value = availableSizes.first;
      }

      final preferred =
          labelTemplateOptions.firstWhereOrNull((item) => item.isDefault) ??
          (labelTemplateOptions.isNotEmpty ? labelTemplateOptions.first : null);
      _applyTemplateSelection(preferred, preferCustom: retainCustomSelection);
      _clearRuntimeTemplateCache();
    } catch (error) {
      labelTemplateOptions.clear();
      _clearLabelSelection();
      if (error is ResponseModel) {
        Utility.showApiErrorSnackbar(error);
      } else {
        Utility.showCustomApiErrorSnackBar(
          title: 'Template Options',
          body: 'Failed to load label format options.',
        );
      }
    } finally {
      isTemplateOptionsLoading.value = false;
    }
  }

  void _applyTemplateSelection(
    LabelTemplateOption? option, {
    bool preferCustom = false,
  }) {
    if (option == null) {
      _clearLabelSelection();
      return;
    }

    if (preferCustom || option.isCustom) {
      selectedLabelFormat.value = customLabelSelection;
      selectedLabelFormatObj.value = null;
      _applySelectedCustomTemplateOption(
        option.isCustom ? option : _resolvePreferredCustomTemplateOption(),
      );
      _syncSelectedAttributesCount();
      return;
    }

    final existingFormat = dashboardController.resolveExistingLabelFormat(
      optionId: option.id,
    );
    selectedLabelFormat.value = existingFormat.nameOfLabel;
    selectedLabelFormatObj.value = existingFormat;
    selectedLabelTemplateOption.value = option;
    selectedCustomTemplateOptionName.value = '';
    _syncSelectedAttributesCount();
  }

  LabelTemplateOption? _resolvePreferredCustomTemplateOption() {
    final currentCustomId = selectedLabelTemplateOption.value?.isCustom == true
        ? selectedLabelTemplateOption.value?.id
        : null;
    if (currentCustomId != null && currentCustomId.isNotEmpty) {
      final matched = labelTemplateOptions.firstWhereOrNull(
        (item) =>
            item.isCustom &&
            item.id == currentCustomId &&
            _matchesSelectedCustomLabelSize(item),
      );
      if (matched != null) {
        return matched;
      }
    }

    return labelTemplateOptions.firstWhereOrNull(
          (item) =>
              item.isCustom &&
              item.isDefault &&
              _matchesSelectedCustomLabelSize(item),
        ) ??
        labelTemplateOptions.firstWhereOrNull(
          (item) => item.isCustom && _matchesSelectedCustomLabelSize(item),
        );
  }

  void _applySelectedCustomTemplateOption(LabelTemplateOption? option) {
    selectedLabelTemplateOption.value = option;
    selectedCustomTemplateOptionName.value = option?.name ?? '';
    unawaited(_applyCustomTemplateAttributeDefaults());
  }

  void _clearLabelSelection() {
    selectedLabelTemplateOption.value = null;
    selectedLabelFormatObj.value = null;
    selectedLabelFormat.value = '';
    selectedCustomTemplateOptionName.value = '';
    _syncSelectedAttributesCount();
  }

  void _resetAttributeSelections() {
    selectedAttributes.forEach((_, value) => value.value = '');
    attributeEnabled.forEach((_, value) => value.value = false);
    selectedAttributesCount.value = 0;
  }

  void _clearRuntimeTemplateCache() {
    _cachedRuntimeTemplate = null;
    _cachedRuntimeTemplateKey = null;
  }

  void _applyExistingOnlySelection() {
    final existingFormat =
        selectedLabelFormatObj.value ??
        dashboardController.defaultNonBatchLabelFormatObj.value ??
        dashboardController.resolveExistingLabelFormat();
    selectedLabelFormat.value = existingFormat.nameOfLabel;
    selectedLabelFormatObj.value = existingFormat;
    selectedLabelTemplateOption.value = null;
    selectedCustomTemplateOptionName.value = '';
  }

  bool get isCustomTemplateSelected =>
      selectedLabelFormat.value == customLabelSelection;

  List<String> get customTemplateSizeOptions => labelTemplateOptions
      .where((item) => item.isCustom)
      .map((item) => item.labelSize?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  List<String> get primaryLabelFormatOptions {
    final options = <String>[];
    for (final format in dashboardController.labelFormats) {
      if (!options.contains(format.nameOfLabel)) {
        options.add(format.nameOfLabel);
      }
    }
    if (isCustomLabelFeatureEnabled) {
      options.add(customLabelSelection);
    }
    return options;
  }

  List<String> get customTemplateOptionNames => labelTemplateOptions
      .where((item) => item.isCustom && _matchesSelectedCustomLabelSize(item))
      .map((item) => item.name)
      .toList();

  bool _matchesSelectedCustomLabelSize(LabelTemplateOption option) {
    final optionSize = option.labelSize?.trim() ?? '';
    if (optionSize.isEmpty) return true;
    return optionSize == selectedLabelSize.value;
  }

  int get maxSelectableAttributes =>
      selectedLabelFormatObj.value?.elementsAllowedToPrint ??
      allAttributesList.length;

  List<NonBatchAttributes> _buildSelectedNonBatchAttributes() {
    final selectedAttrList = <NonBatchAttributes>[];

    for (final attr in allAttributesList) {
      final attrName = attr.attributeName?.trim() ?? '';
      if (attrName.isEmpty) continue;

      final isEnabled = attributeEnabled[attrName]?.value ?? false;
      final selectedOptionName =
          selectedAttributes[attrName]?.value.trim() ?? '';
      if (!isEnabled || selectedOptionName.isEmpty) continue;

      Options? matchedOption;
      for (final option in attr.options ?? const <Options>[]) {
        if ((option.optionsName ?? '').trim() == selectedOptionName) {
          matchedOption = option;
          break;
        }
      }
      if (matchedOption == null) continue;

      selectedAttrList.add(
        NonBatchAttributes(
          attributeId: attr.attributeId,
          attributeName: attr.attributeName,
          optionId: matchedOption.optionsId,
          optionName: matchedOption.optionsName,
        ),
      );
    }

    return selectedAttrList;
  }

  List<PrintableAttributeEntry> _buildPrintableAttributeEntries(
    List<NonBatchAttributes> attributes,
  ) {
    return attributes
        .map(
          (item) => PrintableAttributeEntry(
            name: item.attributeName?.trim() ?? '',
            value: item.optionName?.trim() ?? '',
          ),
        )
        .where(
          (item) => item.name.trim().isNotEmpty && item.value.trim().isNotEmpty,
        )
        .toList();
  }

  Map<String, String> _buildRuntimeAttributeValues(
    List<NonBatchAttributes> attributes,
  ) {
    final values = <String, String>{};
    for (final item in attributes) {
      final name = item.attributeName?.trim() ?? '';
      final value = item.optionName?.trim() ?? '';
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

  Future<void> _applyCustomTemplateAttributeDefaults() async {
    if (!isCustomTemplateSelected || allAttributesList.isEmpty) {
      return;
    }

    final runtimeTemplate = await _getRuntimeTemplateForSelectedProduct();
    if (runtimeTemplate == null || !runtimeTemplate.isCustom) {
      return;
    }

    final visibleAttributeKeys =
        runtimeTemplate.template?.fields
            .where(
              (field) =>
                  field.isVisible &&
                  field.fieldKey.trim().toLowerCase().startsWith('attr_'),
            )
            .map((field) => field.fieldKey.trim().toLowerCase())
            .toSet() ??
        <String>{};

    if (visibleAttributeKeys.isEmpty) {
      return;
    }

    for (final attr in allAttributesList) {
      final attrName = attr.attributeName?.trim() ?? '';
      if (attrName.isEmpty) continue;

      final runtimeFieldKey = _runtimeAttributeFieldKey(attrName);
      final shouldEnable = visibleAttributeKeys.contains(runtimeFieldKey);
      attributeEnabled[attrName]?.value = shouldEnable;

      if (!shouldEnable) {
        selectedAttributes[attrName]?.value = '';
        continue;
      }

      String? firstOptionName;
      for (final option in attr.options ?? const <Options>[]) {
        final optionName = option.optionsName?.trim() ?? '';
        if (optionName.isNotEmpty) {
          firstOptionName = optionName;
          break;
        }
      }
      selectedAttributes[attrName]?.value = firstOptionName ?? '';
    }

    _syncSelectedAttributesCount();
  }

  bool _templateHasExplicitAttributeFields(
    RuntimeLabelTemplateData runtimeTemplate,
  ) {
    return runtimeTemplate.template?.fields.any(
          (field) => field.fieldKey.trim().toLowerCase().startsWith('attr_'),
        ) ??
        false;
  }

  void _syncSelectedAttributesCount() {
    selectedAttributesCount.value = attributeEnabled.values
        .where((item) => item.value)
        .length;
  }

  Future<RuntimeLabelTemplateData?>
  _getRuntimeTemplateForSelectedProduct() async {
    final productId = selectedProduct.value?.id;
    final selectedOption = selectedLabelTemplateOption.value;
    if (productId == null || selectedOption?.isCustom != true) {
      return null;
    }

    final cacheKey =
        '$productId:${selectedLabelSize.value}:${selectedOption?.id}';
    if (_cachedRuntimeTemplateKey == cacheKey &&
        _cachedRuntimeTemplate != null) {
      return _cachedRuntimeTemplate;
    }

    try {
      final response = await dashboardController.callTypedApi(
        apiCall: () => connectHelper.getRuntimeLabelTemplate(
          productId: productId,
          labelSize: selectedLabelSize.value,
        ),
        isLoading: initLoading,
        blockWhileRunning: false,
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
    final List<NonBatchAttributes> selectedAttrList =
        _buildSelectedNonBatchAttributes();
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
  }) async {
    final runtimeTemplate = await _getRuntimeTemplateForSelectedProduct();
    if (isCustomTemplateSelected && runtimeTemplate == null) {
      return;
    }
    if (runtimeTemplate?.isCustom == true) {
      final printedAt =
          DateTime.tryParse(barcodeData.time ?? '') ??
          Utility.nowWithoutSeconds();
      final runtimeAttributes =
          productData.attributes ?? const <NonBatchAttributes>[];
      final attributeValues = _buildRuntimeAttributeValues(runtimeAttributes);
      final attributePairs = _buildPrintableAttributeEntries(runtimeAttributes);
      final useExplicitAttributeFields = _templateHasExplicitAttributeFields(
        runtimeTemplate!,
      );
      await dashboardController.printRuntimeTemplateLabel(
        labelSize: selectedLabelSize.value,
        runtimeData: runtimeTemplate,
        productName: productData.productName ?? "Product",
        grossWeight: barcodeData.grossWeight ?? 0,
        tareWeight: barcodeData.tareWeight ?? 0,
        netWeight: barcodeData.netWeight ?? 0,
        barcodeString: barcodeData.barCodeString ?? "",
        serialNumber: serialNumber.toString(),
        printedAt: printedAt,
        attributeValues: attributeValues,
        attributePairs: useExplicitAttributeFields
            ? const <PrintableAttributeEntry>[]
            : attributePairs,
      );
      return;
    }

    final LabelFormat selected =
        (runtimeTemplate?.isExisting == true
            ? dashboardController
                  .resolveExistingLabelFormat(
                    optionId:
                        selectedLabelTemplateOption.value?.id ??
                        selectedLabelFormatObj.value?.id.toString(),
                  )
                  .labelFormat
            : selectedLabelFormatObj.value?.labelFormat) ??
        LabelFormat.Large;
    final selectedModule = selectedProduct.value;
    final double netWeightValue = barcodeData.netWeight ?? 0;
    final Map<String, String> unitFields =
        (selectedModule?.unitConversion ?? false)
        ? {
            "Units": _formatConvertedUnits(
              netWeightValue * (selectedModule?.unitValue ?? 1),
            ),
          }
        : {};

    // -------------------------------------------------------------
    // 1️⃣ Convert selected attributes to Map<String, String>
    // -------------------------------------------------------------
    // final Map<String, dynamic> combinationFields = {
    //   for (var attr in (productData.attributes ?? []))
    //     attr.attributeName ?? "Attribute": attr.optionName ?? "",
    // };

    final Map<String, String> combinationFields = {};

    selectedAttributes.forEach((key, value) {
      final isEnabled = attributeEnabled[key]?.value ?? false;

      if (isEnabled && value.value.isNotEmpty) {
        combinationFields[key] = value.value;
      }
    });

    // -------------------------------------------------------------
    // 2️⃣ Add weight fields
    // -------------------------------------------------------------
    Map<String, String> manualGTNFields = {};
    Map<String, String> manualNFields = {};
    if (selected == LabelFormat.DryFruit) {
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
    // -------------------------------------------------------------
    // 3️⃣ Merge all fields into one labelFields map
    // -------------------------------------------------------------
    //Map<String, String> labelFields = selected == LabelFormat.neoLabel
    Map<String, String> labelFields = selected == LabelFormat.MajedarTea
        ? {...combinationFields}
        : isTareWeightOff.value
        ? {...combinationFields, ...manualNFields}
        : {...combinationFields, ...manualGTNFields};
    // Map<String, String> labelFields = isTareWeightOff.value
    //     ? {...combinationFields, ...manualNFields}
    //     : {...combinationFields, ...manualGTNFields};
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
          labelFields: labelFields,
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
        if (unitFields.isNotEmpty) {
          final serialValue = labelFields.remove("Sr No ");
          labelFields = {
            if (serialValue != null) "Sr No ": serialValue,
            ...combinationFields,
            ...unitFields,
            if (isTareWeightOff.value) ...manualNFields else ...manualGTNFields,
          };
        }
        await dashboardController.printSmallSevenLabelSticker(
          barcodeString: barcodeString,
          productName: productName,
          labelFields: labelFields,
        );
        break;
      case LabelFormat.large100by150:
        await dashboardController.print100by150Sticker(
          barcodeString: barcodeString,
          productName: productName,
          noAttribute: noAttr,
          labelFields: labelFields,
        );
    }
  }

  StaticLabelPreviewData? _buildExistingLabelPreviewData({
    RuntimeLabelTemplateData? runtimeTemplate,
  }) {
    final product = selectedProduct.value;
    if (product == null) return null;

    final selected =
        (runtimeTemplate?.isExisting == true
            ? dashboardController
                  .resolveExistingLabelFormat(
                    optionId:
                        selectedLabelTemplateOption.value?.id ??
                        selectedLabelFormatObj.value?.id.toString(),
                  )
                  .labelFormat
            : selectedLabelFormatObj.value?.labelFormat) ??
        LabelFormat.Large;

    final netWeightValue =
        Utility.toDouble(manualCtrl.manualNet.value ?? '0') ?? 0;
    final unitFields = product.unitConversion
        ? {'Units': _formatConvertedUnits(netWeightValue * product.unitValue)}
        : <String, String>{};

    final combinationFields = <String, String>{};
    selectedAttributes.forEach((key, value) {
      final isEnabled = attributeEnabled[key]?.value ?? false;
      if (isEnabled && value.value.isNotEmpty) {
        combinationFields[key] = value.value;
      }
    });

    Map<String, String> manualGTNFields = {};
    Map<String, String> manualNFields = {};
    if (selected == LabelFormat.DryFruit) {
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

    Map<String, dynamic> labelFields = selected == LabelFormat.MajedarTea
        ? {...combinationFields}
        : isTareWeightOff.value
        ? {...combinationFields, ...manualNFields}
        : {...combinationFields, ...manualGTNFields};

    final previewSerial = serialNumber.value.toString();
    if (dashboardController.printSerialNumberInLabel.value) {
      labelFields = {'Sr No ': previewSerial, ...labelFields};
    }

    final barcodeString = Utility.generateBarcode(id: serialNumber.value);
    final productName = product.name;
    final noAttr = labelFields.length;

    switch (selected) {
      case LabelFormat.Small:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selected,
          width: 600,
          height: 410,
          isGrid: noAttr > 1,
          productName: productName,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.smallLabelLayout,
        );
      case LabelFormat.Medium:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selected,
          width: 600,
          height: 600,
          isGrid: noAttr > 5,
          productName: productName,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.largeLabelLayout,
        );
      case LabelFormat.Large:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selected,
          width: 700,
          height: 600,
          isGrid: noAttr > 5,
          productName: productName,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.largeLabelLayout,
        );
      case LabelFormat.ExtraLarge:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selected,
          width: 700,
          height: 700,
          isGrid: noAttr > 5,
          productName: productName,
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
          format: selected,
          width: 700,
          height: 1200,
          isGrid: false,
          productName: productName,
          barcodeString: barcodeString,
          labelFields: wholesaleFields,
          layout: dashboardController.wholesalePackLayout,
          businessHours: 'On working day 11:00AM - 6:00PM',
        );
      case LabelFormat.MajedarTea:
        return dashboardController.buildTeaStaticLabelPreview(
          productName: productName,
          barcodeString: barcodeString,
          grossWeight: double.parse(
            manualCtrl.manualNet.value ?? '0.0',
          ).toStringAsFixed(3),
          labelFields: labelFields,
        );
      case LabelFormat.DryFruit:
        return dashboardController.buildDryFruitStaticLabelPreview(
          productName: productName,
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
          productName: productName,
          barcodeString: barcodeString,
          labelFields: smallSevenFields,
        );
      case LabelFormat.large100by150:
        return dashboardController.buildGenericStaticLabelPreview(
          format: selected,
          width: 700,
          height: 1100,
          isGrid: noAttr > 1,
          productName: productName,
          barcodeString: barcodeString,
          labelFields: labelFields,
          layout: dashboardController.large100by150LabelLayout,
        );
    }
  }

  Future<void> previewCurrentLabel(BuildContext context) async {
    final product = selectedProduct.value;
    if (product == null) {
      Utility.showCustomApiErrorSnackBar(
        title: 'Preview',
        body: 'Select a product before opening label preview.',
      );
      return;
    }

    final runtimeTemplate = isCustomTemplateSelected
        ? await _getRuntimeTemplateForSelectedProduct()
        : null;
    if (isCustomTemplateSelected && runtimeTemplate == null) {
      Utility.showCustomApiErrorSnackBar(
        title: 'Preview',
        body: 'Custom runtime template is not available for preview.',
      );
      return;
    }

    if (runtimeTemplate?.isCustom != true) {
      final staticPreview = _buildExistingLabelPreviewData(
        runtimeTemplate: runtimeTemplate,
      );
      if (staticPreview == null) {
        Utility.showCustomApiErrorSnackBar(
          title: 'Preview',
          body: 'Unable to build label preview for the selected format.',
        );
        return;
      }
      await showStaticLabelPreviewDialog(context: context, data: staticPreview);
      return;
    }

    final customRuntimeTemplate = runtimeTemplate!;

    final previewSerial = serialNumber.value;
    final barcodeString = Utility.generateBarcode(id: previewSerial);
    final grossWeight =
        Utility.toDouble(manualCtrl.manualGross.value ?? '0') ?? 0;
    final tareWeight =
        Utility.toDouble(
          isTareWeightOff.value ? '0' : manualCtrl.manualTare.value ?? '0',
        ) ??
        0;
    final netWeight = Utility.toDouble(manualCtrl.manualNet.value ?? '0') ?? 0;
    final printedAt = Utility.nowWithoutSeconds();
    final selectedAttrList = _buildSelectedNonBatchAttributes();
    final attributeValues = _buildRuntimeAttributeValues(selectedAttrList);
    final attributes = _buildPrintableAttributeEntries(selectedAttrList);
    final useExplicitAttributeFields = _templateHasExplicitAttributeFields(
      customRuntimeTemplate,
    );
    final fields = dashboardController.buildResolvedRuntimePreviewFields(
      runtimeData: customRuntimeTemplate,
      productName: product.name,
      grossWeight: grossWeight,
      tareWeight: tareWeight,
      netWeight: netWeight,
      barcodeString: barcodeString,
      serialNumber: previewSerial.toString(),
      printedAt: printedAt,
      attributeValues: attributeValues,
    );

    await showRuntimeLabelPreviewDialog(
      context: context,
      title: 'Label Preview',
      labelSize: selectedLabelSize.value,
      fields: fields,
      attributes: useExplicitAttributeFields ? const [] : attributes,
    );
  }

  NonBatchProducts buildSelectedProductJson() {
    final product = selectedProduct.value;

    if (product == null) {
      throw Exception("No product selected!");
    }

    final List<NonBatchAttributes> attributesJson =
        _buildSelectedNonBatchAttributes();

    // Build barcode list
    List<NonBatchBarcodes> barcodeList = barcode_list;

    return NonBatchProducts(
      productId: product.id,
      productName: product.name,
      attributes: attributesJson,
      barcodes: barcodeList,
    );
  }

  Future<void> onPauseOrStop({required String pauseOrStop}) async {
    if (inwardState.value == InwardState.running) {
      inwardState.value = InwardState.paused;
    }
    final connectedDevice = dashboardController.connectedDevice.value;
    final rawScaleName = connectedDevice?.platformName ?? '';
    final scaleName = rawScaleName.trim().isEmpty ? null : rawScaleName;
    final scaleMac = connectedDevice?.remoteId.str;
    var data = NonBatchInwardModel(
      transactionId: nonInwardController.selectedTransaction.value != null
          ? nonBatchDetailModel.value?.data?.transactionId
          : null,
      transactionName: transactionName.text,
      status: pauseOrStop,
      scaleName: scaleName,
      scaleMac: scaleMac,
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
      if (pauseOrStop == 'stop') {
        Get.snackbar(
          "Successful",
          "Transaction Saved Successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          animationDuration: Duration(seconds: 3),
        );
      } else {
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

  Future<void> generatePdf() async {
    final now = DateTime.now();

    final uniqueSuffix =
        "${DateFormat('ddMMyyyy_HHmmss').format(now)}_${now.microsecondsSinceEpoch}";

    final title = "Transaction_$uniqueSuffix";

    await ExportHelper.generatePDF(
      title: title,
      metaData: {
        "Transaction Name": transactionName.text,
        "Generated By": "punitinstrument.com",
        "Date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
      },
      headers: ["Sr No", "Name", "Gross", "Tare", "Net", "Created_at"],
      data: _flattenBarcodesForExport(),
      email:
          dashboardController.companyDetails.value?.data?.email ??
          'shahjenil9977@gmail.com',
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
          "Transaction Name": transactionName.text,
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

    return attrs.map((a) => "${a.attributeName}: ${a.optionName}").join(", ");

    ///If you want multi-line instead of comma: .join("\n");
  }

  void _startAutoWeightMonitor() {
    autoWeightTimer?.cancel();

    autoWeightTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
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
          netWeight >= product.minWeight && netWeight <= product.maxWeight;

      // 5️⃣ 🔥 TOWER LIGHT INTEGRATION

      dashboardController.tower_controller.updateWeightStatus(
        isInRange
            ? WeightStatus
                  .inRange // sends "0"
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:punit_label/constants/enums.dart';
import 'package:punit_label/constants/utility.dart';
import 'package:punit_label/features/dashboard/dashboardModel.dart';
import 'package:punit_label/features/label_preview/models/static_label_preview_models.dart';
import 'package:punit_label/features/label_template/models/label_template_models.dart';
import 'package:punit_label/features/login/loginmodel.dart';
import 'package:punit_label/scale_support/scale_support.dart';

import '../../apis/connectHelper.dart';
import '../../apis/bluetooth_device_store.dart';
import '../../apis/responseModel.dart';
import '../../apis/sharedPreference.dart';
import '../../constants/bluetooth_device_display.dart';
import '../../constants/strings.dart';
import '../../navigation/routesManagement.dart';
import '../../widgets/searchableDropdown.dart';
import '../../widgets/usbSerial.dart';
import 'bluetoothController.dart';
import 'companyModel.dart';

typedef ApiCall = Future<ResponseModel> Function();

class DashboardController extends GetxController with WidgetsBindingObserver {
  static const platform = MethodChannel('label_printer');
  var selectedIndex = 0.obs;
  var isLabelPrinterMode = true.obs;
  var isTowerLight = false.obs;
  var isWeightScaleConnected = false.obs;
  var isExperimentalScaleConnected = false.obs;
  ConnectHelper connectHelper = ConnectHelper();
  var isPrinterConnected = false.obs;
  final Map<String, StreamSubscription<List<int>>> _charSubs = {};
  StreamSubscription<BluetoothConnectionState>? _scaleConnectionSub;
  var scanResults = <ScanResult>[].obs;
  Rx<TareState> tareState = TareState.on.obs;
  Rx<LabelState> labelState = LabelState.Label.obs;
  // Rx<DeviceState> towerLight = DeviceState.on.obs;
  var isWhiteLabel = false.obs;
  var printSerialNumberInLabel = false.obs;
  var printTimeInLabel = false.obs;
  var printCopies = 1.obs;
  var defaultNonBatchLabelFormatId = 3.obs;
  Rxn<LabelFormatElement> defaultNonBatchLabelFormatObj =
      Rxn<LabelFormatElement>();
  RxString defaultNonBatchLabelFormatName = "".obs;
  RxBool enableInward = false.obs;
  RxBool enableDispatch = false.obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  var receivedData = ''.obs;
  var isScanning = false.obs;
  var isConnecting = false.obs;
  var connectingDeviceId = Rxn<String>(); // null when idle
  var receivedWeight = Rxn<String>();
  Rxn<CompanyDetailsModel> companyDetails = Rxn<CompanyDetailsModel>();
  Rxn<dashboardModel> dashboardDetails = Rxn<dashboardModel>();
  Rxn<UserProfile> userDetails = Rxn<UserProfile>();
  final manualBatchWeights = Get.put(ManualWeightController(), tag: 'batch');
  final manualTareWeights = Get.put(ManualWeightController(), tag: 'tare');
  final bluetoothController = Get.put(BluetoothController());
  final manualNonBatchWeights = Get.put(
    ManualWeightController(),
    tag: 'nonbatch',
  );
  var activeManualWeightTag = Rx<String>('');
  var statusMessage = ''.obs;
  Timer? printerTimer;
  bool _autoReconnectStarted = false;
  bool _isResumeRecoveryRunning = false;
  bool _isRestoringDrawerSettings = false;
  RxBool isLoading = false.obs;
  final List<Worker> _settingsWorkers = [];
  final List<Worker> _scaleWorkers = [];

  RxInt totalProducts = 0.obs;
  RxInt totalVariants = 0.obs;
  RxString totalInventory = "0".obs;
  var selectedFilter = "top".obs;

  RxList<TopProducts> topProducts = <TopProducts>[].obs;
  RxList<LowStockProducts> lowStockProducts = <LowStockProducts>[].obs;

  RxList<LabelFormatElement> labelFormats = <LabelFormatElement>[].obs;
  final androidScaleController =
      AndroidScaleConnectionController.ensureRegistered();
  bool get isAnyScaleConnected =>
      isWeightScaleConnected.value || isExperimentalScaleConnected.value;

  bool get isActivePrinterConnected => isLabelPrinterMode.value
      ? isPrinterConnected.value
      : bluetoothController.isConnected.value;
  final smallLabelLayout = LabelLayout(
    maxAttributes: 6,
    lineHeight: 40,
    keyFont: 24,
    valueFont: 26,
    bottomPadding: 80,
    columnGap: 140,
    barcodeHeight: 45,
  );

  final largeLabelLayout = LabelLayout(
    maxAttributes: 10,
    lineHeight: 60,
    keyFont: 30,
    valueFont: 34,
    bottomPadding: 150,
    columnGap: 200,
    barcodeHeight: 80,
  );

  final wholesalePackLayout = LabelLayout(
    maxAttributes: 10,
    lineHeight: 60,
    keyFont: 40, // 5mm
    valueFont: 40, // 5mm
    bottomPadding: 180,
    columnGap: 400,
    barcodeHeight: 90,
  );

  final neoLabelLayout = LabelLayout(
    maxAttributes: 3,
    lineHeight: 40,
    keyFont: 36,
    valueFont: 40,
    bottomPadding: 25,
    columnGap: 245,
    barcodeHeight: 85,
  );

  final smallSevenLabelLayout = LabelLayout(
    maxAttributes: 10,
    lineHeight: 40,
    keyFont: 28,
    valueFont: 30,
    bottomPadding: 25,
    columnGap: 190,
    barcodeHeight: 45,
  );

  final tower_controller = Get.put(TowerLightController());

  // Example triggers
  //   controller.updateState(DeviceState.inLimit);
  //   controller.updateState(DeviceState.almostLimit);
  //   controller.updateState(DeviceState.outOfLimit);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // // react to white label toggle
    // ever(isWhiteLabel, (_) {
    //   loadLabelFormats();
    // });
    //
    // // initial load
    // loadLabelFormats();
  }

  int get normalizedPrintCopies => printCopies.value.clamp(1, 10).toInt();

  void setPrintCopies(int value) {
    printCopies.value = value.clamp(1, 10).toInt();
  }

  LabelFormatElement? _findLabelFormatById(int id) {
    for (final format in labelFormats) {
      if (format.id == id) return format;
    }
    return null;
  }

  void _applyDefaultNonBatchLabelFormat(int? preferredId) {
    if (labelFormats.isEmpty) return;

    final matched =
        (preferredId != null ? _findLabelFormatById(preferredId) : null) ??
        _findLabelFormatById(3) ??
        labelFormats.first;

    defaultNonBatchLabelFormatId.value = matched.id;
    defaultNonBatchLabelFormatObj.value = matched;
    defaultNonBatchLabelFormatName.value = matched.nameOfLabel;
  }

  Future<void> loadDefaultNonBatchLabelFormat() async {
    final savedId = await TokenStorage.getDefaultNonBatchLabelFormatId();
    _applyDefaultNonBatchLabelFormat(savedId);
  }

  Future<void> updateDefaultNonBatchLabelFormat(
    LabelFormatElement selected,
  ) async {
    _applyDefaultNonBatchLabelFormat(selected.id);
    await TokenStorage.saveDefaultNonBatchLabelFormatId(selected.id);
  }

  LabelFormatElement resolveExistingLabelFormat({
    String? optionId,
    int fallbackId = 3,
  }) {
    final parsedId = int.tryParse(optionId ?? '');
    return _findLabelFormatById(parsedId ?? fallbackId) ??
        _findLabelFormatById(fallbackId) ??
        labelFormats.first;
  }

  String formatRuntimeDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String formatRuntimeWeight(double value) {
    return value.toStringAsFixed(3);
  }

  TareState? _parseTareState(String? value) {
    if (value == null) return null;
    for (final state in TareState.values) {
      if (state.name == value) return state;
    }
    return null;
  }

  LabelState? _parseLabelState(String? value) {
    if (value == null) return null;
    for (final state in LabelState.values) {
      if (state.name == value) return state;
    }
    return null;
  }

  Future<void> loadDrawerSettings() async {
    _isRestoringDrawerSettings = true;
    try {
      final savedWhiteLabel = await TokenStorage.getWhiteLabelEnabled();
      if (savedWhiteLabel != null) {
        isWhiteLabel.value = savedWhiteLabel;
      }

      final savedPrintSerialNumber =
          await TokenStorage.getPrintSerialNumberEnabled();
      if (savedPrintSerialNumber != null) {
        printSerialNumberInLabel.value = savedPrintSerialNumber;
      }

      final savedPrintTime = await TokenStorage.getPrintTimeEnabled();
      if (savedPrintTime != null) {
        printTimeInLabel.value = savedPrintTime;
      }

      final savedPrintCopies = await TokenStorage.getPrintCopies();
      if (savedPrintCopies != null) {
        setPrintCopies(savedPrintCopies);
      }

      final savedTareState = _parseTareState(await TokenStorage.getTareState());
      if (savedTareState != null) {
        tareState.value = savedTareState;
      }

      final savedLabelState = _parseLabelState(
        await TokenStorage.getLabelState(),
      );
      if (savedLabelState != null) {
        labelState.value = savedLabelState;
        isLabelPrinterMode.value = savedLabelState == LabelState.Label;
      }

      final savedTowerLight = await TokenStorage.getTowerLightEnabled();
      if (savedTowerLight != null) {
        isTowerLight.value = savedTowerLight;
      }
    } finally {
      _isRestoringDrawerSettings = false;
    }
  }

  void _registerDrawerSettingPersistence() {
    if (_settingsWorkers.isNotEmpty) return;

    _settingsWorkers.add(
      ever<bool>(isWhiteLabel, (value) async {
        if (_isRestoringDrawerSettings) return;
        await TokenStorage.saveWhiteLabelEnabled(value);
        loadLabelFormats();
        _applyDefaultNonBatchLabelFormat(defaultNonBatchLabelFormatId.value);
      }),
    );

    _settingsWorkers.add(
      ever<bool>(printSerialNumberInLabel, (value) async {
        if (_isRestoringDrawerSettings) return;
        await TokenStorage.savePrintSerialNumberEnabled(value);
      }),
    );

    _settingsWorkers.add(
      ever<bool>(printTimeInLabel, (value) async {
        if (_isRestoringDrawerSettings) return;
        await TokenStorage.savePrintTimeEnabled(value);
      }),
    );

    _settingsWorkers.add(
      ever<int>(printCopies, (value) async {
        if (_isRestoringDrawerSettings) return;
        await TokenStorage.savePrintCopies(value.clamp(1, 10).toInt());
      }),
    );

    _settingsWorkers.add(
      ever<TareState>(tareState, (value) async {
        if (_isRestoringDrawerSettings) return;
        await TokenStorage.saveTareState(value.name);
      }),
    );

    _settingsWorkers.add(
      ever<LabelState>(labelState, (value) async {
        if (_isRestoringDrawerSettings) return;
        isLabelPrinterMode.value = value == LabelState.Label;
        await TokenStorage.saveLabelState(value.name);
      }),
    );

    _settingsWorkers.add(
      ever<bool>(isTowerLight, (value) async {
        if (_isRestoringDrawerSettings) return;
        await TokenStorage.saveTowerLightEnabled(value);
      }),
    );
  }

  Future<dynamic> _invokeLabelPrintRepeated(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    dynamic result;
    for (int i = 0; i < normalizedPrintCopies; i++) {
      result = await platform.invokeMethod(method, arguments);
    }
    return result;
  }

  @override
  Future<void> onReady() async {
    // TODO: implement onReady
    super.onReady();
    await handlePermissions();
    await loadDrawerSettings();
    _registerDrawerSettingPersistence();
    _registerAndroidScaleBindings();
    if (!_autoReconnectStarted) {
      _autoReconnectStarted = true;
      unawaited(autoReconnectDevicesOnStartup());
    }
    await getUserDetails();
    await getDashboardDetails();
    await getCompanyDetails();
    loadLabelFormats();
    await loadDefaultNonBatchLabelFormat();
    printerTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkPrinterConnection();
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAllCharSubs();
    _cancelScaleConnectionSub();
    for (final worker in _settingsWorkers) {
      worker.dispose();
    }
    for (final worker in _scaleWorkers) {
      worker.dispose();
    }
    printerTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recoverScaleConnectionOnResume());
    }
  }

  Future<void> _recoverScaleConnectionOnResume() async {
    if (_isResumeRecoveryRunning) return;
    if (isAnyScaleConnected) return;
    _isResumeRecoveryRunning = true;

    try {
      await androidScaleController.handleAppResumed();
    } finally {
      _isResumeRecoveryRunning = false;
    }
  }

  void _registerAndroidScaleBindings() {
    if (_scaleWorkers.isNotEmpty) return;

    _scaleWorkers.add(
      ever<ScaleConnectionSnapshot>(androidScaleController.connection, (
        snapshot,
      ) {
        final connected =
            snapshot.status == ScaleConnectionStatus.connected &&
            snapshot.device != null;
        isWeightScaleConnected.value = connected;
        isExperimentalScaleConnected.value = connected;

        if (!connected) {
          receivedData.value = '';
        }
      }),
    );

    _scaleWorkers.add(
      ever<ScalePacket?>(androidScaleController.latestPacket, (packet) {
        if (packet == null) return;
        debugPrint(
          'Scale receivedData(${packet.transportType.name}): "${packet.asString}"',
        );
        receivedData.value = packet.asString;
      }),
    );

    _scaleWorkers.add(
      ever<ScaleReading?>(androidScaleController.latestReading, (reading) {
        if (reading == null) return;
        final formatted = reading.weight.toStringAsFixed(3);
        receivedWeight.value = formatted;
        manualBatchWeights.manualGross.value = formatted;
        manualBatchWeights.calculateManualNet();
        manualNonBatchWeights.manualGross.value = formatted;
        manualNonBatchWeights.calculateManualNet();
        manualTareWeights.manualGross.value = formatted;
      }),
    );
  }

  Future<ResponseModel> callApi({
    required ApiCall apiCall,
    required RxBool isLoading,
    bool retryOn401 = true,
    bool throwOnError = false,
    bool blockWhileRunning = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    /// 🚫 Prevent duplicate parallel calls
    if (blockWhileRunning && isLoading.value) {
      return ResponseModel(
        hasError: true,
        errorCode: 429,
        data: jsonEncode({"message": "Request already running", "code": 429}),
      );
    }

    try {
      isLoading.value = true;

      ResponseModel response = await apiCall().timeout(timeout);

      /// 🔐 Handle 401 (Token Expired)
      if (retryOn401 && response.hasError && response.errorCode == 401) {
        final refresh = await connectHelper.refreshToken().timeout(timeout);

        if (!refresh.hasError) {
          final decoded = refreshModel.fromJson(jsonDecode(refresh.data));
          await TokenStorage.saveToken(decoded.accessToken ?? "");

          /// 🔁 Retry original request ONCE
          response = await apiCall().timeout(timeout);
        } else {
          logout();
          return refresh;
        }
      }

      /// ❌ Handle API error (except blocked calls)
      if (response.hasError && response.errorCode != 429) {
        _handleApiError(response);

        if (throwOnError) {
          throw Exception(response.data);
        }
      }

      return response;
    }
    /// ⏳ Timeout
    on TimeoutException {
      final error = ResponseModel(
        hasError: true,
        errorCode: 408,
        data: jsonEncode({"message": "Request timed out", "code": 408}),
      );

      _handleApiError(error);
      if (throwOnError) throw error;
      return error;
    }
    /// 🌐 Network error
    on SocketException {
      final error = ResponseModel(
        hasError: true,
        errorCode: 408,
        data: jsonEncode({"message": "No Internet Connection", "code": 408}),
      );

      _handleApiError(error);
      if (throwOnError) throw error;
      return error;
    }
    /// 💥 Unknown crash
    catch (e, stack) {
      debugPrint("API CRASH: $e");
      debugPrintStack(stackTrace: stack);

      final error = ResponseModel(
        hasError: true,
        errorCode: 500,
        data: jsonEncode({"message": "Unexpected error occurred", "code": 500}),
      );

      _handleApiError(error);
      if (throwOnError) throw error;
      return error;
    } finally {
      isLoading.value = false;
    }
  }

  /*  Future<ResponseModel> callApi({
    required ApiCall apiCall,
    required RxBool isLoading,
    bool retryOn401 = true,
    bool throwOnError = false,
    bool blockWhileRunning = true,
    Duration timeout = const Duration(seconds: 20),
  }) async
  {
    /// 🚫 Prevent duplicate parallel calls
    if (blockWhileRunning && isLoading.value) {
      return ResponseModel(hasError: true, data: "Request already running");
    }

    try {
      isLoading.value = true;

      ResponseModel response = await apiCall().timeout(timeout);

      /// 🔐 Handle 401 (Token Expired)
      if (retryOn401 && response.hasError && response.errorCode == 401) {
        final refresh = await connectHelper.refreshToken().timeout(timeout);

        if (!refresh.hasError) {
          final decoded = refreshModel.fromJson(jsonDecode(refresh.data));

          await TokenStorage.saveToken(decoded.accessToken ?? "");

          /// Retry original request ONCE
          response = await apiCall().timeout(timeout);
        } else {
          logout();
          return refresh;
        }
      }

      /// ❌ If still error
      if (response.hasError) {
        _handleApiError(response);

        if (throwOnError) {
          throw Exception(response.data);
        }
      }

      return response;
    }
    /// ⏳ Timeout
    on TimeoutException {
      final error = ResponseModel(
        hasError: true,
        data: jsonEncode({"message": "Request timed out", "code": 408}),
        errorCode: 408,
      );

      _handleApiError(error);

      if (throwOnError) throw error;

      return error;
    }
    /// 🌐 Network error
    on SocketException {
      final error = ResponseModel(
        hasError: true,
        data: jsonEncode({"message": "No Internet Connection", "code": 408}),
        errorCode: 408,
      );

      _handleApiError(error);

      if (throwOnError) throw error;

      return error;
    }
    /// 💥 Unknown crash
    catch (e, stack) {
      debugPrint("API CRASH: $e");
      debugPrintStack(stackTrace: stack);

      final error = ResponseModel(
        hasError: true,
        data: jsonEncode({"message": "Request timed out", "code": 408}),
      );

      _handleApiError(error);

      if (throwOnError) throw error;

      return error;
    } finally {
      isLoading.value = false;
    }
  }*/

  void _handleApiError(ResponseModel response) {
    if (response.errorCode == 500) {
      Get.snackbar(
        "Server Error",
        "Something went wrong on server",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (response.data == "No Internet Connection") {
      Get.snackbar(
        "No Internet",
        "Please check your connection",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Utility.showApiErrorSnackbar(response);
    }
  }

  void loadLabelFormats() {
    if (isWhiteLabel.value) {
      labelFormats.value = [
        LabelFormatElement(
          0,
          "Majedar tea Label Format",
          1,
          LabelFormat.MajedarTea,
        ),
        // LabelFormatElement(0, "Neo Label Format", 3, LabelFormat.neoLabel),
        LabelFormatElement(
          1,
          "Small Label Select Max (3)",
          3,
          LabelFormat.Small,
        ),
        LabelFormatElement(
          2,
          "Medium Label Select Max (6)",
          6,
          LabelFormat.Medium,
        ),
        LabelFormatElement(
          3,
          "Large Label Select Max (8)",
          8,
          LabelFormat.Large,
        ),
        LabelFormatElement(
          4,
          "Extra Large Label Select Max (9)",
          9,
          LabelFormat.ExtraLarge,
        ),
        LabelFormatElement(5, "Wholesale Pack", 10, LabelFormat.WholesalePack),
        LabelFormatElement(6, "Small Seven (5)", 5, LabelFormat.SmallSeven),
        LabelFormatElement(7, "DryFruit Label Format", 3, LabelFormat.DryFruit),
      ];
    } else {
      labelFormats.value = [
        LabelFormatElement(
          0,
          "Majedar tea Label Format",
          1,
          LabelFormat.MajedarTea,
        ),
        // LabelFormatElement(0, "Neo Label Format", 3, LabelFormat.neoLabel),
        LabelFormatElement(
          1,
          "Small Label Select Max (3)",
          3,
          LabelFormat.Small,
        ),
        LabelFormatElement(
          2,
          "Medium Label Select Max (4)",
          4,
          LabelFormat.Medium,
        ),
        LabelFormatElement(
          3,
          "Large Label Select Max (5)",
          5,
          LabelFormat.Large,
        ),
        LabelFormatElement(
          4,
          "Extra Large Label Select Max (7)",
          7,
          LabelFormat.ExtraLarge,
        ),
        LabelFormatElement(5, "Wholesale Pack", 10, LabelFormat.WholesalePack),
        LabelFormatElement(6, "Small Seven (5)", 5, LabelFormat.SmallSeven),
        LabelFormatElement(7, "DryFruit Label Format", 3, LabelFormat.DryFruit),
      ];
    }
  }

  void checkPrinterConnection() {
    if (isPrinterConnected.value) {
      checkPrinterStatus();
    }
  }

  Future<void> _cancelScaleConnectionSub() async {
    try {
      await _scaleConnectionSub?.cancel();
    } catch (_) {}
    _scaleConnectionSub = null;
  }

  void _handleBleScaleDisconnected(BluetoothDevice device) {
    final current = connectedDevice.value;
    if (current == null || current.remoteId != device.remoteId) {
      return;
    }

    connectedDevice.value = null;
    isWeightScaleConnected.value = false;
    isExperimentalScaleConnected.value = false;
    receivedData.value = '';
    unawaited(_cancelAllCharSubs());
    unawaited(_cancelScaleConnectionSub());
  }

  Future<void> getUserDetails() async {
    userDetails.value = await TokenStorage.getUser();
    enableInward.value = userDetails.value?.inventoryUser ?? false;

    enableDispatch.value = userDetails.value?.dispatchUser ?? false;
    //enableDispatch.value = true;
  }

  Future<void> getCompanyDetails() async {
    try {
      var response = await callApi(
        apiCall: () => connectHelper.getCompanyDetails(),
        isLoading: isLoading,
      );

      companyDetails.value = CompanyDetailsModel.fromJson(
        jsonDecode(response.data),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ getCompanyDetails error: $e");
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        "Error",
        "Failed to load company details",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      debugPrint(
        "---------------- Company Details API Completed ----------------",
      );
    }
  }

  Future<void> refreshDashboard() async {
    await getDashboardDetails();
    await getCompanyDetails();
  }

  Future<void> getDashboardDetails() async {
    try {
      var response = await callApi(
        apiCall: () => connectHelper.getDashboardDetails(),
        isLoading: isLoading,
      );

      /// 📦 Parse dashboard data
      dashboardDetails.value = dashboardModel.fromJson(
        jsonDecode(response.data),
      );

      /// 📊 Assign lists safely
      topProducts.assignAll(dashboardDetails.value?.data?.topProducts ?? []);

      lowStockProducts.assignAll(
        dashboardDetails.value?.data?.lowStockProducts ?? [],
      );
    } catch (e, stackTrace) {
      /// 💥 Any unexpected runtime / JSON / null crash
      debugPrint("❌ getDashboardDetails error: $e");
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        "Error",
        "Something went wrong while loading dashboard",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      /// ✅ Runs no matter success or failure
      debugPrint(
        "---------------- Dashboard API Call Completed ----------------",
      );
    }
  }

  List<String> buildCompanyInfoLines(CompanyData? data) {
    if (data == null || data.labelFields == null) return [];

    final valueMap = <String, String>{
      "email": data.email ?? "",
      "contact_no": data.contactNo ?? "",
      "gst_no": data.gstNo ?? "",
      "website": data.website ?? "",
    };

    final List<String> topLineParts = [];
    String addressLine = "";

    // Preferred order for top line
    final preferredOrder = ["email", "contact_no", "gst_no", "website"];

    for (final key in preferredOrder) {
      if (data.labelFields?[key] == "on") {
        final value = valueMap[key]?.trim() ?? "";
        if (value.isNotEmpty) {
          topLineParts.add(value);
        }
      }
    }

    // Address handled separately
    if (data.labelFields?["address"] == "on") {
      addressLine = data.address?.trim() ?? "";
    }

    final List<String> lines = [];

    if (topLineParts.isNotEmpty) {
      lines.add(topLineParts.take(2).join(" | "));
    }

    // if (addressLine.isNotEmpty) {
    //   lines.add(addressLine);
    // }
    if (addressLine.isNotEmpty) {
      const int maxChars = 49; // fits within label width at contactFont size
      for (int i = 0; i < addressLine.length; i += maxChars) {
        lines.add(
          addressLine.substring(i, (i + maxChars).clamp(0, addressLine.length)),
        );
      }
    }

    return lines;
  }

  List<Map<String, dynamic>> buildNeoLabelAttributes(
    Map<String, dynamic>? labelFields,
  ) {
    if (labelFields == null || labelFields.isEmpty) return [];

    const excludedKeys = {
      "weight",
      "gross weight",
      "tare weight",
      "net weight",
      "sr no",
      "sr no.",
    };

    final attributes = <Map<String, dynamic>>[];
    labelFields.forEach((key, value) {
      if (attributes.length >= 3) return;

      final normalizedKey = key.trim().toLowerCase();
      final normalizedValue = value?.toString().trim() ?? "";
      if (excludedKeys.contains(normalizedKey) || normalizedValue.isEmpty) {
        return;
      }

      attributes.add({"key": key.trim(), "value": normalizedValue});
    });

    return attributes;
  }

  Future<bool> printRuntimeTemplateLabel({
    required String labelSize,
    required RuntimeLabelTemplateData runtimeData,
    required String productName,
    required double grossWeight,
    required double tareWeight,
    required double netWeight,
    required String barcodeString,
    required String serialNumber,
    required DateTime printedAt,
    Map<String, String> attributeValues = const {},
    List<PrintableAttributeEntry> attributePairs = const [],
  }) async {
    if (!isLabelPrinterMode.value) {
      Utility.showCustomApiErrorSnackBar(
        title: 'Label Printer Required',
        body:
            'Custom label templates only work in label-printer mode on Android.',
      );
      return false;
    }

    final template = runtimeData.template;
    if (template == null) {
      Utility.showCustomApiErrorSnackBar(
        title: 'Template Missing',
        body: 'Runtime template payload is missing template layout data.',
      );
      return false;
    }

    final resolvedFields = _buildResolvedRuntimeFields(
      runtimeData: runtimeData,
      productName: productName,
      grossWeight: grossWeight,
      tareWeight: tareWeight,
      netWeight: netWeight,
      barcodeString: barcodeString,
      serialNumber: serialNumber,
      printedAt: printedAt,
      attributeValues: attributeValues,
    );

    final dimensions = _runtimeTemplateDimensions(labelSize);
    final previewScalePxPerMm =
        template.canvasConfigJson?['preview_scale_px_per_mm'];
    final payload = {
      'labelSize': labelSize,
      'width': dimensions.width,
      'height': dimensions.height,
      'previewScalePxPerMm': previewScalePxPerMm,
      'whiteLabel': template.whiteLabel,
      'lockedFields': runtimeData.lockedFields,
      'footerLocked': runtimeData.footerLocked,
      'footerMessage': runtimeData.footerMessage ?? '',
      'fields': resolvedFields.map((field) => field.toMap()).toList(),
      'attributePairs': attributePairs.map((item) => item.toMap()).toList(),
    };

    await _invokeLabelPrintRepeated('printRuntimeTemplateSticker', payload);
    return true;
  }

  List<ResolvedPrintField> buildResolvedRuntimePreviewFields({
    required RuntimeLabelTemplateData runtimeData,
    required String productName,
    required double grossWeight,
    required double tareWeight,
    required double netWeight,
    required String barcodeString,
    required String serialNumber,
    required DateTime printedAt,
    Map<String, String> attributeValues = const {},
  }) {
    return _buildResolvedRuntimeFields(
      runtimeData: runtimeData,
      productName: productName,
      grossWeight: grossWeight,
      tareWeight: tareWeight,
      netWeight: netWeight,
      barcodeString: barcodeString,
      serialNumber: serialNumber,
      printedAt: printedAt,
      attributeValues: attributeValues,
    );
  }

  List<ResolvedPrintField> _buildResolvedRuntimeFields({
    required RuntimeLabelTemplateData runtimeData,
    required String productName,
    required double grossWeight,
    required double tareWeight,
    required double netWeight,
    required String barcodeString,
    required String serialNumber,
    required DateTime printedAt,
    required Map<String, String> attributeValues,
  }) {
    final companyProfile = runtimeData.companyProfile;
    final footerValue = runtimeData.footerText ?? '';

    return runtimeData.template?.fields.map((field) {
          final value = _resolveRuntimeFieldValue(
            fieldKey: field.fieldKey,
            companyProfile: companyProfile,
            productName: productName,
            grossWeight: grossWeight,
            tareWeight: tareWeight,
            netWeight: netWeight,
            barcodeString: barcodeString,
            serialNumber: serialNumber,
            printedAt: printedAt,
            footerValue: footerValue,
            attributeValues: attributeValues,
          );
          return ResolvedPrintField.fromTemplateField(field, value);
        }).toList() ??
        const [];
  }

  String _resolveRuntimeFieldValue({
    required String fieldKey,
    required RuntimeCompanyProfile? companyProfile,
    required String productName,
    required double grossWeight,
    required double tareWeight,
    required double netWeight,
    required String barcodeString,
    required String serialNumber,
    required DateTime printedAt,
    required String footerValue,
    required Map<String, String> attributeValues,
  }) {
    final normalizedFieldKey = fieldKey.trim().toLowerCase();
    if (normalizedFieldKey.startsWith('attr_')) {
      return attributeValues[normalizedFieldKey] ?? '';
    }

    switch (normalizedFieldKey) {
      case 'company_name':
      case 'company_email':
      case 'company_contact_no':
      case 'company_gst_no':
      case 'company_website':
      case 'company_address':
        return companyProfile?.valueForField(fieldKey) ?? '';
      case 'product_name':
        return productName;
      case 'gross_weight':
        return formatRuntimeWeight(grossWeight);
      case 'tare_weight':
        return formatRuntimeWeight(tareWeight);
      case 'net_weight':
        return formatRuntimeWeight(netWeight);
      case 'barcode':
        return barcodeString;
      case 'barcode_text':
        return '';
      case 'sr_no':
        return serialNumber;
      case 'datetime':
        return formatRuntimeDateTime(printedAt);
      case 'footer':
        return footerValue;
      default:
        return '';
    }
  }

  RuntimeLabelDimensions _runtimeTemplateDimensions(String labelSize) {
    switch (labelSize.trim()) {
      case '50x75':
        return const RuntimeLabelDimensions(width: 410, height: 600);
      case '75x100':
        return const RuntimeLabelDimensions(width: 600, height: 700);
      case '100x100':
        return const RuntimeLabelDimensions(width: 700, height: 700);
      case '75x75':
      default:
        return const RuntimeLabelDimensions(width: 600, height: 600);
    }
  }

  List<Map<String, dynamic>> buildSmallSevenLabelAttributes(
    Map<String, dynamic>? labelFields,
  ) {
    if (labelFields == null || labelFields.isEmpty) return [];

    const excludedKeys = {"weight", "sr no", "sr no."};

    final attributes = <Map<String, dynamic>>[];
    labelFields.forEach((key, value) {
      if (attributes.length >= 10) return;

      final normalizedKey = key.trim().toLowerCase();
      final normalizedValue = value?.toString().trim() ?? "";
      if (excludedKeys.contains(normalizedKey) || normalizedValue.isEmpty) {
        return;
      }

      attributes.add({"key": key.trim(), "value": normalizedValue});
    });

    return attributes;
  }

  List<Map<String, dynamic>> buildDryFruitLabelAttributes(
    Map<String, dynamic>? labelFields,
  ) {
    if (labelFields == null || labelFields.isEmpty) return [];

    const excludedKeys = {
      "weight",
      "gross weight",
      "tare weight",
      "sr no",
      "sr no.",
    };

    final attributes = <Map<String, dynamic>>[];
    labelFields.forEach((key, value) {
      final normalizedKey = key.trim().toLowerCase();
      final normalizedValue = value?.toString().trim() ?? "";
      if (excludedKeys.contains(normalizedKey) || normalizedValue.isEmpty) {
        return;
      }

      attributes.add({"key": key.trim(), "value": normalizedValue});
    });

    return attributes;
  }

  StaticLabelPreviewData buildGenericStaticLabelPreview({
    required LabelFormat format,
    required int width,
    required int height,
    required bool isGrid,
    required String productName,
    required String barcodeString,
    Map<String, dynamic>? labelFields,
    required LabelLayout layout,
    String businessHours = '',
  }) {
    final companyData = companyDetails.value?.data;
    final attributes = <StaticLabelPreviewAttribute>[];
    labelFields?.forEach((key, value) {
      final normalizedValue = value?.toString().trim() ?? '';
      if (normalizedValue.isEmpty) return;
      attributes.add(
        StaticLabelPreviewAttribute(key: key.trim(), value: normalizedValue),
      );
    });

    final serialNumber = printSerialNumberInLabel.value
        ? ((labelFields?['Sr No '] ?? labelFields?['Sr No'])
                  ?.toString()
                  .trim() ??
              '')
        : '';

    return StaticLabelPreviewData(
      format: format,
      width: width,
      height: height,
      isWhiteLabel: isWhiteLabel.value,
      printTime: printTimeInLabel.value,
      printSerialNumber: printSerialNumberInLabel.value,
      isGrid: isGrid,
      companyName: companyData?.name ?? '',
      companyInfoLines: buildCompanyInfoLines(companyData),
      address: companyData?.address?.trim() ?? '',
      phone: companyData?.contactNo?.trim() ?? '',
      email: companyData?.email?.trim() ?? '',
      productName: productName,
      barcodeData: barcodeString,
      serialNumber: serialNumber,
      footerText: 'Label generated from weighing ERP by punitinstrument.com',
      businessHours: businessHours,
      attributeLabel: '',
      description: '',
      grossWeight: '',
      previewedAt: Utility.nowWithoutSeconds(),
      layout: _toStaticPreviewLayout(layout),
      attributes: attributes,
    );
  }

  StaticLabelPreviewData buildSmallSevenStaticLabelPreview({
    required String productName,
    required String barcodeString,
    Map<String, dynamic>? labelFields,
  }) {
    final companyData = companyDetails.value?.data;
    final serialNumber = printSerialNumberInLabel.value
        ? ((labelFields?['Sr No '] ?? labelFields?['Sr No'])
                  ?.toString()
                  .trim() ??
              '')
        : '';

    return StaticLabelPreviewData(
      format: LabelFormat.SmallSeven,
      width: 600,
      height: 410,
      isWhiteLabel: isWhiteLabel.value,
      printTime: printTimeInLabel.value,
      printSerialNumber: printSerialNumberInLabel.value,
      isGrid: false,
      companyName: companyData?.name ?? '',
      companyInfoLines: buildCompanyInfoLines(companyData),
      address: companyData?.address?.trim() ?? '',
      phone: companyData?.contactNo?.trim() ?? '',
      email: companyData?.email?.trim() ?? '',
      productName: productName,
      barcodeData: barcodeString,
      serialNumber: serialNumber,
      footerText: '',
      businessHours: '',
      attributeLabel: '',
      description: '',
      grossWeight: '',
      previewedAt: Utility.nowWithoutSeconds(),
      layout: _toStaticPreviewLayout(smallSevenLabelLayout),
      attributes: buildSmallSevenLabelAttributes(labelFields)
          .map(
            (item) => StaticLabelPreviewAttribute(
              key: item['key']?.toString() ?? '',
              value: item['value']?.toString() ?? '',
            ),
          )
          .toList(),
    );
  }

  StaticLabelPreviewData buildTeaStaticLabelPreview({
    required String productName,
    required String barcodeString,
    required String grossWeight,
    Map<String, dynamic>? labelFields,
  }) {
    const ignoredKeys = {
      'sr no',
      'gross weight',
      'tare weight',
      'net weight',
      'weight',
    };

    final companyData = companyDetails.value?.data;
    String attributeLabel = '';
    String attributeValue = '';

    labelFields?.forEach((key, value) {
      if (attributeLabel.isNotEmpty) return;
      final normalizedKey = key.trim().toLowerCase();
      final normalizedValue = value.toString().trim();
      if (normalizedValue.isEmpty || ignoredKeys.contains(normalizedKey)) {
        return;
      }
      attributeLabel = key.trim();
      attributeValue = normalizedValue;
    });

    return StaticLabelPreviewData(
      format: LabelFormat.MajedarTea,
      width: 600,
      height: 410,
      isWhiteLabel: isWhiteLabel.value,
      printTime: printTimeInLabel.value,
      printSerialNumber: printSerialNumberInLabel.value,
      isGrid: false,
      companyName: companyData?.name ?? 'Majedar Tea Co.',
      companyInfoLines: buildCompanyInfoLines(companyData),
      address: companyData?.address?.trim() ?? '',
      phone: companyData?.contactNo?.trim() ?? '',
      email: companyData?.email?.trim() ?? '',
      productName: productName,
      barcodeData: barcodeString,
      serialNumber: '',
      footerText: '',
      businessHours: '',
      attributeLabel: attributeLabel,
      description: attributeValue,
      grossWeight: grossWeight,
      previewedAt: Utility.nowWithoutSeconds(),
      layout: null,
      attributes: const [],
    );
  }

  StaticLabelPreviewData buildDryFruitStaticLabelPreview({
    required String productName,
    required String barcodeString,
    required String grossWeight,
    Map<String, dynamic>? labelFields,
  }) {
    final companyData = companyDetails.value?.data;
    final attrs = buildDryFruitLabelAttributes(labelFields)
        .map(
          (item) => StaticLabelPreviewAttribute(
            key: item['key']?.toString() ?? '',
            value: item['value']?.toString() ?? '',
          ),
        )
        .toList();

    String attributeLabel = '';
    String attributeValue = '';
    if (attrs.isNotEmpty) {
      attributeLabel = attrs.first.key;
      attributeValue = attrs.first.value;
    }

    return StaticLabelPreviewData(
      format: LabelFormat.DryFruit,
      width: 600,
      height: 410,
      isWhiteLabel: isWhiteLabel.value,
      printTime: printTimeInLabel.value,
      printSerialNumber: false,
      isGrid: false,
      companyName: companyData?.name ?? '',
      companyInfoLines: buildCompanyInfoLines(companyData),
      address: companyData?.address?.trim() ?? '',
      phone: companyData?.contactNo?.trim() ?? '',
      email: companyData?.email?.trim() ?? '',
      productName: productName,
      barcodeData: barcodeString,
      serialNumber: '',
      footerText: '',
      businessHours: '',
      attributeLabel: attributeLabel,
      description: attributeValue,
      grossWeight: grossWeight,
      previewedAt: Utility.nowWithoutSeconds(),
      layout: null,
      attributes: attrs,
    );
  }

  StaticLabelPreviewLayout _toStaticPreviewLayout(LabelLayout layout) {
    return StaticLabelPreviewLayout(
      maxAttributes: layout.maxAttributes,
      lineHeight: layout.lineHeight,
      keyFont: layout.keyFont,
      valueFont: layout.valueFont,
      bottomPadding: layout.bottomPadding,
      columnGap: layout.columnGap,
      barcodeHeight: layout.barcodeHeight,
    );
  }

  Future<void> printOneSticker({
    required int stickerHeight,
    required int stickerWidth,
    required int margin,
    required int thickness,
    required String barcode,
    required String productName,
    required LabelFormat format,
    required bool isGrid,
    String? businessHours,
    Map<String, dynamic>? labelFields,
    required LabelLayout label_layout,
  }) async {
    try {
      // COMPANY DETAILS SAFE HANDLING

      final companyData = companyDetails.value?.data;
      final companyName = companyData?.name ?? "";
      final List<String> companyInfoLines = buildCompanyInfoLines(companyData);

      // CONVERT labelFields → attribute list
      final List<Map<String, dynamic>> dynamicAttributes = [];
      if (labelFields != null) {
        labelFields.forEach((key, value) {
          dynamicAttributes.add({"key": key, "value": value.toString()});
        });
      }

      if (isLabelPrinterMode.value == false) {
        bluetoothController.printReceipt(
          companyName: companyName,
          companyContact: companyInfoLines,
          items: dynamicAttributes,
          barcodeData: barcode,
        );
      } else {
        // CALLING PLATFORM
        final payload = {
          "width": stickerWidth,
          "height": stickerHeight,
          //"fontSize": fontSizeForFormat(format),
          "margin": margin,
          "thickness": thickness,
          "barcodeData": barcode,
          "productName": "Product Name :- $productName",
          "isGrid": isGrid,
          "isWhiteLabel": isWhiteLabel.value,
          "printTime": printTimeInLabel.value,
          "companyName": companyName,
          "companyContact": companyInfoLines.join("\n"),
          "attributes": dynamicAttributes,
          "layout": label_layout.toMap(), // 👈 KEY
          "businessHours": businessHours ?? "",
        };
        final result = await _invokeLabelPrintRepeated(
          "printTestSticker",
          payload,
        );

        print(result);
      }
      //bluetoothController.printReceipt(companyName: companyName, companyContact: companyData?.email ?? '', address: companyData?.address ?? "", items: dynamicAttributes, barcodeData: barcode);
    } catch (e) {
      print("Error printing sticker: $e");
    }
  }

  Future<void> printTeaSmallSticker({
    required String barcodeString,
    required String productName,
    required int noAttribute,
    required double netweight,
    Map<String, dynamic>? labelFields,
  }) async {
    print("printTeaLabel CALLED");
    await printTeaLabel(
      barcodeString: barcodeString,
      productName: productName,
      noAttribute: noAttribute,
      netweight: netweight,
      labelFields: labelFields,
    );
  }

  Future<void> printDryFruitSmallSticker({
    required String barcodeString,
    required String productName,
    required int noAttribute,
    required double netweight,
    Map<String, dynamic>? labelFields,
  }) async {
    print("printDryFruitLabel CALLED");
    await printDryFruitLabel(
      barcodeString: barcodeString,
      productName: productName,
      noAttribute: noAttribute,
      netweight: netweight,
      labelFields: labelFields,
    );
  }

  Future<void> printNeoLabelSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
  }) async {
    try {
      final companyData = companyDetails.value?.data;
      final companyName = companyData?.name ?? "";
      final address = companyData?.address?.trim() ?? "";
      final phone = companyData?.contactNo?.trim() ?? "";
      final email = companyData?.email?.trim() ?? "";
      final dynamicAttributes = buildNeoLabelAttributes(labelFields);
      final serialNumber = printSerialNumberInLabel.value
          ? ((labelFields?["Sr No "] ?? labelFields?["Sr No"])
                    ?.toString()
                    .trim() ??
                "")
          : "";

      if (isLabelPrinterMode.value == false) {
        final items = <Map<String, dynamic>>[
          if (serialNumber.isNotEmpty) {"key": "Sr No", "value": serialNumber},
          ...dynamicAttributes,
        ];

        final companyContact = <String?>[
          if (address.isNotEmpty) address,
          if (phone.isNotEmpty) "Phone: $phone",
          if (email.isNotEmpty) "Email: $email",
        ];

        bluetoothController.printReceipt(
          companyName: companyName,
          companyContact: companyContact,
          items: items,
          barcodeData: barcodeString,
        );
      } else {
        final payload = {
          "width": 700,
          "height": 600,
          "margin": 0,
          "companyName": companyName,
          "address": address,
          "phone": phone,
          "email": email,
          "productName": productName,
          "barcodeData": barcodeString,
          "attributes": dynamicAttributes,
          "serialNumber": serialNumber,
          "printSerialNumber": printSerialNumberInLabel.value,
          "layout": neoLabelLayout.toMap(),
          "isWhiteLabel": isWhiteLabel.value,
          "printTime": printTimeInLabel.value,
        };
        final result = await _invokeLabelPrintRepeated(
          "printNeoLabelSticker",
          payload,
        );

        print(result);
      }
    } catch (e) {
      print("Error printing neo label sticker: $e");
    }
  }

  Future<void> printSmallSevenLabelSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
  }) async {
    try {
      final companyData = companyDetails.value?.data;
      final companyName = companyData?.name ?? "";
      final address = companyData?.address?.trim() ?? "";
      final phone = companyData?.contactNo?.trim() ?? "";
      final email = companyData?.email?.trim() ?? "";
      final dynamicAttributes = buildSmallSevenLabelAttributes(labelFields);
      final serialNumber = printSerialNumberInLabel.value
          ? ((labelFields?["Sr No "] ?? labelFields?["Sr No"])
                    ?.toString()
                    .trim() ??
                "")
          : "";

      if (isLabelPrinterMode.value == false) {
        final items = <Map<String, dynamic>>[
          if (serialNumber.isNotEmpty) {"key": "Sr No", "value": serialNumber},
          ...dynamicAttributes,
        ];

        final companyContact = <String?>[
          if (address.isNotEmpty) address,
          if (phone.isNotEmpty) "Phone: $phone",
          if (email.isNotEmpty) "Email: $email",
        ];

        bluetoothController.printReceipt(
          companyName: companyName,
          companyContact: companyContact,
          items: items,
          barcodeData: barcodeString,
        );
      } else {
        final payload = {
          "width": 600,
          "height": 410,
          "margin": 0,
          "companyName": companyName,
          "address": address,
          "phone": phone,
          "email": email,
          "productName": productName,
          "barcodeData": barcodeString,
          "attributes": dynamicAttributes,
          "serialNumber": serialNumber,
          "printSerialNumber": printSerialNumberInLabel.value,
          "layout": smallSevenLabelLayout.toMap(),
          "isWhiteLabel": isWhiteLabel.value,
          "printTime": printTimeInLabel.value,
        };
        final result = await _invokeLabelPrintRepeated(
          "printSmallSevenLabelSticker",
          payload,
        );

        print(result);
      }
    } catch (e) {
      print("Error printing small seven label sticker: $e");
    }
  }

  Future<void> printTeaLabel({
    required String barcodeString,
    required String productName,
    required int noAttribute,
    required double netweight,
    Map<String, dynamic>? labelFields,
  }) async {
    try {
      final companyData = companyDetails.value?.data;
      final companyName = companyData?.name ?? "Majedar Tea Co.";
      const ignoredKeys = {
        "sr no",
        "gross weight",
        "tare weight",
        "net weight",
        "weight",
      };
      String attributeLabel = "";
      String attributeValue = "";

      labelFields?.forEach((key, value) {
        if (attributeLabel.isNotEmpty) return;

        final normalizedKey = key.trim().toLowerCase();
        final normalizedValue = value.toString().trim();

        if (normalizedValue.isEmpty || ignoredKeys.contains(normalizedKey)) {
          return;
        }

        attributeLabel = key.trim();
        attributeValue = normalizedValue;
      });

      if (isLabelPrinterMode.value == false) {
        bluetoothController.printReceipt(
          companyName: companyName,
          companyContact: buildCompanyInfoLines(companyData),
          items: [
            {"key": "Product", "value": productName},
            {
              "key": attributeLabel.isNotEmpty ? attributeLabel : "Description",
              "value": attributeValue,
            },
            {"key": "Gross Wt", "value": "${netweight.toStringAsFixed(3)} kg"},
          ],
          barcodeData: barcodeString,
        );
      } else {
        final payload = {
          "width": 600,
          "height": 410,
          "margin": 0,
          "companyName": companyName,
          "barcodeData": barcodeString,

          /// ✅ Send clean 3 values
          "productName": productName,
          "grossWt": netweight.toStringAsFixed(3),
          "attributeLabel": attributeLabel,
          "description": attributeValue,

          "isWhiteLabel": isWhiteLabel.value,
          "printTime": printTimeInLabel.value,
        };
        final result = await _invokeLabelPrintRepeated(
          "printTeaSticker",
          payload,
        );

        print(result);
      }
    } catch (e) {
      print("Error printing tea sticker: $e");
    }
  }

  Future<void> printDryFruitLabel({
    required String barcodeString,
    required String productName,
    required int noAttribute,
    required double netweight,
    Map<String, dynamic>? labelFields,
  }) async {
    try {
      final companyData = companyDetails.value?.data;
      final companyName = companyData?.name ?? "Majedar Tea Co.";
      print("dynamic attributes ===========> ${jsonEncode(labelFields)}");
      final dynamicAttributes = buildDryFruitLabelAttributes(labelFields);

      print("label attributes ===========> ${jsonEncode(dynamicAttributes)}");
      final firstAttribute = dynamicAttributes.isNotEmpty
          ? dynamicAttributes.first
          : const <String, dynamic>{};
      final attributeLabel = (firstAttribute["key"]?.toString() ?? "").trim();
      final attributeValue = (firstAttribute["value"]?.toString() ?? "").trim();

      if (isLabelPrinterMode.value == false) {
        bluetoothController.printReceipt(
          companyName: companyName,
          companyContact: buildCompanyInfoLines(companyData),
          items: [
            {"key": "Product", "value": productName},
            ...dynamicAttributes,
            {"key": "Gross Wt", "value": "${netweight.toStringAsFixed(3)} kg"},
          ],
          barcodeData: barcodeString,
        );
      } else {
        final payload = {
          "width": 600,
          "height": 410,
          "margin": 0,
          "companyName": companyName,
          "barcodeData": barcodeString,

          /// ✅ Send clean 3 values
          "productName": productName,
          "grossWt": netweight.toStringAsFixed(3),
          "attributeLabel": attributeLabel,
          "description": attributeValue,
          "attributes": dynamicAttributes,

          "isWhiteLabel": isWhiteLabel.value,
          "printTime": printTimeInLabel.value,
        };
        final result = await _invokeLabelPrintRepeated(
          "printDryFruitSticker",
          payload,
        );

        print(result);
      }
    } catch (e) {
      print("Error printing tea sticker: $e");
    }
  }

  /// Print 50 X 75 Sticker
  Future<void> printSmallSticker({
    required String barcodeString,
    required String productName,
    required int noAttribute,
    Map<String, dynamic>? labelFields,
  }) async {
    if (noAttribute > 1) {
      await printOneSticker(
        stickerHeight: 410,
        stickerWidth: 600,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: true,
        labelFields: labelFields,
        format: LabelFormat.Small,
        label_layout: smallLabelLayout,
      );
    } else {
      await printOneSticker(
        stickerHeight: 410,
        stickerWidth: 600,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
        format: LabelFormat.Small,
        label_layout: smallLabelLayout,
      );
    }
  }

  /// Print 75 X 75 Sticker
  Future<void> printMediumSticker({
    required String barcodeString,
    required String productName,
    required int noAttribute,
    Map<String, dynamic>? labelFields,
  }) async {
    if (noAttribute > 5) {
      await printOneSticker(
        stickerHeight: 600,
        stickerWidth: 600,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: true,
        labelFields: labelFields,
        format: LabelFormat.Medium,
        label_layout: largeLabelLayout,
      );
    } else {
      await printOneSticker(
        stickerHeight: 600,
        stickerWidth: 600,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
        format: LabelFormat.Medium,
        label_layout: largeLabelLayout,
      );
    }
  }

  /// Print 75 X 100 Sticker
  Future<void> printLargeSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
    required int noAttribute,
  }) async {
    if (noAttribute > 5) {
      await printOneSticker(
        stickerHeight: 600,
        stickerWidth: 700,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: true,
        labelFields: labelFields,
        format: LabelFormat.Large,
        label_layout: largeLabelLayout,
      );
    } else {
      await printOneSticker(
        stickerHeight: 600,
        stickerWidth: 700,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
        format: LabelFormat.Large,
        label_layout: largeLabelLayout,
      );
    }
  }

  /// Print 100 X 100 Sticker
  Future<void> printExtraLargeSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
    required int noAttribute,
  }) async {
    if (noAttribute > 5) {
      await printOneSticker(
        stickerHeight: 700,
        stickerWidth: 700,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: true,
        labelFields: labelFields,
        format: LabelFormat.ExtraLarge,
        label_layout: largeLabelLayout,
      );
    } else {
      await printOneSticker(
        stickerHeight: 700,
        stickerWidth: 700,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
        format: LabelFormat.ExtraLarge,
        label_layout: largeLabelLayout,
      );
    }
  }

  /// Print 100 X 150mm Wholesale Pack Sticker
  Future<void> printWholesalePackSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
    required int noAttribute,
  }) async {
    await printOneSticker(
      stickerHeight: 1200,
      stickerWidth: 700,
      margin: 0,
      thickness: 0,
      productName: productName,
      barcode: barcodeString,
      isGrid: false,
      labelFields: labelFields,
      format: LabelFormat.WholesalePack,
      label_layout: wholesalePackLayout,
      businessHours: "On working day 11:00AM - 6:00PM",
    );
  }

  Future<void> checkPrinterStatus() async {
    try {
      final status = await platform.invokeMethod<Map>('getPrinterStatus');

      if (status == null) {
        return;
      }

      bool currentlyConnected = status["connected"] == true;

      // 🔥 Detect disconnect ONLY if it was connected before
      if (!currentlyConnected) {
        if (isPrinterConnected.value == true) {
          Get.snackbar(
            "Printer Disconnected",
            status["message"] ?? "Connection lost unexpectedly.",
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 3),
          );
          isPrinterConnected.value = false;
        }
        return;
      }

      // 🔥 Printer is connected
      isPrinterConnected.value = true;
      // statusMessage.value = _formatStatus(status);
    } catch (e) {
      if (isPrinterConnected.value == true) {
        Get.snackbar(
          "Printer Disconnected",
          "Status error: $e",
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _cancelAllCharSubs() async {
    for (final sub in _charSubs.values) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    _charSubs.clear();
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  Future<void> logout() async {
    try {
      await androidScaleController.disconnect(clearSavedDevice: true);
    } catch (_) {}

    try {
      if (connectedDevice.value != null) {
        await disconnectDevice();
      }
    } catch (_) {}

    try {
      if (bluetoothController.connectedDevice != null) {
        await bluetoothController.disconnect();
      }
    } catch (_) {}

    try {
      if (isPrinterConnected.value) {
        await disconnectPrinter();
      }
    } catch (_) {}

    try {
      await tower_controller.disconnect();
    } catch (_) {}

    await BluetoothDeviceStore.clearDevice(BluetoothDeviceStore.scaleKey);
    await BluetoothDeviceStore.clearDevice(BluetoothDeviceStore.printerKey);
    await BluetoothDeviceStore.clearDevice(
      BluetoothDeviceStore.receiptPrinterKey,
    );
    await BluetoothDeviceStore.clearDevice(BluetoothDeviceStore.towerLightKey);
    await TokenStorage.clearAll();

    isWeightScaleConnected.value = false;
    isExperimentalScaleConnected.value = false;
    isPrinterConnected.value = false;
    receivedData.value = '';
    statusMessage.value = '';

    RouteManagement.offToLogin();
  }

  Future<void> autoReconnectDevicesOnStartup() async {
    await _runReconnectSafely(_tryAutoReconnectScale);
    await _runReconnectSafely(_tryAutoReconnectLabelPrinter);
    await _runReconnectSafely(bluetoothController.tryAutoReconnectFromSaved);
    await _runReconnectSafely(tower_controller.tryAutoReconnectFromSaved);
  }

  Future<void> disconnectActiveScale() async {
    if (androidScaleController.isConnected || isAnyScaleConnected) {
      await androidScaleController.disconnect();
      isWeightScaleConnected.value = false;
      isExperimentalScaleConnected.value = false;
      receivedData.value = '';
    }
  }

  Future<void> disconnectActivePrinter() async {
    if (isLabelPrinterMode.value) {
      if (isPrinterConnected.value) {
        await disconnectPrinter();
      }
      return;
    }

    if (bluetoothController.isConnected.value) {
      await bluetoothController.disconnect();
    }
  }

  Future<void> _runReconnectSafely(Future<void> Function() fn) async {
    try {
      await fn().timeout(const Duration(seconds: 12));
    } catch (_) {}
  }

  Future<void> _tryAutoReconnectScale() async {
    if (isWeightScaleConnected.value) return;
    await androidScaleController.tryAutoReconnectFromSaved();
  }

  Future<void> _tryAutoReconnectLabelPrinter() async {
    if (isPrinterConnected.value) return;

    final savedMac = await BluetoothDeviceStore.getDevice(
      BluetoothDeviceStore.printerKey,
    );
    if (savedMac == null || savedMac.isEmpty) return;

    await connectPrinterWithMac(savedMac);
  }

  Future<void> connectPrinterWithMac(String macAddress) async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    try {
      final result = await platform.invokeMethod(
        'connectPrinter',
        {"mac": macAddress}, // pass MAC
      );

      statusMessage.value = "Connected" + result;
      isPrinterConnected.value = true;
      await BluetoothDeviceStore.saveDevice(
        BluetoothDeviceStore.printerKey,
        macAddress,
      );
      // wasPrinterEverConnected.value = true;    // MARK it now
      // await checkPrinterStatus();              // prime status immediately
    } catch (e) {
      isPrinterConnected.value = false;

      statusMessage.value = "Error connecting printer: $e";
    }
  }

  Future<void> handlePermissions() async {
    if (!await checkAllPermissionsGranted()) {
      await requestPermissions();
    }
  }

  Future<void> requestPermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.status;

      if (!status.isGranted) {
        final result = await permission.request();

        if (result.isPermanentlyDenied) {
          // If permanently denied, show a dialog
          showPermissionDialog(permission);
        } else if (result.isDenied) {
          Get.snackbar(
            'Permission Denied',
            '${permission.toString().split(".").last} permission is required to continue.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        print('${permission.toString()} already granted.');
      }
    }
  }

  void showPermissionDialog(Permission permission) {
    Get.defaultDialog(
      title: 'Permission Required',
      middleText:
          'The app needs ${permission.toString().split(".").last} permission to work properly.\n\nPlease enable it from settings.',
      textConfirm: 'Open Settings',
      textCancel: 'Cancel',
      onConfirm: () async {
        Get.back(); // Close dialog
        await openAppSettings(); // Opens device settings
      },
      onCancel: () {
        Get.back();
      },
      barrierDismissible: false,
    );
  }

  Future<bool> checkAllPermissionsGranted() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      if (!await permission.isGranted) {
        return false;
      }
    }
    return true;
  }

  Future<void> startScan({required String roles}) async {
    scanResults.clear();
    isScanning.value = true;
    await handlePermissions();
    await FlutterBluePlus.stopScan();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      // Sort results: devices starting with "BT" go first
      if (roles == SStringConstants.role_scale) {
        results.sort((a, b) {
          final aName = BluetoothDeviceDisplay.displayName(a);
          final bName = BluetoothDeviceDisplay.displayName(b);

          final aIsBT = aName.startsWith("BT");
          final bIsBT = bName.startsWith("BT");

          if (aIsBT && !bIsBT) return -1; // a comes first
          if (bIsBT && !aIsBT) return 1; // b comes first

          // fallback: sort alphabetically or by RSSI
          return aName.compareTo(bName);
          // Or: return b.rssi.compareTo(a.rssi); // if you prefer strongest signal
        });
      }

      scanResults.assignAll(results);
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      isScanning.value = scanning;
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (connectedDevice.value?.remoteId == device.remoteId &&
        isWeightScaleConnected.value) {
      return;
    }

    connectingDeviceId.value = BluetoothDeviceDisplay.deviceIdFromDevice(
      device,
    ); // mark this device as connecting

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    await _cancelAllCharSubs();
    await _cancelScaleConnectionSub();

    if (connectedDevice.value != null &&
        connectedDevice.value?.remoteId != device.remoteId) {
      try {
        await connectedDevice.value?.disconnect();
      } catch (_) {}
      connectedDevice.value = null;
    }

    try {
      await device.connect(autoConnect: false);
      connectedDevice.value = device;
      isWeightScaleConnected.value = true;
      isExperimentalScaleConnected.value = false;
      _scaleConnectionSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleBleScaleDisconnected(device);
        } else if (state == BluetoothConnectionState.connected &&
            connectedDevice.value?.remoteId == device.remoteId) {
          isWeightScaleConnected.value = true;
        }
      });
      device.cancelWhenDisconnected(_scaleConnectionSub!, delayed: true);
      final services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.read) {
            final uuid = characteristic.uuid.toString().toLowerCase();

            if (_charSubs.containsKey(uuid)) continue;

            try {
              await characteristic.setNotifyValue(true);
              // final sub = characteristic.value.listen((value) {
              //   receivedData.value = String.fromCharCodes(value);
              // });
              final sub = characteristic.lastValueStream.listen((value) {
                final raw = String.fromCharCodes(value);

                // 1. Update raw data
                debugPrint('Scale receivedData(ble): "$raw"');
                receivedData.value = raw;

                // 2. Parse weight from raw string
                final weight = parseWeight(raw);
                if (weight != null) {
                  // 3. Keep manualGross in sync with Bluetooth gross
                  try {
                    print(
                      'manual weight ---------------------------------------------> $activeManualWeightTag',
                    );

                    /// Inward
                    manualBatchWeights.manualGross.value = weight
                        .toStringAsFixed(3);
                    manualBatchWeights.calculateManualNet();
                    manualNonBatchWeights.manualGross.value = weight
                        .toStringAsFixed(3);
                    manualNonBatchWeights.calculateManualNet();
                    manualTareWeights.manualGross.value = weight
                        .toStringAsFixed(3);
                  } catch (e) {
                    debugPrint("ManualWeightController not found for tag");
                  }
                }
              });

              _charSubs[uuid] = sub;
            } catch (e) {
              debugPrint('Failed to subscribe to $uuid: $e');
            }
            break;
          }
        }
      }
      await BluetoothDeviceStore.saveDevice(
        BluetoothDeviceStore.scaleKey,
        BluetoothDeviceDisplay.deviceIdFromDevice(device),
      );
    } catch (e) {
      await _cancelScaleConnectionSub();
      connectedDevice.value = null;
      debugPrint("Connection failed: $e");
      isWeightScaleConnected.value = false;
      isExperimentalScaleConnected.value = false;
      Get.snackbar("Error", "Failed to connect: $e");
    } finally {
      connectingDeviceId.value = null; // reset after attempt
    }
  }

  Future<void> disconnectDevice() async {
    // 1) cancel characteristic subscriptions
    await _cancelAllCharSubs();
    await _cancelScaleConnectionSub();

    // 2) disconnect device safely
    try {
      await connectedDevice.value?.disconnect();
      isWeightScaleConnected.value = false;
      isExperimentalScaleConnected.value = false;
    } catch (e) {
      debugPrint('Error while disconnecting: $e');
    }
    connectedDevice.value = null;
    receivedData.value = '';
    await BluetoothDeviceStore.clearDevice(BluetoothDeviceStore.scaleKey);
    //startScan(roles: '');
  }

  double? parseWeight(String raw) {
    if (raw.trim().isEmpty) return null;
    final cleaned = raw
        .replaceAll(',', '.')
        .replaceAll('\u0000', ' ')
        .replaceAll(RegExp(r'[\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;

    final chunks = cleaned
        .split(RegExp(r'[\r\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList()
        .reversed;

    for (final chunk in chunks) {
      final parsed = _extractWeightFromChunk(chunk);
      if (parsed != null) return parsed;
    }

    return _extractWeightFromChunk(cleaned);
  }

  double? _extractWeightFromChunk(String chunk) {
    final matches = RegExp(r'[-+]?\d*\.?\d+').allMatches(chunk).toList();
    if (matches.isEmpty) return null;

    final lowerChunk = chunk.toLowerCase();
    final hasDecimalCandidate = matches.any(
      (match) => (match.group(0) ?? '').contains('.'),
    );

    double? bestValue;
    int? bestScore;
    int bestStart = -1;

    for (final match in matches) {
      final token = match.group(0);
      if (token == null || token.trim().isEmpty) continue;

      final value = double.tryParse(token);
      if (value == null) continue;

      var score = 0;
      if (token.contains('.')) score += 40;
      if (value.abs() < 1000) score += 5;
      if ((token == '0' || token == '00' || token == '000') &&
          hasDecimalCandidate) {
        score -= 40;
      }
      if (!token.contains('.') && token.length <= 1 && hasDecimalCandidate) {
        score -= 20;
      }

      final contextStart = (match.start - 6).clamp(0, lowerChunk.length);
      final contextEnd = (match.end + 6).clamp(0, lowerChunk.length);
      final context = lowerChunk.substring(contextStart, contextEnd);
      if (RegExp(r'(kg|kgs|gm|gms|gram|grams|wt|weight)').hasMatch(context)) {
        score += 80;
      }

      if (bestScore == null ||
          score > bestScore ||
          (score == bestScore && match.start > bestStart)) {
        bestScore = score;
        bestValue = value;
        bestStart = match.start;
      }
    }

    return bestValue;
  }

  /// Disconnect printer
  Future<void> disconnectPrinter() async {
    try {
      final result = await platform.invokeMethod('disconnectPrinter');
      statusMessage.value = result;
      isPrinterConnected.value = false;
      await BluetoothDeviceStore.clearDevice(BluetoothDeviceStore.printerKey);
    } catch (e) {
      statusMessage.value = "Error disconnecting: $e";
    }
  }
}

class module {
  int id;
  String name;
  bool autoWeight;
  double minWeight;
  double maxWeight;
  double seconds;
  double productTareWeight;
  bool unitConversion;
  double unitValue;
  module({
    required this.id,
    required this.name,
    this.autoWeight = false,
    this.minWeight = 10.0,
    this.maxWeight = 20.0,
    this.seconds = 5,
    this.productTareWeight = 0,
    this.unitConversion = false,
    this.unitValue = 0,
  });
}

class ManualWeightController extends GetxController {
  final grossCtrl = TextEditingController();
  final tareCtrl = TextEditingController();

  var manualGross = Rxn<String>();
  var manualTare = Rxn<String>();
  var manualNet = Rxn<String>();
  //var manualUnit = Rxn<String>();

  void calculateManualNet() {
    final gross = double.tryParse(manualGross.value ?? '') ?? 0.0;
    final tare = double.tryParse(manualTare.value ?? '') ?? 0.0;
    manualNet.value = (gross - tare).toStringAsFixed(3);
  }
}

class LabelLayout {
  final int maxAttributes;
  final int lineHeight;
  final int keyFont;
  final int valueFont;
  final int bottomPadding;
  final int columnGap;
  final int barcodeHeight;

  const LabelLayout({
    required this.maxAttributes,
    required this.lineHeight,
    required this.keyFont,
    required this.valueFont,
    required this.bottomPadding,
    required this.columnGap,
    required this.barcodeHeight,
  });

  Map<String, dynamic> toMap() => {
    "maxAttributes": maxAttributes,
    "lineHeight": lineHeight,
    "keyFont": keyFont,
    "valueFont": valueFont,
    "bottomPadding": bottomPadding,
    "columnGap": columnGap,
    "barcodeHeight": barcodeHeight,
  };
}

class RuntimeLabelDimensions {
  final int width;
  final int height;

  const RuntimeLabelDimensions({required this.width, required this.height});
}

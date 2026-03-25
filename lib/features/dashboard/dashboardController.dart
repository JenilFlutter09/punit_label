import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:punit_label/constants/enums.dart';
import 'package:punit_label/constants/utility.dart';
import 'package:punit_label/features/dashboard/dashboardModel.dart';
import 'package:punit_label/features/login/loginmodel.dart';

import '../../apis/connectHelper.dart';
import '../../apis/responseModel.dart';
import '../../apis/sharedPreference.dart';
import '../../constants/strings.dart';
import '../../navigation/routesManagement.dart';
import '../../widgets/searchableDropdown.dart';
import '../../widgets/usbSerial.dart';
import '../inward/models/singleProduct.dart';
import 'bluetoothController.dart';
import 'companyModel.dart';

typedef ApiCall = Future<ResponseModel> Function();

class DashboardController extends GetxController {
  static const platform = MethodChannel('label_printer');
  var selectedIndex = 0.obs;
  var isLabelPrinterMode = true.obs;
  var isTowerLight = false.obs;
  var isWeightScaleConnected = false.obs;
  ConnectHelper connectHelper = ConnectHelper();
  var isPrinterConnected = false.obs;
  final Map<String, StreamSubscription<List<int>>> _charSubs = {};
  var scanResults = <ScanResult>[].obs;
  Rx<TareState> tareState = TareState.on.obs;
  Rx<LabelState> labelState = LabelState.Label.obs;
 // Rx<DeviceState> towerLight = DeviceState.on.obs;
  var isWhiteLabel = false.obs;
  var printSerialNumberInLabel = false.obs;
  var printTimeInLabel = false.obs;
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
  RxBool isLoading = false.obs;

  RxInt totalProducts = 0.obs;
  RxInt totalVariants = 0.obs;
  RxString totalInventory = "0".obs;
  var selectedFilter = "top".obs;

  RxList<TopProducts> topProducts = <TopProducts>[].obs;
  RxList<LowStockProducts> lowStockProducts = <LowStockProducts>[].obs;

  RxList<LabelFormatElement> labelFormats = <LabelFormatElement>[].obs;
  final smallLabelLayout = LabelLayout(
    maxAttributes: 6,
    lineHeight: 40,
    keyFont: 24,
    valueFont: 26,
    bottomPadding: 80,
    columnGap: 140,
    barcodeHeight: 45
  );

  final largeLabelLayout = LabelLayout(
    maxAttributes: 10,
    lineHeight: 60,
    keyFont: 30,
    valueFont: 34,
    bottomPadding: 150,
    columnGap: 200,
    barcodeHeight: 80
  );

  final wholesalePackLayout = LabelLayout(
    maxAttributes: 10,
    lineHeight: 60,
    keyFont: 40,      // 5mm
    valueFont: 40,    // 5mm
    bottomPadding: 180,
    columnGap: 400,
    barcodeHeight: 90,
);

  final dryfruitLabelLayout = LabelLayout(
    maxAttributes: 6,      // Product Name, Batch No, Packed On, Quantity, Net Weight, Gross Weight, + 1 for barcode
    lineHeight: 30,        // Compact for smaller label
    keyFont: 24,           // Smaller font for 75mm x 50mm
    valueFont: 26,
    bottomPadding:170,     // Room for barcode at bottom
    columnGap: 170,        // Space for single column layout
    barcodeHeight: 60      // Smaller barcode
  );

  final tower_controller = Get.put(TowerLightController());

// Example triggers
//   controller.updateState(DeviceState.inLimit);
//   controller.updateState(DeviceState.almostLimit);
//   controller.updateState(DeviceState.outOfLimit);


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    // // react to white label toggle
    // ever(isWhiteLabel, (_) {
    //   loadLabelFormats();
    // });
    //
    // // initial load
    // loadLabelFormats();
  }

  @override
  Future<void> onReady() async {
    // TODO: implement onReady
    super.onReady();
    await handlePermissions();
    await getUserDetails();
    await getDashboardDetails();
    await getCompanyDetails();
    loadLabelFormats();
    ever(isWhiteLabel, (_) {
      loadLabelFormats();
    });
    printerTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkPrinterConnection();
    });
  }

  @override
  void onClose() {
    // TODO: implement onClose
    _cancelAllCharSubs();
    printerTimer?.cancel();
    super.onClose();
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
        data: jsonEncode({
          "message": "Request already running",
          "code": 429,
        }),
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
        data: jsonEncode({
          "message": "Request timed out",
          "code": 408,
        }),
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
        data: jsonEncode({
          "message": "No Internet Connection",
          "code": 408,
        }),
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
        data: jsonEncode({
          "message": "Unexpected error occurred",
          "code": 500,
        }),
      );

      _handleApiError(error);
      if (throwOnError) throw error;
      return error;
    }

    finally {
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
        LabelFormatElement(
          5,
          "Wholesale Pack",
          10, 
          LabelFormat.WholesalePack),

        LabelFormatElement(
          6,
          "Dryfruit Label Select Max (6)",
          6,
          LabelFormat.Dryfruit),
      ];
    } else {
      labelFormats.value = [
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
        LabelFormatElement(
          5,
          "Wholesale Pack",
          10, 
          LabelFormat.WholesalePack),
        LabelFormatElement(
          6,
          "Dryfruit Label Select Max (6)",
          6,
          LabelFormat.Dryfruit),
      ];
    }
  }

  void checkPrinterConnection() {
    if (isPrinterConnected.value) {
      checkPrinterStatus();
    }
  }

  Future<void> getUserDetails() async {
    userDetails.value = await TokenStorage.getUser();
    enableInward.value = userDetails.value?.inventoryUser ?? false;
    enableDispatch.value = userDetails.value?.dispatchUser ?? false;
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
        final result = await platform.invokeMethod("printTestSticker", {
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
        });

        print(result);
      }
      //bluetoothController.printReceipt(companyName: companyName, companyContact: companyData?.email ?? '', address: companyData?.address ?? "", items: dynamicAttributes, barcodeData: barcode);
    } catch (e) {
      print("Error printing sticker: $e");
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

  /// Print 75 X 50mm Dryfruit Label
  Future<void> printDryfruitSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
    required int noAttribute,
  }) async {
    await printOneSticker(
      stickerHeight: 410,    
      stickerWidth: 600,     
      margin: 0,
      thickness: 0,
      productName: productName,
      barcode: barcodeString,
      isGrid: false,
      labelFields: labelFields,
      format: LabelFormat.Dryfruit,
      label_layout: dryfruitLabelLayout,
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

  void logout() {
    TokenStorage.clearAll();
    isPrinterConnected.value = false;
    RouteManagement.offToLogin();
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
          final aName = a.device.name;
          final bName = b.device.name;

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
    if (connectedDevice.value?.id == device.id) return;

    connectingDeviceId.value = device.id.id; // mark this device as connecting

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    await _cancelAllCharSubs();

    try {
      await device.connect(autoConnect: false);
      connectedDevice.value = device;
      isWeightScaleConnected.value = true;
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
              final sub = characteristic.value.listen((value) {
                final raw = String.fromCharCodes(value);

                // 1. Update raw data
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
                        .toStringAsFixed(2);
                    manualBatchWeights.calculateManualNet();
                    manualNonBatchWeights.manualGross.value = weight
                        .toStringAsFixed(2);
                    manualNonBatchWeights.calculateManualNet();
                    manualTareWeights.manualGross.value = weight
                        .toStringAsFixed(2);
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
    } catch (e) {
      debugPrint("Connection failed: $e");
      isWeightScaleConnected.value = false;
      Get.snackbar("Error", "Failed to connect: $e");
    } finally {
      connectingDeviceId.value = null; // reset after attempt
    }
  }

  Future<void> disconnectDevice() async {
    // 1) cancel characteristic subscriptions
    await _cancelAllCharSubs();

    // 2) disconnect device safely
    try {
      await connectedDevice.value?.disconnect();
      isWeightScaleConnected.value = false;
    } catch (e) {
      debugPrint('Error while disconnecting: $e');
    }
    connectedDevice.value = null;
    receivedData.value = '';
    //startScan(roles: '');
  }

  double? parseWeight(String raw) {
    if (raw.trim().isEmpty) return null;
    final cleaned = raw.replaceAll(',', '.');
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(cleaned);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  /// Disconnect printer
  Future<void> disconnectPrinter() async {
    try {
      final result = await platform.invokeMethod('disconnectPrinter');
      statusMessage.value = result;
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
    manualNet.value = (gross - tare).toStringAsFixed(2);
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

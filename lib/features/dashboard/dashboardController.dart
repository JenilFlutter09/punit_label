import 'dart:async';
import 'dart:convert';

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
import '../inward/models/singleProduct.dart';
import 'companyModel.dart';
typedef ApiCall = Future<ResponseModel> Function();

class DashboardController extends GetxController {
  static const platform = MethodChannel('label_printer');
  var selectedIndex = 0.obs;
  //var isBlueToothMode = true.obs;
  var isWeightScaleConnected = false.obs;
  ConnectHelper connectHelper = ConnectHelper();
  var isPrinterConnected = false.obs;
  final Map<String, StreamSubscription<List<int>>> _charSubs = {};
  var scanResults = <ScanResult>[].obs;
  Rx<TareState> tareState = TareState.on.obs;
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
  final manualNonBatchWeights = Get.put(
    ManualWeightController(),
    tag: 'nonbatch',
  );
  var activeManualWeightTag = Rx<String>('');
  var statusMessage = ''.obs;
  Timer? printerTimer;

  RxInt totalProducts = 0.obs;
  RxInt totalVariants = 0.obs;
  RxString totalInventory = "0".obs;
  var selectedFilter = "top".obs;

  RxList<TopProducts> topProducts = <TopProducts>[].obs;
  RxList<LowStockProducts> lowStockProducts = <LowStockProducts>[].obs;

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    await handlePermissions();
    await getUserDetails();
    await getDashboardDetails();
    await getCompanyDetails();
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
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
  }) async
  {
    late ResponseModel response;

    try {
      /// 1️⃣ Initial API call
      response = await apiCall();

      /// 2️⃣ Handle explicit API error
      if (response.hasError) {
        if (response.errorCode == 401) {
          var response = await connectHelper.refreshToken();
          var decodedResponse = refreshModel.fromJson(jsonDecode(response.data));
          await TokenStorage.saveToken(decodedResponse.accessToken ?? 'access Token');
          response = await apiCall(); // 🔁 retry
        } else {
          Utility.showApiErrorSnackbar(response);
          RouteManagement.offToLogin();
          return response;
        }
      }
      //
      // /// 3️⃣ Handle backend token-expired message
      // final decoded = jsonDecode(response.data);
      // if (decoded["message"] == "Token expired") {
      //   await connectHelper.refreshToken();
      //   response = await apiCall(); // 🔁 retry
      // }

      return response;

    } catch (e, stackTrace) {
      /// 💥 Unexpected crash (JSON / null / network)
      debugPrint("❌ API Wrapper Error: $e");
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        "Error",
        "Something went wrong while calling API",
        snackPosition: SnackPosition.BOTTOM,
      );

      /// ❗ Always return a ResponseModel
      return ResponseModel(
        hasError: true,
        data: e.toString(),
      );

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
      var response = await callApi(apiCall: ()=>connectHelper.getCompanyDetails());

      companyDetails.value =
          CompanyDetailsModel.fromJson(jsonDecode(response.data));

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



  Future<void> getDashboardDetails() async {
    try {
      var response = await callApi(apiCall: ()=> connectHelper.getDashboardDetails());

      /// 📦 Parse dashboard data
      dashboardDetails.value =
          dashboardModel.fromJson(jsonDecode(response.data));

      /// 📊 Assign lists safely
      topProducts.assignAll(
        dashboardDetails.value?.data?.topProducts ?? [],
      );

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
/*
  List<String> buildCompanyInfoLines(CompanyData? data) {
    if (data == null || data.labelFields == null) return [];

    final Map<String, String?> valueMap = {
      "name": data.name,
      "email": data.email,
      "contact_no": data.contactNo,
      "gst_no": data.gstNo,
      "address": data.address,
      "website": data.labelFields?['website'], // if website stored elsewhere, adjust
    };

    final List<String> lines = [];

    data.labelFields!.forEach((key, value) {
      if (value == "on") {
        final fieldValue = valueMap[key];
        if (fieldValue != null && fieldValue.isNotEmpty) {
          lines.add(fieldValue);
        }
      }
    });

    return lines;
  }
*/
  List<String> buildCompanyInfoLines(CompanyData? data) {
    if (data == null || data.labelFields == null) return [];

    final valueMap = <String, String>{
      "email": data.email ?? "",
      "contact_no": data.contactNo ?? "",
      "gst_no": data.gstNo ?? "",
      "address": data.address ?? "",
      "website": data.website ?? "",
    };

    final List<String> topLineParts = [];
    String addressLine = "";

    data.labelFields!.forEach((key, toggle) {
      if (toggle == "on" && valueMap.containsKey(key)) {
        final value = valueMap[key]!.trim();

        if (value.isEmpty) return;

        if (key == "address") {
          addressLine = value;
        } else {
          topLineParts.add(value);
        }
      }
    });

    // Limit to max 2 fields in top line
    final limitedTop = topLineParts.take(2).toList();

    final List<String> lines = [];

    if (limitedTop.isNotEmpty) {
      lines.add(limitedTop.join(" | "));
    }

    if (addressLine.isNotEmpty) {
      lines.add(addressLine);
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
    required bool isGrid,
    Map<String, dynamic>? labelFields,
  }) async {
    try {
      // COMPANY DETAILS SAFE HANDLING

      final companyData = companyDetails.value?.data;
      final companyName = companyData?.name ?? "";
      final List<String> companyInfoLines =
      buildCompanyInfoLines(companyData);
      // final name = companyDetails.value?.data?.name ?? "";
      // final contact = companyDetails.value?.data?.contactNo ?? "";
      // final email = companyDetails.value?.data?.email ?? "";
      //
      // final companyContact = (contact.isNotEmpty && email.isNotEmpty)
      //     ? "$contact | $email"
      //     : contact + email;

      // CONVERT labelFields → attribute list
      final List<Map<String, dynamic>> dynamicAttributes = [];
      if (labelFields != null) {
        labelFields.forEach((key, value) {
          dynamicAttributes.add({"key": key, "value": value.toString()});
        });
      }

      // CALLING PLATFORM
      final result = await platform.invokeMethod("printTestSticker", {
        "width": stickerWidth,
        "height": stickerHeight,
        "margin": margin,
        "thickness": thickness,
        "barcodeData": barcode,
        "productName": "Product Name :- $productName",
        "isGrid": isGrid,
        "printTime": printTimeInLabel.value,
        "companyName": companyName,
        "companyContact": companyInfoLines.join("\n"),
        "attributes": dynamicAttributes,
      });

      print(result);
    } catch (e) {
      print("Error printing sticker: $e");
    }
  }
/*
  Future<void> printOneSticker({
    required int stickerHeight,
    required int stickerWidth,
    required int margin,
    required int thickness,
    required String barcode,
    required String productName,
    required bool isGrid,
    Map<String, dynamic>? labelFields,
  }) async {
    try {
      // COMPANY DETAILS SAFE HANDLING

      final companyData = companyDetails.value?.data;
      final companyName = companyData?.name ?? "";
      final List<String> companyInfoLines =
      buildCompanyInfoLines(companyData);
      // final name = companyDetails.value?.data?.name ?? "";
      // final contact = companyDetails.value?.data?.contactNo ?? "";
      // final email = companyDetails.value?.data?.email ?? "";
      //
      // final companyContact = (contact.isNotEmpty && email.isNotEmpty)
      //     ? "$contact | $email"
      //     : contact + email;

      // CONVERT labelFields → attribute list
      final List<Map<String, dynamic>> dynamicAttributes = [];
      if (labelFields != null) {
        labelFields.forEach((key, value) {
          dynamicAttributes.add({"key": key, "value": value.toString()});
        });
      }

      // CALLING PLATFORM
      final result = await platform.invokeMethod("printTestSticker", {
        "width": stickerWidth,
        "height": stickerHeight,
        "margin": margin,
        "thickness": thickness,
        "barcodeData": barcode,
        "productName": "Product Name :- $productName",
        "isGrid": isGrid,
        "printTime": printTimeInLabel.value,
        "companyName": companyName,
        "companyContact": companyInfoLines,
        "attributes": dynamicAttributes,
      });

      print(result);
    } catch (e) {
      print("Error printing sticker: $e");
    }
  }*/
  /// Print 50 X 75 Sticker (2 Attribute)
  Future<void> printSmallSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
  }) async {
    if(printSerialNumberInLabel.value){
    await printOneSticker(
      stickerHeight: 375,
      stickerWidth: 600,
      margin: 0,
      thickness: 0,
      productName: productName,
      barcode: barcodeString,
      isGrid: true,
      labelFields: labelFields,
    );
    }else{
      await printOneSticker(
        stickerHeight: 375,
        stickerWidth: 600,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
      );
    }
  }
  /// Print 75 X 75 Sticker (3 Attribute)
  Future<void> printMediumSticker({
    required String barcodeString,
    required String productName,
    required int noAttribute,
    Map<String, dynamic>? labelFields,
  }) async {
    if(noAttribute > 4) {
      await printOneSticker(
        stickerHeight: 600,
        stickerWidth: 600,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: true,
        labelFields: labelFields,
      );
    }else{
      await printOneSticker(
        stickerHeight: 600,
        stickerWidth: 600,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
      );
    }
  }
  /// Print 75 X 100 Sticker (6 Attribute)
  Future<void> printLargeSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
    required int noAttribute
  }) async {
    if(noAttribute > 4)
      {
        await printOneSticker(
          stickerHeight: 600,
          stickerWidth: 700,
          margin: 0,
          thickness: 0,
          productName: productName,
          barcode: barcodeString,
          isGrid: true,
          labelFields: labelFields,
        );
      }
    else {
      await printOneSticker(
        stickerHeight: 600,
        stickerWidth: 700,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
      );
    }
  }
  /// Print 100 X 100 Sticker (1 Attribute)
  Future<void> printExtraLargeSticker({
    required String barcodeString,
    required String productName,
    Map<String, dynamic>? labelFields,
    required int noAttribute
  }) async {
    if(noAttribute > 5) {
      await printOneSticker(
        stickerHeight: 700,
        stickerWidth: 700,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: true,
        labelFields: labelFields,
      );
    }else{
      await printOneSticker(
        stickerHeight: 700,
        stickerWidth: 700,
        margin: 0,
        thickness: 0,
        productName: productName,
        barcode: barcodeString,
        isGrid: false,
        labelFields: labelFields,
      );
    }
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
    this.unitValue = 0
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

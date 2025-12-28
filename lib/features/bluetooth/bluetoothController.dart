/*
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '/apis/connectHelper.dart';
import '/constants/utility.dart';

import 'models/inwardModel.dart';


import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import 'models/orderDetailModel.dart';
import 'models/orderlistmodel.dart';
import 'models/supervisorModel.dart';

class BluetoothController extends GetxController {
  var scanResults = <ScanResult>[].obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  var receivedData = ''.obs;
  var isScanning = false.obs;
  var isLoading = false.obs;
  var inwardCount = 0.obs;
  var jobWorkCount = 0.obs;
  var dispatchCount = 0.obs;
  ConnectHelper connectHelper = ConnectHelper();
  // Form fields
  var grnNumber = ''.obs;
  var orderNumber = ''.obs;
  //var dropdownCategory = ''.obs;
  var isConnecting = false.obs;
  var connectingDeviceId = Rxn<String>(); // null when idle
  var isBluetoothMode = true.obs; // default ON
  var manualGross = "".obs;
  var manualTare = "".obs;
  var manualNet = "".obs;

  RxList<String> dropdownCustomerList = <String>[].obs;
  RxString dropdownCustomer = "".obs;

  */
/*RxList<String> dropdownProductList = <String>[].obs;
  RxString dropdownProduct = "".obs;*//*

  RxList<module> dropdownProducts = <module>[].obs;
  var selectedProduct = Rxn<module>();

  RxList<module> dropdownSuppliers = <module>[].obs;
  var selectedSupplier = Rxn<module>();


  //RxList<String> dropdownGradeList = <String>[].obs;
  RxString dropdownGrade = "".obs;

  // RxList<String> dropdownSupplierList = <String>[].obs;
  // RxString dropdownSupplier = "".obs;

  // Recorded entries
  var recordedEntries = <Item>[].obs;
  // Static dropdown data (replace with API later)
 // List<String> dropdown1List = [];
 //  List<String> dropdownCategoryList = [
 //    "Raw Materials",
 //    "Finished Goods",
 //    "Scrap",
 //  ];
  final RxList<module> dropdownCategories = <module>[].obs;
  final Rxn<module> selectedCategory = Rxn<module>();
 // List<String> dropdown2List = [];
  List<String> dropdownGradeList = [
    "Grade A",
    "Grade B",
    "Grade C",
    "Grade D",
    "Grade E",
    "Grade F",
  ];
  //List<String> dropdown3List = ["Supervisor X", "Supervisor Y", "Supervisor Z"];
  RxList<module> dropdownSupervisorsList = <module>[].obs;
  var dropdownSupervisor = Rxn<module>();
  var dropdownOrderList = <String>[].obs;

  // keep subscriptions so we can cancel them on disconnect
  final Map<String, StreamSubscription<List<int>>> _charSubs = {};

  @override
  void onInit() {
    super.onInit();
    requestPermissions();
    _fetchorderlist();
    fetchsupervisorslist();
  }

  @override
  void onClose() {
    _cancelAllCharSubs();
    super.onClose();
  }
  /// Fetch Order List
  Future<void> _fetchorderlist() async {
    var response = await connectHelper.getOrderList();
    var decodedresponse = jsonDecode(response.data);
    if(decodedresponse["message"] == "Token expired"){
      await connectHelper.refreshToken();
      response = await connectHelper.getOrderList();
    }
    orderListModel orderlistmodel =
    orderListModel.fromJson(jsonDecode(response.data));

    print("---------------------------fetched order list--------------------");
    print(orderlistmodel.success);

    // ✅ Convert List<int> (model) → List<String> (dropdown)
    dropdownOrderList.value =
        (orderlistmodel.orderIds ?? []).map((e) => e.toString()).toList();

    if (dropdownOrderList.isNotEmpty) {
      orderNumber.value = dropdownOrderList.first;
      await fetchOrderDetail(orderId: orderNumber.value);
    }
  }
  /// Fetch Supervisor List
  Future<void> fetchsupervisorslist() async {
    var response = await connectHelper.getSupervisorList();
    var decodedresponse = jsonDecode(response.data);
    if(decodedresponse["message"] == "Token expired"){
      await connectHelper.refreshToken();
      response = await connectHelper.getSupervisorList();
    }
    supervisorModel supervisormodel =
    supervisorModel.fromJson(jsonDecode(response.data));

    print("---------------------------fetched supervisors list--------------------");
    print(supervisormodel.success);

    // ✅ Convert Supervisors list -> List<module>
    final supervisors = supervisormodel.supervisors
        ?.map((s) => module(id: s.id ?? 0, name: s.name ?? ""))
        .where((m) => m.id != 0 && m.name.isNotEmpty)
        .toList() ??
        [];

    // ✅ Deduplicate by id
    final uniqueSupervisors = {for (var s in supervisors) s.id: s}.values.toList();

    dropdownSupervisorsList.value = uniqueSupervisors;

    if (dropdownSupervisorsList.isNotEmpty) {
      dropdownSupervisor.value = dropdownSupervisorsList.first;
    }
  }

  Future<void> fetchOrderDetail({required String orderId}) async {
    var response = await connectHelper.getOrderDetail(orderId: orderId);
    var decodedresponse = jsonDecode(response.data);
    if(decodedresponse["message"] == "Token expired"){
      await connectHelper.refreshToken();
      response = await connectHelper.getOrderDetail(orderId: orderId);
    }
    orderDetails orderdetailmodel =
    orderDetails.fromJson(jsonDecode(response.data));

    print("---------------------------fetched order detail--------------------");
    print(orderdetailmodel.success);

    if (orderdetailmodel.orderDetail != null) {
      final order = orderdetailmodel.orderDetail!;

      // ✅ Customer
      if (order.customer != null) {
        dropdownCustomerList.value = [order.customer!.name ?? ""];
        dropdownCustomer.value = order.customer!.name ?? "";
      }

      // ✅ Products (unique by product id)
      final products = order.products!
          .map((p) => module(id: p.id ?? 0, name: p.name ?? ""))
          .where((p) => p.id != 0 && p.name.isNotEmpty)
          .toList();

      final uniqueProducts = {
        for (var p in products) p.id: p
      }.values.toList();

      dropdownProducts.value = uniqueProducts;

      if (dropdownProducts.isNotEmpty) {
        selectedProduct.value = dropdownProducts.first;
      }

      // ✅ Suppliers (unique by supplier id)
      final suppliers = order.products!
          .map((p) => p.supplierRelation?.supplier)
          .where((s) => s != null)
          .map((s) => module(id: s!.id ?? 0, name: s.name ?? ""))
          .where((s) => s.id != 0 && s.name.isNotEmpty)
          .toList();

      final uniqueSuppliers = {
        for (var s in suppliers) s.id: s
      }.values.toList();

      dropdownSuppliers.value = uniqueSuppliers;

      if (dropdownSuppliers.isNotEmpty) {
        selectedSupplier.value = dropdownSuppliers.first;
      }

      // ✅ Categories (unique by category id)
      final categories = order.products!
          .map((p) =>
          module(id: p.category?.id ?? 0, name: p.category?.name ?? ""))
          .where((c) => c.id != 0 && c.name.isNotEmpty)
          .toList();

      final uniqueCategories = {
        for (var c in categories) c.id: c
      }.values.toList();

      dropdownCategories.value = uniqueCategories;

      if (dropdownCategories.isNotEmpty) {
        selectedCategory.value = dropdownCategories.first;
      }
    }
  }

  //
  Future<void> saveAndSubmit() async {
    inward finalInward = inward(grnNo: grnNumber.value, orderNo: int.parse(orderNumber.value), supervisorNo: dropdownSupervisor.value?.id ?? 1, items: recordedEntries);
    var response = await connectHelper.storeData(data: finalInward);
    var decodedresponse = jsonDecode(response.data);
    if(decodedresponse["message"] == "Token expired"){
      await connectHelper.refreshToken();
      response = await connectHelper.storeData(data: finalInward);
    }
    bool res = response.hasError;
    print(!res);
    if(!res){
      generatePdf();
      recordInwardEntry();
      Get.back();
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

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void clearEntries() {
    recordedEntries.clear();
  }

  void calculateManualNet() {
    final gross = double.tryParse(manualGross.value) ?? 0.0;
    final tare = double.tryParse(manualTare.value) ?? 0.0;
    final net = gross - tare;

    manualNet.value = net.toStringAsFixed(2);
  }

  void startScan() {
    scanResults.clear();
    isScanning.value = true;

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      // Sort results: devices starting with "BT" go first
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
                final weight = _parseWeight(raw);
                if (weight != null) {
                  // 3. Keep manualGross in sync with Bluetooth gross
                  manualGross.value = weight.toStringAsFixed(2);

                  // 4. Recalculate Net immediately
                  calculateManualNet();
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
    } catch (e) {
      debugPrint('Error while disconnecting: $e');
    }

    // 3) clear local connection state so UI switches back to connect phase
    connectedDevice.value = null;
    receivedData.value = '';

    // 4) (optional) restart scanning so device list + Connect Device UI appears immediately
    //    you can remove this if you prefer the user to tap "Connect Device" manually.
    startScan();
  }

  void recordEntryManual() {
    final category = selectedCategory.value;
    final product = selectedProduct.value;
    final supplier = selectedSupplier.value;

    if (category == null || product == null || supplier == null) {
      Get.snackbar("Error", "Please select category, product and supplier");
      return;
    }

    if (isBluetoothMode.value) {
      final weight = _parseWeight(receivedData.value);
      if (weight == null) {
        Get.snackbar("Error", "Unable to parse weight",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final tare = 1.0;
      final net = weight - tare;

      _saveEntry(
        gross: weight,
        tare: tare,
        net: net,
        categoryId: category.id,
        productId: product.id,
        supplierId: supplier.id,
        category: category.name,
        productName: product.name,
        scrapGrade: dropdownGrade.value
      );
    } else
    {
      final gross = double.tryParse(manualGross.value) ?? 0.0;
      final tare = double.tryParse(manualTare.value) ?? 0.0;
      final net = gross - tare;

      _saveEntry(
        gross: gross,
        tare: tare,
        net: net,
        categoryId: category.id,
        productId: product.id,
        supplierId: supplier.id,
        category: category.name,
          productName: product.name,
          scrapGrade: dropdownGrade.value
      );
    }

  }


  void recordInwardEntry(){
    inwardCount++;
  }void recordJobWorkEntry(){
    jobWorkCount++;
  }void recordDispatchEntry(){
    dispatchCount++;
  }
  /// Save Item entry directly
  void _saveEntry({
    required double gross,
    required double tare,
    required double net,
    required String category,
    required String productName,
    required String scrapGrade,
    required int categoryId,
    required int productId,
    required int supplierId,
  }) {
    final newItem = Item(
      supplierId: supplierId,
      productId: productId,
      categoryId: categoryId,
      tareWeight: tare,
      grossWeight: gross,
      netWeight: net,
      category: category,
      prod_name: productName,
      scrap_grade: scrapGrade
    );

    recordedEntries.insert(0, newItem);
    print("-----------------------recorded entries----------------------");
    print(recordedEntries);
  }

  double? _parseWeight(String raw) {
    if (raw.trim().isEmpty) return null;
    final cleaned = raw.replaceAll(',', '.');
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(cleaned);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }
}
class module{
  int id;
  String name;
  module({required this.id,required this.name});
}
extension BluetoothControllerPdf on BluetoothController {
  /// Generate PDF from recorded entries and save with grnNumber
  Future<File> generatePdf() async {
    final pdf = pw.Document();

    // Add a page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Inward Report - GRN: ${grnNumber.value}',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // Table
          pw.Table.fromTextArray(
            headers: [
              'Category',
              'Product',
              'Supplier',
              'Scrap Grade',
              'Gross',
              'Tare',
              'Net',
            ],
            data: recordedEntries.map((item) {
              return [
                item.category,
                item.prod_name,
                item.supplierId.toString(),
                item.scrap_grade,
                item.grossWeight.toStringAsFixed(2),
                item.tareWeight.toStringAsFixed(2),
                item.netWeight.toStringAsFixed(2),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),
          pw.Text("Total Entries: ${recordedEntries.length}"),
        ],
      ),
    );

    // Save PDF to local directory
    final outputDir = Directory("/storage/emulated/0/Download");
    final file = File("${outputDir.path}/${grnNumber.value}.pdf");

    await file.writeAsBytes(await pdf.save());
    print("✅ PDF saved at: ${file.path}");
    return file;
  }
}
*/

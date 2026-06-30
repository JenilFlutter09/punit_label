import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/features/dispatch/models/customerModel.dart';

import '../../apis/connectHelper.dart';
import '../../constants/utility.dart';
import '../../widgets/pdfExcel.dart';
import '../dashboard/dashboardController.dart';
import 'models/dispatchBarcodes.dart';
import 'models/dispatchModel.dart';

class DispatchController extends GetxController {
  var initLoading = false.obs;
  var isPdfProcessing = false.obs;
  TextEditingController manualBarcode = TextEditingController();
  ConnectHelper connectHelper = ConnectHelper();
  Rxn<DispatchModel> dispatchModel = Rxn<DispatchModel>();
  Rxn<customerModel> dispatchCustomerModel = Rxn<customerModel>();
  RxList<Customer> customerList = <Customer>[].obs;
  var selectedCustomer = Rxn<Customer>();
  var selectedProduct = Rxn<Data>();
  final dashboardController = Get.find<DashboardController>();
  RxList<Dispatchbarcodes> barcodeList = <Dispatchbarcodes>[].obs;
  RxList<VerifiedBarcode> verifiedBarcodeList = <VerifiedBarcode>[].obs;
  var enableAddButton = Rx<bool>(false);
  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
  }

  void clearDispatchSession({bool clearSelectedProduct = true}) {
    barcodeList.clear();
    verifiedBarcodeList.clear();
    manualBarcode.clear();
    if (clearSelectedProduct) {
      selectedProduct.value = null;
    }
  }

  @override
  Future<void> onReady() async {
    // TODO: implement onReady
    super.onReady();
    // initLoading.value = true;
    await refresh();
    // initLoading.value = false;
  }

  Future<void> refresh() async {
    clearDispatchSession();
    await _fetchBatchlist();
    await _fetchCustomerlist();
  }

  @override
  void onClose() {
    manualBarcode.dispose();
    super.onClose();
  }

  void verifyAndAddBarcode(String scanned) {
    final code = scanned.trim().toLowerCase();
    if (code.isEmpty) return;

    Barcodes? foundBarcode;
    Data? parentProduct;
    for (final product in dispatchModel.value?.data ?? []) {
      Barcodes? barcode;
      try {
        barcode = product.barcodes?.firstWhere(
          (b) => (b.barCodeString ?? '').toLowerCase() == code,
        );
      } catch (_) {
        barcode = null;
      }

      if (barcode != null) {
        foundBarcode = barcode;
        parentProduct = product;
        print(foundBarcode.barCodeString);
        print(parentProduct?.variation?.length);
        selectedProduct.value = parentProduct;
        break;
      }
    }

    if (foundBarcode == null || parentProduct == null) {
      Utility.showToast(
        text: 'Unverified Barcode',
        toastColor: Colors.red,
        icon: Icons.cancel,
      );
      return;
    }

    /// Duplicate check (ID based)
    final alreadyAdded = verifiedBarcodeList.any(
      (v) => v.barcodeId == foundBarcode!.id,
    );

    if (alreadyAdded) {
      Utility.showToast(
        text: 'Entry Already Exist',
        toastColor: Colors.orange,
        icon: Icons.do_not_disturb_alt,
      );
      return;
    }

    /// Add to UI list
    barcodeList.insert(
      0,
      Dispatchbarcodes(
        id: foundBarcode.id,
        stockId: foundBarcode.stockId,
        barCodeString: foundBarcode.barCodeString,
        isTareWeight: foundBarcode.isTareWeight,
        tareWeight: foundBarcode.tareWeight,
        grossWeight: foundBarcode.grossWeight,
        netWeight: foundBarcode.netWeight,
        productName: parentProduct.productName,
        unitConversion: parentProduct.unitConversion,
        unit: parentProduct.unit,
        variation: List<Variation>.from(parentProduct.variation ?? []),
      ),
    );
    print("VARIATION COUNT = ${barcodeList.first.variation?.length}");

    /// Add to verified payload list
    verifiedBarcodeList.insert(
      0,
      VerifiedBarcode(
        stockId: foundBarcode.stockId,
        barcodeId: foundBarcode.id,
      ),
    );

    manualBarcode.clear();

    Utility.showToast(
      text: 'Entry Added',
      toastColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  Future<void> generatePdf({String? dispatchId, String? dispatchedAt}) async {
    final now = DateTime.now();

    final uniqueSuffix =
        "${DateFormat('ddMMyyyy_HHmmss').format(now)}_${now.microsecondsSinceEpoch}";

    final title = dispatchId?.trim().isNotEmpty == true
        ? dispatchId!.trim()
        : "Dispatch_$uniqueSuffix";
    final dispatchDate = _parseDispatchDate(dispatchedAt) ?? now;
    var companyData = dashboardController.companyDetails.value?.data;
    if (companyData == null) {
      await dashboardController.getCompanyDetails();
      companyData = dashboardController.companyDetails.value?.data;
    }
    final companyEmail = companyData?.email?.trim();
    final dispatchEmail = companyEmail?.isNotEmpty == true
        ? companyEmail
        : null;

    await ExportHelper.modern_flex_packing_list(
      title: title,
      metaData: {
        "Customer Name": selectedCustomer.value?.name ?? "Customer",
        "Customer Email": selectedCustomer.value?.email ?? "Customer",
        "Dispatch No": title,
        "Generated By": "https://pinnacle.punitinstrument.com",
        "Date": DateFormat('dd-MM-yyyy').format(dispatchDate),
      },
      email: dispatchEmail,
      companyName: companyData?.name?.trim() ?? '',
      companyAddress: companyData?.address?.trim() ?? '',
      companyPhone: companyData?.contactNo?.trim() ?? '',
      companyEmail: companyEmail ?? '',
      companyGst: companyData?.gstNo?.trim() ?? '',
      companyWebsite: companyData?.website?.trim() ?? '',
      items: barcodeList.toList(),
      onBeforeResultDialogShown: () {
        isPdfProcessing.value = false;
      },
    );

    Utility.showToast(text: 'Pdf Saved', toastColor: Colors.green);
  }

  DateTime? _parseDispatchDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(value.trim());
    } catch (_) {
      return DateTime.tryParse(value.trim());
    }
  }

  /// Custom Made For Specific Client
  Future<void> generatePdfForSpecificClient(BuildContext context) async {
    final now = DateTime.now();

    final uniqueSuffix =
        "${DateFormat('ddMMyyyy_HHmmss').format(now)}_${now.microsecondsSinceEpoch}";

    final title = "Dispatch_$uniqueSuffix";
    ExportHelper.exportHorizontalClientPDF(
      context: context,
      title: title,
      metaData: {
        "Customer Name": selectedCustomer.value?.name ?? "Customer",
        "Customer Email": selectedCustomer.value?.email ?? "Customer",
        "Generated By": "https://pinnacle.punitinstrument.com",
        "Date": DateFormat('dd-MM-yyyy').format(DateTime.now()),
      },
      items: barcodeList.toList(),
      email: dashboardController.companyDetails.value?.data?.email,
    );
  }

  Future<void> _fetchBatchlist() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getDispatchList(),
      isLoading: initLoading,
    );
    if (!response.hasError) {
      dispatchModel.value = DispatchModel.fromJson(jsonDecode(response.data));
      print(
        "---------------------------fetched Dispatch list--------------------",
      );
    } else if (response.hasError) {
      Utility.showApiErrorSnackbar(response);
    }
  }

  Future<void> _fetchCustomerlist() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getCustomerList(),
      isLoading: initLoading,
    );
    dispatchCustomerModel.value = customerModel.fromJson(
      jsonDecode(response.data),
    );
    print(
      "---------------------------fetched customer list--------------------",
    );

    customerList.value = dispatchCustomerModel.value?.data ?? [];

    if (customerList.isNotEmpty) {
      selectedCustomer.value = customerList.first;
    } else {
      selectedCustomer.value = null;
    }
  }

  Future<void> changeSelectedCustomerId(int id) async {
    // find the product by id
    var product = customerList.firstWhere(
      (p) => p.id == id,
      orElse: () => Customer(),
    );

    if (product.id == null) return;

    final previousCustomerId = selectedCustomer.value?.id;
    selectedCustomer.value = product;
    if (previousCustomerId != product.id) {
      clearDispatchSession();
    }
    //await _fetchBatchDetail();
  }

  Future<void> saveAndSubmitScannedBarcodes(BuildContext context) async {
    isPdfProcessing.value = true;
    try {
      var data = DispatchBarcode(
        data: verifiedBarcodeList,
        customerId: selectedCustomer.value?.id,
      );
      print('Body of Dispatch == ${jsonEncode(data)}');
      var response = await dashboardController.callApi(
        apiCall: () =>
            connectHelper.dispatchBarcodesVerify(dispatch_barcode: data),
        isLoading: initLoading,
      );
      if (!response.hasError) {
        final dispatchResponse = DispatchSubmitResponse.fromJson(
          jsonDecode(response.data),
        );
        if (dispatchResponse.status != true) {
          isPdfProcessing.value = false;
          Utility.showApiErrorSnackbar(response);
          return;
        }

        Get.snackbar(
          "Successful",
          dispatchResponse.message ?? "Products Dispatched Successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          animationDuration: Duration(seconds: 3),
        );
        await generatePdf(
          dispatchId: dispatchResponse.data?.dispatchId,
          dispatchedAt: dispatchResponse.data?.dispatchedAt,
        );
        // await generatePdfForSpecificClient(context);
        clearDispatchSession();
        //Get.back();
        await _fetchBatchlist();
      } else if (response.hasError) {
        isPdfProcessing.value = false;
        Utility.showApiErrorSnackbar(response);
      }
    } catch (_) {
      isPdfProcessing.value = false;
      rethrow;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:punit_label/features/inward/batchWise/models/batchInwardModel.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/nonBatchInwardModel.dart';
import 'package:punit_label/features/label_template/models/label_template_models.dart';
import 'package:punit_label/features/tare/tareModel.dart';

import '../features/dispatch/models/dispatchBarcodes.dart';
import '/apis/responseModel.dart';
import '/apis/sharedPreference.dart';
import '/constants/enums.dart';
import '/constants/styles.dart';
import 'apiWrapper.dart';

class ConnectHelper {
  ConnectHelper();
  final apiWrapper = ApiWrapper();

  String get baseUrl => apiWrapper.baseUrl;

  bool get supportsCustomLabelTemplates =>
      apiWrapper.supportsCustomLabelTemplates;
  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Login Api
  ///
  // Future<ResponseModel> login({
  //   required String companyCode,
  //   required String email,
  //   required String password,
  // }) async {
  //   final payLoad = {
  //     "email": email,
  //     "password": password,
  //     "company_code": companyCode,
  //   };
  //   return await apiWrapper.makeRequest(
  //     'login',
  //     Request.post,
  //     payLoad,
  //     true,
  //     {},
  //   );
  // }
  Future<ResponseModel> login({
    required String companyCode,
    required String email,
    required String password,
  }) {
    final payload = {
      "email": email,
      "password": password,
      "company_code": companyCode,
    };

    return apiWrapper.makeRequest(
      url: 'login',
      request: Request.post,
      data: payload,
      headers: {},
    );
  }

  /// Tare Product Store
  ///
  // Future<ResponseModel> tareStore({required TareModel tareModel}) async {
  //   final payLoad = jsonEncode(tareModel);
  //   String? token = await TokenStorage.getToken();
  //   return await apiWrapper.makeRequest(
  //     'tare-product/store',
  //     Request.post,
  //     payLoad,
  //     true,
  //     {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
  //   );
  // }

  Future<ResponseModel> tareStore({required TareModel tareModel}) async {
    return apiWrapper.makeRequest(
      url: 'tare-product/store',
      request: Request.post,
      data: jsonEncode(tareModel),
      headers: await _authHeaders(),
    );
  }

  /// Batch Product Store
  ///
  Future<ResponseModel> batchProductStore({
    required batchInwardModel batch_inward_model,
  }) async {
    return apiWrapper.makeRequest(
      url: 'batchinward',
      request: Request.post,
      data: jsonEncode(batch_inward_model),
      headers: await _authHeaders(),
    );
  }

  /// Barcode Verify
  ///
  Future<ResponseModel> dispatchBarcodesVerify({
    required DispatchBarcode dispatch_barcode,
  }) async {
    return apiWrapper.makeRequest(
      url: 'scan/barcode',
      request: Request.post,
      data: jsonEncode(dispatch_barcode),
      headers: await _authHeaders(),
    );
  }

  /// Batch Product Store
  ///
  Future<ResponseModel> nonBatchProductStore({
    required NonBatchInwardModel non_batch_inward_model,
  }) async {
    return apiWrapper.makeRequest(
      url: 'nonbatch/inward',
      request: Request.post,
      data: jsonEncode(non_batch_inward_model),
      headers: await _authHeaders(),
    );
  }

  /// Refresh token
  ///
  Future<ResponseModel> refreshToken() async {
    return apiWrapper.makeRequest(
      url: 'refresh',
      request: Request.post,
      data: null,
      headers: await _authHeaders(),
    );
  }

  /// Company Details
  ///
  Future<ResponseModel> getCompanyDetails() async {
    return apiWrapper.makeRequest(
      url: 'company-details',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  /// Dashboard Details
  ///
  Future<ResponseModel> getDashboardDetails() async {
    return apiWrapper.makeRequest(
      url: 'dashboard',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getBatchList() async {
    return apiWrapper.makeRequest(
      url: 'batches',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getDispatchList() async {
    return apiWrapper.makeRequest(
      url: 'product/stocks/all',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getCustomerList() async {
    return apiWrapper.makeRequest(
      url: 'customers',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getNonBatchList() async {
    return apiWrapper.makeRequest(
      url: 'transactions-list',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getTareList() async {
    return apiWrapper.makeRequest(
      url: 'tare-products',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getBatchDetails(String batchId) async {
    return apiWrapper.makeRequest(
      url: 'batch/$batchId',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getDispatchBarcodes(String batchId) async {
    return apiWrapper.makeRequest(
      url: 'product/stocks/$batchId',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getProductList() async {
    return apiWrapper.makeRequest(
      url: 'products',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getAttributeList() async {
    return apiWrapper.makeRequest(
      url: 'attributes',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<ResponseModel> getNonBatchDetails(String TransactionId) async {
    return apiWrapper.makeRequest(
      url: 'transaction/$TransactionId',
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );
  }

  Future<LabelTemplateOptionsResponse> getLabelTemplateOptions({
    String? labelSize,
    int? productId,
    int? batchProductId,
  }) async {
    final queryParameters = <String, String>{};
    if (labelSize != null && labelSize.trim().isNotEmpty) {
      queryParameters['label_size'] = labelSize.trim();
    }
    if (productId != null) {
      queryParameters['product_id'] = productId.toString();
    }
    if (batchProductId != null) {
      queryParameters['batch_product_id'] = batchProductId.toString();
    }

    final uri = Uri(
      path: 'label-template/options',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();

    final response = await apiWrapper.makeRequest(
      url: uri,
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );

    if (response.hasError) {
      throw response;
    }

    return LabelTemplateOptionsResponse.fromJson(
      jsonDecode(response.data) as Map<String, dynamic>,
    );
  }

  Future<RuntimeLabelTemplateResponse> getRuntimeLabelTemplate({
    required String labelSize,
    int? productId,
    int? batchProductId,
  }) async {
    final queryParameters = <String, String>{'label_size': labelSize.trim()};
    if (productId != null) {
      queryParameters['product_id'] = productId.toString();
    }
    if (batchProductId != null) {
      queryParameters['batch_product_id'] = batchProductId.toString();
    }

    final uri = Uri(
      path: 'label-template/runtime',
      queryParameters: queryParameters,
    ).toString();

    final response = await apiWrapper.makeRequest(
      url: uri,
      request: Request.get,
      data: null,
      headers: await _authHeaders(),
    );

    if (response.hasError) {
      throw response;
    }

    return RuntimeLabelTemplateResponse.fromJson(
      jsonDecode(response.data) as Map<String, dynamic>,
    );
  }

  Future<bool> showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismiss on tap outside
          builder: (context) => AlertDialog(
            title: Text('Exit App', style: Styles.primaryBold16),
            content: Text(
              'Are you sure you want to exit?',
              style: Styles.primary14,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No', style: Styles.primaryBold14),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes', style: Styles.primaryBold14),
              ),
            ],
          ),
        ) ??
        false; // Default to false if dialog is dismissed unexpectedly
  }
}

class refreshModel {
  bool? success;
  String? accessToken;
  String? tokenType;

  refreshModel({this.success, this.accessToken, this.tokenType});

  refreshModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    accessToken = json['access_token'];
    tokenType = json['token_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['access_token'] = this.accessToken;
    data['token_type'] = this.tokenType;
    return data;
  }
}

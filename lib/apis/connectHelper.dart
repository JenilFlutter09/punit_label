
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/inward/batchWise/models/batchInwardModel.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/nonBatchInwardModel.dart';
import 'package:punit_label/features/tare/tareModel.dart';
import 'package:punit_label/navigation/routesManagement.dart';

import '../features/dispatch/models/dispatchBarcodes.dart';
import '/apis/responseModel.dart';
import '/apis/sharedPreference.dart';
import '/constants/enums.dart';
import '/constants/styles.dart';
import 'apiWrapper.dart';


class ConnectHelper {
  ConnectHelper();
  final apiWrapper = ApiWrapper();

  /// Login Api
  ///
  Future<ResponseModel> login({
    required String companyCode,
    required String email,
    required String password,
  }) async {
    final payLoad = {
      "email": email,
      "password": password,
      "company_code": companyCode,
    };
    return await apiWrapper.makeRequest(
      'login',
      Request.post,
      payLoad,
      true,
      {},
    );
  }

  /// Tare Product Store
  ///
  Future<ResponseModel> tareStore({required TareModel tareModel}) async {
    final payLoad = jsonEncode(tareModel);
    String? token = await TokenStorage.getToken();
    return await apiWrapper.makeRequest(
      'tare-product/store',
      Request.post,
      payLoad,
      true,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  /// Batch Product Store
  ///
  Future<ResponseModel> batchProductStore({
    required batchInwardModel batch_inward_model,
  }) async {
    final payLoad = jsonEncode(batch_inward_model);
    String? token = await TokenStorage.getToken();
    return await apiWrapper.makeRequest(
      'batchinward',
      Request.post,
      payLoad,
      true,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );

  }

  /// Barcode Verify
  ///
  Future<ResponseModel> dispatchBarcodesVerify({
    required DispatchBarcode dispatch_barcode,
  }) async {
    final payLoad = jsonEncode(dispatch_barcode);
    String? token = await TokenStorage.getToken();
    return await apiWrapper.makeRequest(
      'scan/barcode',
      Request.post,
      payLoad,
      true,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  /// Batch Product Store
  ///
  Future<ResponseModel> nonBatchProductStore({
    required NonBatchInwardModel non_batch_inward_model,
  }) async {
    final payLoad = jsonEncode(non_batch_inward_model);
    String? token = await TokenStorage.getToken();
    return await apiWrapper.makeRequest(
      'nonbatch/inward',
      Request.post,
      payLoad,
      true,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  /// Refresh token
  ///
  Future<ResponseModel> refreshToken() async {
    String? token = await TokenStorage.getToken();
    final payLoad = "";
    return await apiWrapper.makeRequest(
      'refresh',
      Request.post,
      payLoad,
      true,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  /// Company Details
  ///
  Future<ResponseModel> getCompanyDetails() async {
    String? token = await TokenStorage.getToken();
    final payLoad = "";
    return await apiWrapper.makeRequest(
      'company-details',
      Request.get,
      payLoad,
      true,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  /// Dashboard Details
  ///
  Future<ResponseModel> getDashboardDetails() async {
    String? token = await TokenStorage.getToken();
    final payLoad = "";
    return await apiWrapper.makeRequest(
      'dashboard',
      Request.get,
      payLoad,
      true,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<ResponseModel> getBatchList() async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest('batches', Request.get, body, false, {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
  }

  Future<ResponseModel> getDispatchList() async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest(
      'product/stocks/all',
      Request.get,
      body,
      false,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<ResponseModel> getCustomerList() async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest('customers', Request.get, body, false, {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
  }

  Future<ResponseModel> getNonBatchList() async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest(
      'transactions-list',
      Request.get,
      body,
      false,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<ResponseModel> getTareList() async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest(
      'tare-products',
      Request.get,
      body,
      false,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<ResponseModel> getBatchDetails(String batchId) async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest(
      'batch/$batchId',
      Request.get,
      body,
      false,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<ResponseModel> getDispatchBarcodes(String batchId) async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest(
      'product/stocks/$batchId',
      Request.get,
      body,
      false,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<ResponseModel> getProductList() async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest('products', Request.get, body, false, {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
  }

  Future<ResponseModel> getAttributeList() async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest(
      'attributes',
      Request.get,
      body,
      false,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  Future<ResponseModel> getNonBatchDetails(String TransactionId) async {
    String? token = await TokenStorage.getToken();
    print('Token: $token');
    final payLoad = '';
    final body = jsonEncode(payLoad);
    print(body);
    return await apiWrapper.makeRequest(
      'transaction/$TransactionId',
      Request.get,
      body,
      false,
      {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
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

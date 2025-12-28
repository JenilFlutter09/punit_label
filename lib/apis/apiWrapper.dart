
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '/apis/responseModel.dart';

import '../constants/enums.dart';
import '../constants/utility.dart';



class ApiWrapper {
  /// Base Url for testing purpose
 //  final String _baseUrl = "https://labels.clotheeo.com/api/";
  /// Live Url for Client purpose
  final String _baseUrl = "https://pinnacle.punitinstrument.com/api/";

  Future<ResponseModel> makeRequest(String url,
      Request request,
      dynamic data,
      bool isLoading,
      Map<String, String> headers,) async {
    /* if (!await Utility.isNetworkAvailable()) {
      Utility.showInternetDialog(
        "No internet, please enable mobile data or Wi-Fi in your phone settings and try again.",
      );
      return ResponseModel(
        data:
            '{"message":"No internet, please enable mobile data or Wi-Fi in your phone settings and try again"}',
        hasError: true,
      );
    }
*/
    if (Get.isDialogOpen == true) Get.back<void>();
    final uri = request == Request.awsUpload ? url : _baseUrl + url;

    try {
      if (isLoading) Utility.showLoader();

      http.Response response;

      switch (request) {
        case Request.get:
          response = await http
              .get(Uri.parse(uri), headers: headers)
              .timeout(const Duration(seconds: 120));
          break;

        case Request.post:
          response = await http
              .post(Uri.parse(uri), body: data, headers: headers)
              .timeout(const Duration(seconds: 120));
          break;

        case Request.put:
          response = await http
              .put(Uri.parse(uri), body: data, headers: headers)
              .timeout(const Duration(seconds: 120));
          break;

        case Request.patch:
          response = await http
              .patch(Uri.parse(uri), body: jsonEncode(data), headers: headers)
              .timeout(const Duration(seconds: 120));
          break;

        case Request.delete:
          response = await http
              .delete(Uri.parse(uri), body: jsonEncode(data), headers: headers)
              .timeout(const Duration(seconds: 120));
          break;

        case Request.awsUpload:
          response = await http
              .put(Uri.parse(uri), body: data, headers: headers)
              .timeout(const Duration(seconds: 120));
          break;
      }

      if (isLoading) {
        Utility.closeDialog();
      }
      _logRequest(uri, headers, response);
      return returnResponse(response);
    } on TimeoutException {
      if (isLoading) Utility.closeDialog();
      return _handleTimeout();
    } catch (e) {
      if (isLoading) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Unexpected error: $e"}',
        hasError: true,
      );
    }
  }

  /// Handle timeout errors consistently
  ResponseModel _handleTimeout() {
    return ResponseModel(
      data: '{"message":"Request timed out"}',
      hasError: true,
    );
  }

  /// Logs request and response for debugging
  void _logRequest(String uri,
      Map<String, String> headers,
      http.Response response,) {
    log('''
== API CALL ==
URL       : $uri
Headers   : $headers
Status    : ${response.statusCode}
Response  : ${response.body}
''');
    Utility.printILog(uri);
  }

  /// Centralized response handler based on status codes
  Future<ResponseModel> returnResponse(http.Response response) async {
    final statusCode = response.statusCode;
    final body = response.body;

    switch (statusCode) {
      case 200:
      case 201:
      case 204:
        return ResponseModel(
          data: body,
          hasError: false,
          errorCode: statusCode,
        );

      case 400:
        return ResponseModel(
          data: body,
          hasError: true,
          errorCode: statusCode,
        );

      case 401:
        return ResponseModel(
          data: '{"message":"Token expired"}',
          hasError: true,
          errorCode: statusCode,
        );


      case 403:
        return ResponseModel(
          data: '{"message":"Forbidden"}',
          hasError: true,
          errorCode: statusCode,
        );

      case 404:
        return ResponseModel(
          data: '{"message":"Not found"}',
          hasError: true,
          errorCode: statusCode,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ResponseModel(
          data: '{"message":"Server error, please try again later"}',
          hasError: true,
          errorCode: statusCode,
        );

      default:
        return ResponseModel(
          data: '{"message":"Unexpected error occurred"}',
          hasError: true,
          errorCode: statusCode,
        );
    }
  }
}
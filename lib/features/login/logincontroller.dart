import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../apis/responseModel.dart';
import '../../constants/utility.dart';
import '/apis/connectHelper.dart';
import '/apis/sharedPreference.dart';
import '/features/login/loginmodel.dart';
import '/navigation/routesManagement.dart';

typedef ApiCall = Future<ResponseModel> Function();

class LoginController extends GetxController {
  final ConnectHelper connectHelper = ConnectHelper();

  final email = ''.obs;
  final password = ''.obs;
  final companyCode = ''.obs;

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  // ---------------- GENERIC API WRAPPER ----------------
  Future<ResponseModel> callApi({required ApiCall apiCall}) async {
    late ResponseModel response;

    try {
      response = await apiCall();

      if (response.hasError) {
        if (response.errorCode == 401) {
          Utility.showCustomApiErrorSnackBar(
            title: 'Login Failed',
            body: 'Re-Check Credentials',
          );
        } else {
          Utility.showApiErrorSnackbar(response);
        }
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint("❌ API Wrapper Error: $e");
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        "Error",
        "Something went wrong",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );

      return ResponseModel(hasError: true, data: e.toString());
    }
  }

  // ---------------- LOGIN ----------------
  Future<void> login() async {
    // ✅ VALIDATION (FIXED Rx BUGS)
    if (email.value.isEmpty) {
      _showError("Please enter email");
      return;
    }

    if (password.value.isEmpty) {
      _showError("Please enter password");
      return;
    }

    if (companyCode.value.isEmpty) {
      _showError("Please enter Company Code");
      return;
    }

    isLoading.value = true;

    try {
      final response = await callApi(
        apiCall: () => connectHelper.login(
          email: email.value,
          password: password.value,
          companyCode: companyCode.value,
        ),
      );

      if (response.hasError) {
        _showError("Login failed");
        return;
      }

      final loginmodel = loginModel.fromJson(jsonDecode(response.data));

      await TokenStorage.saveToken(loginmodel.data?.accessToken ?? '');

      await TokenStorage.saveUser(
        loginmodel.data?.userProfile ?? UserProfile(),
      );

      RouteManagement.goToDashboardScreen();
    } catch (e, stackTrace) {
      debugPrint("❌ Login Error: $e");
      debugPrintStack(stackTrace: stackTrace);

      _showError("Something went wrong during login");
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- HELPER ----------------
  void _showError(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}

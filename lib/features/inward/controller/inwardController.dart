import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/inward/batchWise/models/batchList.dart';

import '../../../apis/connectHelper.dart';
import '../../../constants/utility.dart';
import '../nonBatchWise/models/nonBatchList.dart';

class InwardController extends GetxController {
  var initLoading = false.obs;
  ConnectHelper connectHelper = ConnectHelper();
  Rxn<batchListModel> batchModel = Rxn<batchListModel>();
  RxList<batch> batchList = RxList<batch>();
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final dashboardController = Get.find<DashboardController>();
  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    // initLoading.value = true;
    // await _fetchBatchlist();
    // initLoading.value = false;
  }

  @override
  Future<void> onReady() async {
    // TODO: implement onReady
    super.onReady();
    await _fetchBatchlist();
  }

  Future<void> refreshList() async {
    await _fetchBatchlist();
  }

  List<batch> get filteredBatchList {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return batchList;

    return batchList.where((item) {
      final batchName = item.batchName?.toLowerCase() ?? '';
      return batchName.contains(query);
    }).toList();
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  /// Fetch Order List
  Future<void> _fetchBatchlist() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getBatchList(),
      isLoading: initLoading,
    );
    if (!response.hasError) {
      batchModel.value = batchListModel.fromJson(jsonDecode(response.data));
      batchList.value = batchModel.value?.data ?? [];
      print(
        "---------------------------fetched batch list--------------------",
      );
      print(batchModel.value?.status);
    } else if (response.hasError) {
      Utility.showApiErrorSnackbar(response);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class NonInwardController extends GetxController {
  var initLoading = false.obs;
  ConnectHelper connectHelper = ConnectHelper();
  Rxn<NonBatchListModel> batchListModel = Rxn<NonBatchListModel>();
  RxList<Entity> batchList = RxList<Entity>();
  Rxn<Entity> selectedTransaction = Rxn<Entity>();
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final dashboardController = Get.find<DashboardController>();
  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    // initLoading.value = true;
    // await fetchNonBatchlist();
    // initLoading.value = false;
  }

  @override
  Future<void> onReady() async {
    // TODO: implement onReady
    super.onReady();

    await fetchNonBatchlist();
  }

  Future<void> refreshList() async {
    await fetchNonBatchlist();
  }

  List<Entity> get filteredBatchList {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return batchList;

    return batchList.where((item) {
      final name = item.name?.toLowerCase() ?? '';
      return name.contains(query);
    }).toList();
  }

  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  /// Fetch Order List
  Future<void> fetchNonBatchlist() async {
    var response = await dashboardController.callApi(
      apiCall: () => connectHelper.getNonBatchList(),
      isLoading: initLoading,
    );
    if (!response.hasError) {
      batchListModel.value = NonBatchListModel.fromJson(
        jsonDecode(response.data),
      );
      batchList.value = batchListModel.value?.data ?? [];
      print(
        "---------------------------fetched Non batch list--------------------",
      );
      print(batchListModel.value?.status);
    } else if (response.hasError) {
      Utility.showApiErrorSnackbar(response);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

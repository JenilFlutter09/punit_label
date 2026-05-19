import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/constants/sizes.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import '../../../constants/utility.dart';
import '../../../widgets/actionButtons.dart';
import 'bluetoothWeightSection.dart';
import '../../../widgets/customDrawer.dart';
import '../../../widgets/miscellenous.dart';
import '../../../widgets/searchableDropdown.dart';

import 'batchInwardController.dart';

class BatchInwardScreen extends StatelessWidget {
  BatchInwardScreen({super.key, required this.selectedBatchId}) {
    Get.put(BatchInwardController(selectedBatchId));
  }

  final String selectedBatchId;
  final dashboardController = Get.find<DashboardController>();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 600;
    final controller = Get.find<BatchInwardController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Batch Inward',
        showScale: true,
        showPrinter: true,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: Obx(() {
        if (controller.initLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Utility.styledInputSerialNumberField(
                label: 'Serial Number',
                icon: Icons.numbers,
                keyboard: TextInputType.number,
                isTablet: isTablet,
                controller: controller.serialNumberTextController,
                onChanged: controller.validateSerial,
                suffix: Obx(
                  () => Icon(
                    controller.isSerialVerified.value
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: controller.isSerialVerified.value
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
              Dimens.boxHeight8,
              Card(
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 18 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTitle(
                        title: "Select Product",
                        titleAlign: TextAlign.left,
                      ),
                      SizedBox(height: 12),
                      Utility.styledDropdown(
                        child: SearchableMapDropdown(
                          label: "Select Product",
                          items: controller.dropdownProducts,
                          selectedValue: controller.selectedModuleProduct,
                          onItemSelected: (val) =>
                              controller.changeSelectedProductId(val.id),
                        ),
                      ),
                      SizedBox(height: 12),
                      Obx(() {
                        if (dashboardController.labelFormats.isEmpty) {
                          return SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "LABEL FORMAT",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SearchableStringDropdown(
                              label: "Select Label Format",
                              items: dashboardController.labelFormats
                                  .map((e) => e.nameOfLabel)
                                  .toList(),
                              selectedValue: controller.selectedLabelFormat,
                              onItemSelected: (selectedName) {
                                controller.selectedLabelFormat.value =
                                    selectedName;
                                controller.selectedLabelFormatObj.value =
                                    dashboardController.labelFormats.firstWhere(
                                      (e) => e.nameOfLabel == selectedName,
                                    );
                              },
                            ),
                          ],
                        );
                      }),
                      Obx(() {
                        final selected = controller.selectedModuleProduct.value;
                        if (selected == null) return SizedBox();

                        // Find the full product model
                        final product = controller
                            .batchModel
                            .value
                            ?.data
                            ?.products
                            ?.firstWhere(
                              (p) => p.batchProductId == selected.id,
                            );

                        if (product == null) return SizedBox();
                        if (product.combinations?.isEmpty == true)
                          return SizedBox.shrink();
                        return ProductInfoCard(
                          productName: product.productName ?? '',
                          combinations: product.combinations ?? [],
                          isTablet: isTablet,
                          isClickable: false,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              BluetoothWeightSection(
                isTablet: isTablet,
                dashboardController: dashboardController,
                controller: controller, // your screen controller
              ),
              SizedBox(height: isTablet ? 26 : 20),

              InwardActionBar(
                controller: controller,
                isTablet: isTablet,
                context: context,
              ),

              SizedBox(height: isTablet ? 28 : 20),

              Text(
                "Inward Logs",
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 12),

              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.productList.length,
                  itemBuilder: (context, index) {
                    final data = controller.productList[index];
                    final itemKey = ValueKey(data); // Important for Dismissible

                    return Dismissible(
                      key: itemKey,
                      direction:
                          DismissDirection.endToStart, // Swipe right → left
                      background: _buildDismissBackground(),
                      confirmDismiss: (direction) async {
                        // Show professional confirmation dialog
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: const [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 12),
                                Text("Delete Entry?"),
                              ],
                            ),
                            content: Text(
                              "Are you sure you want to remove \"${data.batchProductName}\" from the list?\nThis cannot be undone.",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );

                        return confirm == true;
                      },
                      onDismissed: (direction) {
                        // Actually remove from list
                        controller.productList.removeAt(index);

                        // Show undo snackbar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "\"${data.batchProductName}\" removed",
                            ),
                            backgroundColor: Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            action: SnackBarAction(
                              label: "UNDO",
                              textColor: Colors.white,
                              onPressed: () {
                                // Re-insert at original position
                                controller.productList.insert(index, data);
                              },
                            ),
                          ),
                        );
                      },
                      child: InwardListItem(product: data, isTablet: isTablet),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Container(
        margin: Dimens.edgeInsets0_0_05_8,
        child: FloatingActionButton.extended(
          onPressed: () async => await controller.addToList(),
          label: Text('Add Entry', style: TextStyle(color: Colors.white)),
          backgroundColor: ColorsValue.primaryColor,
          icon: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_forever, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            "Delete",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

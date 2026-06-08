import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/inward/batchWise/models/batchDetails.dart';
import 'package:punit_label/widgets/actionButtons.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import 'package:punit_label/widgets/customDrawer.dart';
import 'package:punit_label/widgets/miscellenous.dart';
import 'package:punit_label/widgets/searchableDropdown.dart';

import '../../../constants/utility.dart';
import 'batchInwardController.dart';
import 'bluetoothWeightSection.dart';

class BatchInwardScreen extends StatelessWidget {
  BatchInwardScreen({super.key, required this.selectedBatchId}) {
    Get.put(BatchInwardController(selectedBatchId));
  }

  final String selectedBatchId;
  final dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;
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
          return const Center(child: CircularProgressIndicator());
        }

        return AdaptiveWorkflowShell(
          title: 'Batch Inward',
          subtitle:
              'Capture serial, product, label format, and weight on the left while reviewing the running inward session on the right.',
          headerBadge: 'Batch ${controller.batchId}',
          compactContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BatchInwardFormPanel(
                controller: controller,
                dashboardController: dashboardController,
                layout: layout,
              ),
              SizedBox(height: layout.sectionSpacing),
              _BatchActionSection(
                controller: controller,
                layout: layout,
                showInlineAddButton: false,
              ),
              SizedBox(height: layout.sectionSpacing),
              _BatchLogsPanel(controller: controller, layout: layout),
            ],
          ),
          leftPanel: _BatchInwardFormPanel(
            controller: controller,
            dashboardController: dashboardController,
            layout: layout,
          ),
          rightPanel: _BatchLogsPanel(controller: controller, layout: layout),
          primaryAction: layout.isExpandedTablet
              ? _BatchActionSection(
                  controller: controller,
                  layout: layout,
                  showInlineAddButton: true,
                )
              : null,
        );
      }),
      floatingActionButton: layout.isExpandedTablet
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                onPressed: () async => controller.addToList(),
                label: const Text(
                  'Add Entry',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: ColorsValue.primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ),
    );
  }
}

class _BatchInwardFormPanel extends StatelessWidget {
  const _BatchInwardFormPanel({
    required this.controller,
    required this.dashboardController,
    required this.layout,
  });

  final BatchInwardController controller;
  final DashboardController dashboardController;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdaptiveSectionCard(
          title: 'Product Setup',
          subtitle:
              'Verify the serial number, then choose the product and label format before capturing weight.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Utility.styledInputSerialNumberField(
                label: 'Serial Number',
                icon: Icons.numbers,
                keyboard: TextInputType.number,
                isTablet: layout.isTablet,
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
              const SizedBox(height: 12),
              Utility.styledDropdown(
                child: SearchableMapDropdown(
                  label: 'Select Product',
                  items: controller.dropdownProducts,
                  selectedValue: controller.selectedModuleProduct,
                  onItemSelected: (val) {
                    controller.changeSelectedProductId(val.id);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (dashboardController.labelFormats.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LABEL FORMAT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SearchableStringDropdown(
                      label: 'Select Label Format',
                      items: dashboardController.labelFormats
                          .map((e) => e.nameOfLabel)
                          .toList(),
                      selectedValue: controller.selectedLabelFormat,
                      onItemSelected: (selectedName) {
                        controller.selectedLabelFormat.value = selectedName;
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
                if (selected == null) return const SizedBox.shrink();

                final product = controller.batchModel.value?.data?.products
                    ?.firstWhere(
                      (p) => p.batchProductId == selected.id,
                      orElse: () => Products(),
                    );

                if (product == null ||
                    product.batchProductId == null ||
                    product.combinations?.isEmpty == true) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ProductInfoCard(
                    productName: product.productName ?? '',
                    combinations: product.combinations ?? [],
                    isTablet: layout.isTablet,
                    isClickable: false,
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: layout.sectionSpacing),
        AdaptiveSectionCard(
          title: 'Weight Capture',
          subtitle:
              'Use the live scale or manual controls below to build the current inward session.',
          child: BluetoothWeightSection(
            isTablet: layout.isTablet,
            dashboardController: dashboardController,
            controller: controller,
          ),
        ),
      ],
    );
  }
}

class _BatchActionSection extends StatelessWidget {
  const _BatchActionSection({
    required this.controller,
    required this.layout,
    required this.showInlineAddButton,
  });

  final BatchInwardController controller;
  final AppLayoutSpec layout;
  final bool showInlineAddButton;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Session Actions',
      subtitle:
          'Keep the auto-weighing controls visible on tablets while giving operators a clear place to add entries.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showInlineAddButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async => controller.addToList(),
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
              ),
            ),
          if (showInlineAddButton) SizedBox(height: layout.sectionSpacing),
          Center(
            child: InwardActionBar(
              controller: controller,
              isTablet: layout.isTablet,
              context: context,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchLogsPanel extends StatelessWidget {
  const _BatchLogsPanel({required this.controller, required this.layout});

  final BatchInwardController controller;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Inward Logs',
      subtitle:
          'Review, remove, or undo batch entries in the active inward session.',
      child: Obx(() {
        if (controller.productList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'No inward entries added yet.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.productList.length,
          itemBuilder: (context, index) {
            final data = controller.productList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey(data),
                direction: DismissDirection.endToStart,
                background: _buildDismissBackground(),
                confirmDismiss: (_) => _confirmDelete(context, data),
                onDismissed: (_) {
                  controller.productList.removeAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${data.batchProductName}" removed'),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: Colors.white,
                        onPressed: () {
                          controller.productList.insert(index, data);
                        },
                      ),
                    ),
                  );
                },
                child: InwardListItem(product: data, isTablet: layout.isTablet),
              ),
            );
          },
        );
      }),
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
            'Delete',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, dynamic data) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Delete Entry?'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${data.batchProductName}" from the list?\nThis cannot be undone.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

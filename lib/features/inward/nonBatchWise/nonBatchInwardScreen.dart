import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/nonBatchInwardModel.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchController.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchProductCard.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchWeightSection.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import 'package:punit_label/widgets/customDrawer.dart';
import 'package:punit_label/widgets/searchableDropdown.dart';

import '../../../constants/utility.dart';

class NonBatchInwardScreen extends StatelessWidget {
  NonBatchInwardScreen({super.key});

  final controller = Get.put(NonBatchInwardController());
  final dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Non Batch Inward',
        showScale: true,
        showPrinter: true,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: Obx(() {
        if (controller.initLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Fetching Data...'),
              ],
            ),
          );
        }

        return AdaptiveWorkflowShell(
          title: 'Non Batch Inward',
          subtitle:
              'Configure the transaction, attributes, and weight on the left, then review the running session log on the right.',
          headerBadge:
              controller.nonInwardController.selectedTransaction.value == null
              ? 'New Transaction'
              : 'Resume Mode',
          compactContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NonBatchFormPanel(
                controller: controller,
                dashboardController: dashboardController,
                layout: layout,
              ),
              SizedBox(height: layout.sectionSpacing),
              _NonBatchActionSection(
                controller: controller,
                layout: layout,
                showInlineAddButton: false,
              ),
              SizedBox(height: layout.sectionSpacing),
              _NonBatchLogsPanel(controller: controller, layout: layout),
            ],
          ),
          leftPanel: _NonBatchFormPanel(
            controller: controller,
            dashboardController: dashboardController,
            layout: layout,
          ),
          rightPanel: Column(
            children: [
              _SelectedProductSummary(controller: controller, layout: layout),
              SizedBox(height: layout.sectionSpacing),
              _NonBatchLogsPanel(controller: controller, layout: layout),
            ],
          ),
          primaryAction: layout.isExpandedTablet
              ? _NonBatchActionSection(
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
                icon: const Icon(Icons.add, color: Colors.white),
                backgroundColor: ColorsValue.primaryColor,
              ),
            ),
    );
  }
}

class _NonBatchFormPanel extends StatelessWidget {
  const _NonBatchFormPanel({
    required this.controller,
    required this.dashboardController,
    required this.layout,
  });

  final NonBatchInwardController controller;
  final DashboardController dashboardController;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdaptiveSectionCard(
          title: 'Transaction Setup',
          subtitle:
              'Verify the serial, name the transaction, select the product, and configure attributes for this entry.',
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
              Utility.styledInputField(
                label: 'Transaction Name',
                icon: Icons.label_outlined,
                keyboard: TextInputType.text,
                isTablet: layout.isTablet,
                controller: controller.transactionName,
              ),
              const SizedBox(height: 12),
              Utility.styledDropdown(
                child: SearchableMapDropdown(
                  label: 'Select Product',
                  items: controller.dropdownProducts,
                  selectedValue: controller.selectedProduct,
                  onItemSelected: (val) =>
                      controller.changeSelectedProductId(val.id),
                ),
              ),
              const SizedBox(height: 12),
              AdaptiveSectionCard(
                title: 'Product Attributes',
                subtitle:
                    'Select the label format and only enable the attributes allowed for that label.',
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: layout.cardPadding,
                  ),
                  initiallyExpanded: layout.isExpandedTablet,
                  title: const Text('Configure Attributes'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Obx(() {
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
                              items: controller.dashboardController.labelFormats
                                  .map((e) => e.nameOfLabel)
                                  .toList(),
                              selectedValue: controller.selectedLabelFormat,
                              onItemSelected: (selectedName) {
                                controller.selectedLabelFormat.value =
                                    selectedName;
                                controller.selectedLabelFormatObj.value =
                                    controller.dashboardController.labelFormats
                                        .firstWhere(
                                          (e) => e.nameOfLabel == selectedName,
                                        );
                                controller.selectedAttributesCount.value = 0;
                                controller.attributeEnabled.forEach((
                                  key,
                                  value,
                                ) {
                                  value.value = false;
                                });
                              },
                            ),
                          ],
                        );
                      }),
                    ),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                    ...controller.allAttributesList.map((attr) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Obx(() {
                          final isChecked =
                              controller.attributeEnabled[attr.attributeName] ??
                              false.obs;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isChecked.value,
                                    onChanged: (value) {
                                      final allowed =
                                          controller
                                              .selectedLabelFormatObj
                                              .value
                                              ?.elementsAllowedToPrint ??
                                          0;

                                      if (value == true) {
                                        if (controller
                                                .selectedAttributesCount
                                                .value >=
                                            allowed) {
                                          Get.snackbar(
                                            'Limit Reached',
                                            'Only $allowed attributes allowed for this label format.',
                                          );
                                          return;
                                        }
                                        isChecked.value = true;
                                        controller
                                            .selectedAttributesCount
                                            .value++;
                                      } else {
                                        isChecked.value = false;
                                        controller
                                            .selectedAttributesCount
                                            .value--;
                                      }
                                    },
                                  ),
                                  Text(
                                    (attr.attributeName ?? '').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SearchableStringDropdown(
                                label: attr.attributeName!,
                                items:
                                    attr.options
                                        ?.map((e) => e.optionsName ?? '')
                                        .toList() ??
                                    [],
                                selectedValue:
                                    controller.selectedAttributes[attr
                                        .attributeName] ??
                                    ''.obs,
                                onItemSelected: (value) {
                                  controller
                                          .selectedAttributes[attr
                                              .attributeName]!
                                          .value =
                                      value;
                                },
                              ),
                            ],
                          );
                        }),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: layout.sectionSpacing),
        AdaptiveSectionCard(
          title: 'Weight Capture',
          subtitle:
              'Use the connected scale or manual fields below to build the current non-batch session.',
          child: NonBatchBluetoothWeightSection(
            isTablet: layout.isTablet,
            dashboardController: dashboardController,
            controller: controller,
          ),
        ),
      ],
    );
  }
}

class _SelectedProductSummary extends StatelessWidget {
  const _SelectedProductSummary({
    required this.controller,
    required this.layout,
  });

  final NonBatchInwardController controller;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Selected Product Summary',
      subtitle:
          'Keep the active product, label format, and chosen attributes visible while the operator works through the session.',
      child: Obx(() {
        final selectedProduct = controller.selectedProduct.value;
        final selectedFormat = controller.selectedLabelFormat.value;
        final selectedAttributes = controller.selectedAttributes.entries.where((
          entry,
        ) {
          final enabled =
              controller.attributeEnabled[entry.key]?.value ?? false;
          return enabled && entry.value.value.trim().isNotEmpty;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryBadge(
              label: 'Product',
              value: selectedProduct?.name ?? 'No product selected',
            ),
            const SizedBox(height: 10),
            _SummaryBadge(
              label: 'Label Format',
              value: selectedFormat.isEmpty ? 'Not selected' : selectedFormat,
            ),
            const SizedBox(height: 12),
            Text(
              'Enabled Attributes',
              style: TextStyle(
                fontSize: layout.isTablet ? 16 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (selectedAttributes.isEmpty)
              Text(
                'No attributes enabled yet.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedAttributes.map((entry) {
                  return Chip(
                    label: Text('${entry.key}: ${entry.value.value}'),
                    backgroundColor: ColorsValue.primaryColor.withValues(
                      alpha: 0.08,
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      }),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NonBatchActionSection extends StatelessWidget {
  const _NonBatchActionSection({
    required this.controller,
    required this.layout,
    required this.showInlineAddButton,
  });

  final NonBatchInwardController controller;
  final AppLayoutSpec layout;
  final bool showInlineAddButton;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Session Actions',
      subtitle:
          'Keep transaction controls visible and move the primary add-entry action into the tablet workflow area.',
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
            child: NonBatchInwardActionBar(
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

class _NonBatchLogsPanel extends StatelessWidget {
  const _NonBatchLogsPanel({required this.controller, required this.layout});

  final NonBatchInwardController controller;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Transaction Logs',
      subtitle:
          'Review and remove saved session entries without leaving the current transaction.',
      child: Obx(() {
        if (controller.productList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'No transaction entries added yet.',
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
            final product = controller.productList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey(product.productId ?? index),
                direction: DismissDirection.endToStart,
                background: _buildDismissBackground(),
                confirmDismiss: (_) => _confirmDelete(context, product),
                onDismissed: (_) {
                  controller.productList.removeAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${product.productName}" removed'),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: Colors.white,
                        onPressed: () {
                          controller.productList.insert(index, product);
                        },
                      ),
                    ),
                  );
                },
                child: NonBatchProductCard(
                  product: product,
                  isTablet: layout.isTablet,
                  controller: controller,
                ),
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

  Future<bool?> _confirmDelete(BuildContext context, NonBatchProducts product) {
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
          'Are you sure you want to remove "${product.productName}" from the list?\nThis cannot be undone.',
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/constants/sizes.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchController.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchProductCard.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchWeightSection.dart';
import 'package:punit_label/widgets/customAppBar.dart';

import '../../../constants/utility.dart';
import '../../../widgets/customDrawer.dart';
import '../../../widgets/searchableDropdown.dart';
import '../../dashboard/dashboardController.dart';

class NonBatchInwardScreen extends StatelessWidget {
  NonBatchInwardScreen({super.key});
  final controller = Get.put(NonBatchInwardController());
  final dashboardController = Get.find<DashboardController>();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 600;
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [CircularProgressIndicator(), Text('Fetching Data...')],
            ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      Dimens.boxHeight12,
                      Utility.styledInputField(
                        label: 'Transaction Name',
                        icon: Icons.label_outlined,
                        keyboard: TextInputType.text,
                        isTablet: isTablet,
                        controller: controller.transactionName,
                      ),
                      // Dimens.boxHeight12,
                      // Utility.styledInputField(
                      //   label: 'Serial Number',
                      //   icon: Icons.onetwothree,
                      //   keyboard: TextInputType.number,
                      //   isTablet: isTablet,
                      //   controller: controller.serialNumber,
                      // ),
                      //  CustomTitle(title: "Select Product", titleAlign: TextAlign.left),
                      Dimens.boxHeight12,
                      Utility.styledDropdown(
                        child: SearchableMapDropdown(
                          label: "Select Product",
                          items: controller.dropdownProducts,
                          selectedValue: controller.selectedProduct,
                          onItemSelected: (val) =>
                              controller.changeSelectedProductId(val.id),
                        ),
                      ),
                      SizedBox(height: 12),
                      ExpansionTile(
                        title: const Text("Product Attributes"),
                        children: [
                          /// ---------------------------------------
                          ///  LABEL FORMAT DROPDOWN
                          /// ---------------------------------------
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
                                    "LABEL SIZE",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SearchableStringDropdown(
                                    label: "Select Label Size",
                                    items: const ["75x75", "100x100"],
                                    selectedValue: controller.selectedLabelSize,
                                    onItemSelected: controller.changeLabelSize,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "LABEL FORMAT",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  if (controller.isTemplateOptionsLoading.value)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (controller
                                      .labelTemplateOptions
                                      .isEmpty)
                                    const Text(
                                      "No label formats available for this product and size.",
                                    )
                                  else
                                    SearchableStringDropdown(
                                      label: "Select Label Format",
                                      items: controller.labelTemplateOptions
                                          .map((e) => e.name)
                                          .toList(),
                                      selectedValue:
                                          controller.selectedLabelFormat,
                                      onItemSelected: controller
                                          .selectLabelTemplateOptionByName,
                                    ),
                                  if (controller.isCustomTemplateSelected) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      "Custom templates currently print fixed fields only in non-batch inward.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }),
                          ),
                          Divider(thickness: 1),
                          const SizedBox(height: 16),

                          /// ---------------------------------------
                          /// ATTRIBUTE LIST UI
                          /// ---------------------------------------
                          if (controller.isCustomTemplateSelected)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                "Attribute selection is disabled for custom templates in this version.",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            )
                          else
                            ...controller.allAttributesList.map((attr) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Obx(() {
                                  final isChecked =
                                      controller.attributeEnabled[attr
                                          .attributeName] ??
                                      false.obs;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: isChecked.value,
                                            onChanged: (v) {
                                              final allowed =
                                                  controller
                                                      .selectedLabelFormatObj
                                                      .value
                                                      ?.elementsAllowedToPrint ??
                                                  0;

                                              if (v == true) {
                                                if (controller
                                                        .selectedAttributesCount
                                                        .value >=
                                                    allowed) {
                                                  Get.snackbar(
                                                    "Limit Reached",
                                                    "Only $allowed attributes allowed for this label format.",
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
                                            (attr.attributeName ?? "")
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      /// ---------------------------------------
                                      /// ATTRIBUTE OPTIONS DROPDOWN
                                      /// ---------------------------------------
                                      SearchableStringDropdown(
                                        label: attr.attributeName!,
                                        items:
                                            attr.options
                                                ?.map(
                                                  (e) => e.optionsName ?? "",
                                                )
                                                .toList() ??
                                            [],

                                        selectedValue:
                                            controller.selectedAttributes[attr
                                                .attributeName] ??
                                            "".obs,
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
                            }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              NonBatchBluetoothWeightSection(
                isTablet: isTablet,
                dashboardController: dashboardController,
                controller: controller, // your screen controller
              ),
              SizedBox(height: isTablet ? 26 : 20),

              NonBatchInwardActionBar(
                controller: controller,
                isTablet: isTablet,
                context: context,
              ),

              SizedBox(height: isTablet ? 28 : 5),

              Text(
                "Transaction Logs",
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: isTablet ? 28 : 5),

              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.productList.length,
                  itemBuilder: (context, index) {
                    final product = controller.productList[index];
                    final itemKey = ValueKey(product.productId ?? index);

                    return Dismissible(
                      key: itemKey,
                      direction: DismissDirection.endToStart,
                      background: _buildDismissBackground(),
                      confirmDismiss: (direction) async {
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
                              "Are you sure you want to remove \"${product.productName}\" from the list?\nThis cannot be undone.",
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
                        controller.productList.removeAt(index);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("\"${product.productName}\" removed"),
                            backgroundColor: Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            action: SnackBarAction(
                              label: "UNDO",
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
                        isTablet: isTablet,
                        controller: controller,
                      ),
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
          onPressed: () async {
            // controller.inwardState.value = InwardState.running;
            await controller.addToList();
          },
          label: Text('Add Entry', style: TextStyle(color: Colors.white)),
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: ColorsValue.primaryColor,
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

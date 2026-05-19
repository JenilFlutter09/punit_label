import 'package:flutter/material.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/constants/styles.dart';
import 'package:punit_label/features/dispatch/dispatchController.dart';
import 'package:get/get.dart';

import '../../../constants/sizes.dart';
import '../../../constants/utility.dart';
import '../../../widgets/customAppBar.dart';
import '../../../widgets/customButton.dart';
import '../../../widgets/customDrawer.dart';
import '../../../widgets/miscellenous.dart';
import '../../scanner/scannerDailog.dart';
import '../models/customerModel.dart';
import '../models/dispatchBarcodes.dart';
import '../models/dispatchModel.dart';

class DispatchScreen extends StatelessWidget {
  DispatchScreen({super.key});
  final controller = Get.put(DispatchController());
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Dispatch',
        showScale: false,
        showPrinter: false,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: Obx(() {
        if (controller.initLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Customer & Product Selection Section
              ProductSelectorSection(
                controller: controller,
                isTablet: isTablet,
              ),

              /// Action Buttons (Scan, PDF, Save)
              Padding(
                padding: Dimens.edgeInsets10_0_10_0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Obx(() {
                        return controller
                                    .dispatchModel
                                    .value
                                    ?.data
                                    ?.isNotEmpty ??
                                false
                            ? CustomButton(
                                onPressed: () async {
                                  final result = await showBarcodeScannerDialog(
                                    context,
                                  );
                                  if (result == null) {
                                    Utility.showDialog('Re - Scan Please');
                                  } else {
                                    controller.verifyAndAddBarcode(result);
                                  }
                                },
                                text: 'Scanner',
                                textStyle: Styles.whiteBold22,
                                icon: Icons.document_scanner_outlined,
                                iconSize: Dimens.thirty,
                                height: Dimens.sixty,
                                backgroundColor: Colors.orange,
                              )
                            : CustomButton(
                                onPressed: () {},
                                icon: Icons.document_scanner_outlined,
                                iconSize: Dimens.thirty,
                                text: 'Scanner',
                                textStyle: Styles.whiteBold22,
                                height: Dimens.sixty,
                                backgroundColor: Colors.grey,
                              );
                      }),
                    ),
                    Dimens.boxWidth5,
                    Expanded(
                      flex: 1,
                      child: Obx(() {
                        var isListEmpty = controller.barcodeList.isEmpty;

                        return isListEmpty
                            ? CustomButton(
                                onPressed: () {},
                                text: 'Save',
                                textStyle: Styles.whiteBold22,
                                icon: Icons.check_circle,
                                iconSize: Dimens.thirty,
                                height: Dimens.sixty,
                                backgroundColor: Colors.grey,
                              )
                            : CustomButton(
                                onPressed: () async {
                                  await controller.saveAndSubmitScannedBarcodes(
                                    context,
                                  );
                                },
                                text: 'Save',
                                textStyle: Styles.whiteBold22,
                                icon: Icons.check_circle,
                                iconSize: Dimens.thirty,
                                height: Dimens.sixty,
                                backgroundColor: Colors.green,
                              );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 28 : 20),

              /// Dispatch Logs List
              Text(
                "Dispatch Logs",
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),

              DispatchLogsList(controller: controller, isTablet: isTablet),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await controller.refresh(),
        child: Icon(Icons.refresh,color: Colors.white,),
        backgroundColor: ColorsValue.primaryColor,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

class ProductSelectorSection extends StatelessWidget {
  final DispatchController controller;
  final bool isTablet;

  const ProductSelectorSection({
    super.key,
    required this.controller,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomTitle(
              title: "Select Customer",
              titleAlign: TextAlign.left,
            ),
            Dimens.boxHeight12,
            Utility.styledDropdown(
              child: SearchableCustomerDropdown(
                label: "Select Customer",
                items: controller.customerList,
                selectedValue: controller.selectedCustomer,
                onItemSelected: (val) async =>
                    await controller.changeSelectedCustomerId(val.id ?? 1),
              ),
            ),
            Dimens.boxHeight12,
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: controller.manualBarcode,
                      autofocus: true,
                        onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          controller.verifyAndAddBarcode(value.trim());
                        }
                      },
                      decoration: InputDecoration(
                        // helperText: 'Barcode String here...',
                        labelText: 'Barcode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Dimens.boxWidth8,
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (controller.manualBarcode.text.isNotEmpty) {
                          controller.verifyAndAddBarcode(
                            controller.manualBarcode.text,
                          );
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimens.ten),
                          color: ColorsValue.primaryColor,
                        ),
                        padding: Dimens.edgeInsets5,
                        child: Text(
                          'Add Entry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: Dimens.sixteen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductInfoCard extends StatelessWidget {
  final String productName;
  final List<Variation> combinations;
  final bool isTablet;
  final bool isClickable;

  const ProductInfoCard({
    super.key,
    required this.productName,
    required this.combinations,
    required this.isTablet,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 0.8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 14 : 10,
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: combinations.map((c) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 10,
                vertical: isTablet ? 10 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 0.7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${c.attributeName}: ${c.optionName}",
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class InwardListItem extends StatelessWidget {
  final Dispatchbarcodes product;
  final bool isTablet;

  const InwardListItem({
    Key? key,
    required this.product,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasTare = product.isTareWeight == true;

    return SizedBox(
      width: Get.width,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        shadowColor: Colors.black.withOpacity(0.08),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
              stops: const [0.3, 1.0],
            ),
          ),
          child: Padding(
            padding: Dimens.edgeInsets15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Product Name
                Text(
                  product.productName ?? "Unknown Product",
                  style: TextStyle(
                    fontSize: isTablet ? 19 : 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[850],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                /// Variations
                if ((product.variation ?? []).isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: product.variation!
                        .map(_buildVariationChip)
                        .toList(),
                  ),

                const SizedBox(height: 10),

                /// Weights
                Wrap(
                  spacing: 10,
                  runSpacing: 9,
                  children: [
                    if (product.grossWeight != null)
                      _buildWeightChip(
                        label: "Gross",
                        value: "${product.grossWeight} kg",
                        color: const Color(0xFF2196F3),
                        icon: Icons.scale,
                      ),

                    if (hasTare)
                      _buildWeightChip(
                        label: "Tare",
                        value: "${product.tareWeight} kg",
                        color: const Color(0xFFFF9800),
                        icon: Icons.line_weight,
                      ),

                    _buildWeightChip(
                      label: "Net",
                      value: "${product.netWeight} kg",
                      color: const Color(0xFF4CAF50),
                      icon: Icons.balance,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Variation chip
  Widget _buildVariationChip(Variation v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        "${v.attributeName}: ${v.optionName}",
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 🔹 Weight chip
  Widget _buildWeightChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        Dimens.boxWidth8,
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: isTablet ? 20 : 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 20 : 15,
            fontWeight: FontWeight.w900,
            color: Colors.grey[850],
          ),
        ),
      ],
    );
  }
}

class DispatchLogsList extends StatelessWidget {
  final DispatchController controller;
  final bool isTablet;

  const DispatchLogsList({
    super.key,
    required this.controller,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.barcodeList.length,
        itemBuilder: (context, index) {
          final data = controller.barcodeList[index];

          return Dismissible(
            key: ValueKey(data),
            direction: DismissDirection.endToStart,
            background: _dismissBg(),

            confirmDismiss: (direction) async {
              return _confirmDelete(context, data.barCodeString ?? "");
            },

            onDismissed: (_) {
              final removed = controller.barcodeList.removeAt(index);
              controller.verifiedBarcodeList.removeAt(index);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("\"${removed.barCodeString}\" removed"),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  action: SnackBarAction(
                    label: "UNDO",
                    textColor: Colors.white,
                    onPressed: () {
                      controller.barcodeList.insert(index, removed);
                    },
                  ),
                ),
              );
            },

            child: InwardListItem(product: data, isTablet: isTablet),
          );
        },
      ),
    );
  }

  Widget _dismissBg() {
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

  Future<bool?> _confirmDelete(BuildContext ctx, String title) {
    return showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text("Delete Entry?"),
          ],
        ),
        content: Text(
          "Are you sure you want to remove \"$title\"?\nThis cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/*
class SearchableStringDropdown extends StatelessWidget {
  final String label;
  final List<dispatchProducts> items;
  final Rxn<dispatchProducts> selectedValue;
  final double modalHeightFactor;
  final void Function(dispatchProducts)? onItemSelected;

  const SearchableStringDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValue,
    this.modalHeightFactor = 0.75,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final displayText = selectedValue.value?.productName ?? "";

      return GestureDetector(
        onTap: () => _openSearchModal(context),
        child: InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            displayText,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      );
    });
  }

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: modalHeightFactor,
          child: _SearchModalContent(
            label: label,
            items: items,
            selectedValue: selectedValue,
            onItemSelected: onItemSelected,
          ),
        );
      },
    );
  }
}

class _SearchModalContent extends StatelessWidget {
  final String label;
  final List<dispatchProducts> items;
  final Rxn<dispatchProducts> selectedValue;
  final void Function(dispatchProducts)? onItemSelected;

  const _SearchModalContent({
    required this.label,
    required this.items,
    required this.selectedValue,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    String search = "";

    return StatefulBuilder(
      builder: (context, setState) {
        final filtered = items.where((e) {
          final name = e.productName?.toLowerCase() ?? "";
          return name.contains(search.toLowerCase());
        }).toList();

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select $label",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Search field
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search $label...",
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text("No item found"))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected =
                              selectedValue.value?.stockId == item.stockId;

                          return ListTile(
                            title: Text(item.productName ?? ''),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              selectedValue.value = item;
                              onItemSelected?.call(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),

              // Bottom actions
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      selectedValue.value = null;
                      onItemSelected?.call(
                        dispatchProducts(stockId: 0, productName: ""),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Clear"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
*/

class SearchableCustomerDropdown extends StatelessWidget {
  final String label;
  final List<Customer> items;
  final Rxn<Customer> selectedValue;
  final double modalHeightFactor;
  final void Function(Customer)? onItemSelected;

  const SearchableCustomerDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValue,
    this.modalHeightFactor = 0.75,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final displayText = selectedValue.value?.name ?? "";

      return GestureDetector(
        onTap: () => _openSearchModal(context),
        child: InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            displayText,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      );
    });
  }

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: modalHeightFactor,
          child: _SearchCustomerContent(
            label: label,
            items: items,
            selectedValue: selectedValue,
            onItemSelected: onItemSelected,
          ),
        );
      },
    );
  }
}

class _SearchCustomerContent extends StatelessWidget {
  final String label;
  final List<Customer> items;
  final Rxn<Customer> selectedValue;
  final void Function(Customer)? onItemSelected;

  const _SearchCustomerContent({
    required this.label,
    required this.items,
    required this.selectedValue,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    String search = "";

    return StatefulBuilder(
      builder: (context, setState) {
        final filtered = items.where((e) {
          final name = (e.name ?? "").toLowerCase();
          return name.contains(search.toLowerCase());
        }).toList();

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select $label",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Search field
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search $label...",
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => search = v),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text("No item found"))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = selectedValue.value?.id == item.id;

                          return ListTile(
                            title: Text(item.name ?? ''),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              selectedValue.value = item;
                              onItemSelected?.call(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),

              // Bottom actions
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      selectedValue.value = null;
                      // onItemSelected?.call(
                      //     Customer(id: 0, productName: ""));
                      Navigator.pop(context);
                    },
                    child: const Text("Clear"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

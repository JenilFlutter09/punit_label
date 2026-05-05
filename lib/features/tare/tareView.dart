// views/add_tare_products_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/colors.dart';

import 'package:punit_label/constants/styles.dart';
import 'package:punit_label/features/tare/tareController.dart';
import 'package:punit_label/features/tare/tareScaleConnection.dart';
import 'package:punit_label/widgets/customAppBar.dart';

import '../../constants/sizes.dart';
import '../../widgets/customDrawer.dart';

class AddTareProductsView extends StatelessWidget {
  const AddTareProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final tareCtrl = Get.put(TareProductController());
    final tareScaleCtrl = TareScaleConnectionController.ensureRegistered();
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Tare Products',
        showScale: true,
        showPrinter: true,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: Dimens.edgeInsets16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProductSelector(tareCtrl, isTablet),
                  Dimens.boxHeight20,
                  TareScaleConnectionCard(
                    controller: tareScaleCtrl,
                    isTablet: isTablet,
                  ),
                  Dimens.boxHeight20,

                  // Smart Weight Input: Auto or Manual
                  Obx(
                    () => tareScaleCtrl.isConnected
                        ? _buildLiveWeightCard(
                            tareCtrl,
                            tareScaleCtrl,
                            isTablet,
                          )
                        : _buildManualWeightInput(tareCtrl, isTablet),
                  ),

                  Dimens.boxHeight20,
                  _buildTareItemsList(tareCtrl, isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
      // Submit Button
      floatingActionButton: Padding(
        padding: Dimens.edgeInsets16,
        child: ElevatedButton(
          onPressed: tareCtrl.submitAll,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsValue.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
          ),
          child: Padding(
            padding: Dimens.edgeInsets10_0_10_0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save,color: Colors.white,),
                Dimens.boxWidth8,
                Text(
                  "Save Products",
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Manual Weight Input (When Scale is Disconnected)
  Widget _buildManualWeightInput(TareProductController ctrl, bool isTablet) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: Dimens.edgeInsets20,
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.edit, size: 32, color: ColorsValue.primaryColor),
                const SizedBox(width: 12),
                Text("Manual Weight Entry", style: Styles.blackBold18),
              ],
            ),
            Dimens.boxHeight16,
            TextFormField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Enter Weight (kg)",
                prefixIcon: const Icon(Icons.scale),
                suffixText: "kg",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value) ?? 0.0;
                ctrl.currentWeight.value = parsed;
              },
            ),
            Dimens.boxHeight16,
            ElevatedButton.icon(
              onPressed: ctrl.addCurrentWeightAsTare,
              icon: const Icon(Icons.add_task),
              label: const Text("Add This Weight as Tare"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Live Weight Card (When Scale is Connected)
  Widget _buildLiveWeightCard(
    TareProductController ctrl,
    TareScaleConnectionController scaleCtrl,
    bool isTablet,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: Dimens.edgeInsets20,
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.scale, size: 32, color: ColorsValue.primaryColor),
                const SizedBox(width: 12),
                Text("Live Weight", style: Styles.blackBold18),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bluetooth_connected,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Connected",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Dimens.boxHeight20,
            Obx(
              () => Text(
                "${scaleCtrl.liveWeight.value.toStringAsFixed(3)} kg",
                style: TextStyle(
                  fontSize: isTablet ? 52 : 44,
                  fontWeight: FontWeight.w900,
                  color: scaleCtrl.liveWeight.value > 0
                      ? ColorsValue.primaryColor
                      : Colors.grey,
                ),
              ),
            ),
            Dimens.boxHeight20,
            ElevatedButton.icon(
              onPressed: () {
                ctrl.currentWeight.value = scaleCtrl.liveWeight.value;
                ctrl.addCurrentWeightAsTare();
              },
              icon: const Icon(Icons.add_task),
              label: const Text("Add This Weight as Tare"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelector(TareProductController ctrl, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => DropdownButtonFormField<String>(
              initialValue: ctrl.selectedProductName.value.isEmpty
                  ? null
                  : ctrl.selectedProductName.value,
              hint: const Text("Select Tare Product"),
              decoration: InputDecoration(
                labelText: "Product Name",
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: ctrl.tareProductNames
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              onChanged: (val) => ctrl.selectedProductName.value = val!,
            ),
          ),
        ),
        Dimens.boxWidth10,
        ElevatedButton.icon(
          onPressed: () => _showAddProductDialog(ctrl),
          icon: const Icon(Icons.add, size: 20, color: Colors.white),
          label: Text(
            isTablet ? "Add New" : "Add",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsValue.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildTareItemsList(TareProductController ctrl, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Added Tare Items", style: Styles.blackBold18),
        Dimens.boxHeight12,
        Obx(
          () => ctrl.addedTareItems.isEmpty
              ? Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: Dimens.edgeInsets20,
                    child: Center(
                      child: Text(
                        "No tare items added yet",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ctrl.addedTareItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = ctrl.addedTareItems[i];
                    return Dismissible(
                      key: ValueKey(item),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                        ),
                      ),
                      onDismissed: (_) => ctrl.removeItem(i),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ColorsValue.primaryColor,
                          child: Icon(Icons.double_arrow_sharp,color: Colors.white,)
                        ),
                        title: Text(
                          item.productName ?? 'Product Name',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          "${item.weight?.toStringAsFixed(3)} kg",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorsValue.primaryColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddProductDialog(TareProductController ctrl) {
    Get.dialog(
      AlertDialog(
        title: const Text("Add New Tare Product"),
        content: TextField(
          controller: ctrl.newNameController,
          decoration: const InputDecoration(
            hintText: "e.g., Plastic Tray 200g",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: ctrl.addNewProductName,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

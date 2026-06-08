import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/constants/styles.dart';
import 'package:punit_label/features/tare/tareController.dart';
import 'package:punit_label/features/tare/tareScaleConnection.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import 'package:punit_label/widgets/customDrawer.dart';

class AddTareProductsView extends StatelessWidget {
  const AddTareProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final tareCtrl = Get.put(TareProductController());
    final tareScaleCtrl = TareScaleConnectionController.ensureRegistered();
    final layout = context.layoutSpec;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Add Tare Products',
        showScale: true,
        showPrinter: true,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: AdaptiveWorkflowShell(
        title: 'Tare Products',
        subtitle:
            'Configure the tare product and capture weight on the left while reviewing the running tare session on the right.',
        headerBadge: 'Tare Setup',
        compactContent: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TareCapturePanel(
              tareCtrl: tareCtrl,
              tareScaleCtrl: tareScaleCtrl,
              layout: layout,
            ),
            SizedBox(height: layout.sectionSpacing),
            _TareItemsPanel(ctrl: tareCtrl, layout: layout),
          ],
        ),
        leftPanel: _TareCapturePanel(
          tareCtrl: tareCtrl,
          tareScaleCtrl: tareScaleCtrl,
          layout: layout,
        ),
        rightPanel: _TareItemsPanel(ctrl: tareCtrl, layout: layout),
        primaryAction: layout.isExpandedTablet
            ? _SaveTareAction(ctrl: tareCtrl)
            : null,
      ),
      floatingActionButton: layout.isExpandedTablet
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _SaveTareAction(ctrl: tareCtrl),
            ),
    );
  }
}

class _TareCapturePanel extends StatelessWidget {
  const _TareCapturePanel({
    required this.tareCtrl,
    required this.tareScaleCtrl,
    required this.layout,
  });

  final TareProductController tareCtrl;
  final TareScaleConnectionController tareScaleCtrl;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdaptiveSectionCard(
          title: 'Product Setup',
          subtitle:
              'Choose the tare product first so the printed barcode and saved entry stay aligned.',
          child: _buildProductSelector(context),
        ),
        SizedBox(height: layout.sectionSpacing),
        AdaptiveSectionCard(
          title: 'Scale Connection',
          subtitle:
              'Use the live scale when available, or fall back to manual entry for tare capture.',
          child: TareScaleConnectionCard(
            controller: tareScaleCtrl,
            isTablet: layout.isTablet,
          ),
        ),
        SizedBox(height: layout.sectionSpacing),
        AdaptiveSectionCard(
          title: 'Weight Capture',
          subtitle:
              'Add the live or manual weight directly into the current tare list.',
          child: Obx(
            () => tareScaleCtrl.isConnected
                ? _buildLiveWeightCard(tareCtrl, tareScaleCtrl)
                : _buildManualWeightInput(tareCtrl),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => DropdownButtonFormField<String>(
              initialValue: tareCtrl.selectedProductName.value.isEmpty
                  ? null
                  : tareCtrl.selectedProductName.value,
              hint: const Text('Select Tare Product'),
              decoration: InputDecoration(
                labelText: 'Product Name',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: tareCtrl.tareProductNames
                  .map(
                    (name) => DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                tareCtrl.selectedProductName.value = value ?? '';
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
            label: Text(layout.isTablet ? 'Add New' : 'Add'),
          ),
        ),
      ],
    );
  }

  Widget _buildManualWeightInput(TareProductController ctrl) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.edit, size: 30, color: ColorsValue.primaryColor),
            const SizedBox(width: 12),
            Text('Manual Weight Entry', style: Styles.blackBold18),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Enter Weight (kg)',
            prefixIcon: const Icon(Icons.scale),
            suffixText: 'kg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            ctrl.currentWeight.value = double.tryParse(value) ?? 0.0;
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: ctrl.addCurrentWeightAsTare,
            icon: const Icon(Icons.add_task),
            label: const Text('Add This Weight as Tare'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveWeightCard(
    TareProductController ctrl,
    TareScaleConnectionController scaleCtrl,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.scale, size: 30, color: ColorsValue.primaryColor),
            const SizedBox(width: 12),
            Text('Live Weight', style: Styles.blackBold18),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    'Connected',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Obx(
          () => Text(
            '${scaleCtrl.liveWeight.value.toStringAsFixed(3)} kg',
            style: TextStyle(
              fontSize: layout.isTablet ? 52 : 44,
              fontWeight: FontWeight.w900,
              color: scaleCtrl.liveWeight.value > 0
                  ? ColorsValue.primaryColor
                  : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ctrl.currentWeight.value = scaleCtrl.liveWeight.value;
              ctrl.addCurrentWeightAsTare();
            },
            icon: const Icon(Icons.add_task),
            label: const Text('Add This Weight as Tare'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddProductDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Add New Tare Product'),
        content: TextField(
          controller: tareCtrl.newNameController,
          decoration: const InputDecoration(
            hintText: 'e.g., Plastic Tray 200g',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: tareCtrl.addNewProductName,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TareItemsPanel extends StatelessWidget {
  const _TareItemsPanel({required this.ctrl, required this.layout});

  final TareProductController ctrl;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Tare Item List',
      subtitle:
          'Review, remove, and verify the items waiting to be saved to the backend.',
      child: Obx(
        () => ctrl.addedTareItems.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No tare entries added yet.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.addedTareItems.length,
                itemBuilder: (context, index) {
                  final item = ctrl.addedTareItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
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
                      onDismissed: (_) => ctrl.removeItem(index),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: Colors.grey.shade50,
                        leading: CircleAvatar(
                          backgroundColor: ColorsValue.primaryColor,
                          child: const Icon(
                            Icons.double_arrow_sharp,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          item.productName ?? 'Product Name',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          '${item.weight?.toStringAsFixed(3)} kg',
                          style: TextStyle(
                            fontSize: layout.isTablet ? 17 : 15,
                            fontWeight: FontWeight.bold,
                            color: ColorsValue.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SaveTareAction extends StatelessWidget {
  const _SaveTareAction({required this.ctrl});

  final TareProductController ctrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: ctrl.submitAll,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsValue.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'Save Products',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

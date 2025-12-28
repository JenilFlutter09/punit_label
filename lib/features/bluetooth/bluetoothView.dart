/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:punit_label/constants/strings.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import '/constants/colors.dart';
import '/constants/sizes.dart';
import '/constants/styles.dart';
import '/features/bluetooth/bluetoothController.dart';
import '/widgets/bluetooth_bottomsheet.dart';
import '/widgets/searchableDropdown.dart';
import 'package:printing/printing.dart';

class BluetoothView extends StatelessWidget {
  BluetoothView({super.key});
  Future<void> _generatePDF(
    BuildContext context,
    BluetoothController controller,
  ) async
  {
    controller.recordInwardEntry();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Center(
                child: pw.Text(
                  "Transaction Report",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  "GRN",
                  "Order",
                  "Item",
                  "Gross",
                  "Tare",
                  "Net",
                  "Timestamp",
                ],
                data:
                    controller.recordedEntries.map((e) {
                      return [
                        controller.grnNumber,
                        controller.orderNumber,
                        e.productId ?? '',
                        "${e.grossWeight} kg",
                        "${e.tareWeight} kg",
                        "${e.netWeight} kg",
                        //DateTime.parse(e['timestamp']).toLocal().toString(),
                      ];
                    }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                border: pw.TableBorder.all(width: 0.5),
                cellHeight: 30,
              ),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BluetoothController>();
    final dashBoardController = Get.find<DashboardController>();

    return WillPopScope(
      onWillPop: () async {
        controller.recordedEntries.clear();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "INWARD",
                style: Styles.primaryBold16.copyWith(color: Colors.white),
              ),
              Obx(
                () => Row(
                  children: [
                    Switch(
                      value: controller.isBluetoothMode.value,
                      onChanged: (v) => controller.isBluetoothMode.value = v,
                      activeColor: Colors.green,
                    ),
                    Icon(Icons.bluetooth, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          elevation: 0,
          centerTitle: false,
          backgroundColor: ColorsValue.primaryColor,
          automaticallyImplyLeading: false,
        ),

        body: Obx(() {
          /// --- CASE 1: BLUETOOTH MODE ---
          if (controller.isBluetoothMode.value) {
            if (controller.connectedDevice.value == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bluetooth_disabled,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "No device connected",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.bluetooth_searching,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Connect Device",
                        style: Styles.primary14.copyWith(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsValue.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => showBluetoothSheet(context, dashBoardController,SStringConstants.role_scale)
                    ),
                  ],
                ),
              );
            }

            // ✅ Connected device
            return _entryForm(
              context: context,
              controller: controller,
              weightWidget: Obx(
                () => Text(
                  "Live Weight: ${controller.receivedData.value}",
                  style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                ),
              ),
              showDisconnect: true,
            );
          }

          /// --- CASE 2: MANUAL MODE ---
          return _entryForm(
            context: context,
            controller: controller,
            weightWidget: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Gross Weight",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    controller.manualGross.value = v;
                    controller.calculateManualNet();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Tare Weight",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    controller.manualTare.value = v;
                    controller.calculateManualNet();
                  },
                ),
                Dimens.boxHeight15,
                Obx(
                  () => Container(
                    width: Get.width,
                    alignment: Alignment.center,
                    child: Text(
                      "Net Weight: ${controller.manualNet.value}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Dimens.boxHeight15,
              ],
            ),
            showDisconnect: false,
          );
        }),
        floatingActionButton: FloatingActionButton.extended(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: ColorsValue.primaryColor,
            icon: Icon(Icons.save,color: Colors.white,size: Dimens.thirtyFive,),
            onPressed: () async => await controller.saveAndSubmit(), label: Text('Save',style: Styles.primaryBold16.copyWith(color: Colors.white),),),
      ),
    );
  }

  Widget _entryForm({
    required BuildContext context,
    required BluetoothController controller,
    required Widget weightWidget,
    required bool showDisconnect,
  }) {
    return SingleChildScrollView(
      padding: Dimens.edgeInsets10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Section: Details
         // Text("Details", style: _sectionTitle),
          Row(
            children: [
              Expanded(child: Text("GRN Number", style: _sectionTitle)),
              Dimens.boxWidth10,
              Expanded(child: Text("Order Number", style: _sectionTitle)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
           // height: Dimens.fifty,
            alignment: Alignment.center,

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _styledInputField(
                    label: "GRN Number",
                    icon: Icons.confirmation_number,
                    onChanged: (v) => controller.grnNumber.value = v,
                    showSuffix: false,
                    keyboard: TextInputType.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _styledDropdown(
                    child:SearchableStringDropdown(
                      label: "Order Number",
                      items: controller.dropdownOrderList, // 👈 list of order numbers
                      selectedValue: controller.orderNumber, // RxString bound directly
                      onItemSelected: (val) {
                        controller.fetchOrderDetail(orderId: val); // 👈 your API call here
                      },
                    ),
                  ),
                ),


              ],
            ),
          ),
         Dimens.boxHeight10,

          // 🔹 Section: Selections
          // Text("Selections", style: _sectionTitle),
          Row(
            children: [
              Expanded(child: Text("Category", style: _sectionTitle)),
              Dimens.boxWidth10,
              Expanded(child: controller.selectedCategory.value?.name == "Scrap" ? Text("Select Grade", style: _sectionTitle) : Text("Product Profile", style: _sectionTitle)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _styledDropdown(
                  child: SearchableMapDropdown(
                    label: "Category",
                    items: controller.dropdownCategories,
                    selectedValue: controller.selectedCategory,
                  ),
                ),
              ),
              Dimens.boxWidth5,
              Expanded(
                child:
                    controller.selectedCategory.value?.name == "Scrap"
                        ? _styledDropdown(
                          child: SearchableStringDropdown(
                            label: "Select Grade",
                            items: controller.dropdownGradeList,
                            selectedValue: controller.dropdownGrade,
                          ),
                        )
                        : _styledDropdown(
                          child: SearchableMapDropdown(
                            label: "Select Product",
                            items: controller.dropdownProducts,
                            selectedValue: controller.selectedProduct,
                          ),
                        ),
              ),
            ],
          ),
          Dimens.boxHeight10,
          Row(
            children: [
              Expanded(child: Text("Supplier", style: _sectionTitle)),
              Dimens.boxWidth10,
              Expanded(child: Text("Supervisor", style: _sectionTitle)),
            ],
          ),
          Dimens.boxHeight10,
          Row(
            children: [
              Expanded(
                child: _styledDropdown(
                  child: SearchableMapDropdown(
                    label: "Supplier",
                    items: controller.dropdownSuppliers,
                    selectedValue: controller.selectedSupplier,
                  ),
                ),
              ),
              Dimens.boxWidth5,
              Expanded(
                child: _styledDropdown(
                  child: SearchableMapDropdown(
                    label: "Supervisor",
                    items: controller.dropdownSupervisorsList,
                    selectedValue: controller.dropdownSupervisor,
                  ),
                ),
              ),
            ],
          ),
          Dimens.boxHeight15,
          // 🔹 Section: Weights
          Row(
            children: [
              Expanded(child: Text("Gross Weight", style: _sectionTitle)),
              Dimens.boxWidth10,
              Expanded(child: Text("Tare Weight", style: _sectionTitle)),
            ],
          ),
          const SizedBox(height: 12),

          Obx(() {
            if (controller.isBluetoothMode.value &&
                controller.connectedDevice.value != null) {
              // --- BLUETOOTH MODE --
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Gross from Bluetooth live reading
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _styledInputField(
                            label: "Gross Weight",
                            icon: Icons.scale,
                            enabled: false, // read-only, live from device
                            initialValue: controller.manualGross.value,
                            showSuffix: true,
                            keyboard: TextInputType.number,
                          ),
                        ),
                      ),
                      Dimens.boxWidth5,
                      Expanded(
                        child: _styledInputField(
                          label: "Tare Weight",
                          icon: Icons.line_weight,
                          onChanged: (v) {
                            controller.manualTare.value = v;
                            controller.calculateManualNet();
                          },
                          showSuffix: true,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  Dimens.boxHeight15,
                  // Net calculated
                  Obx(
                    () => Container(
                      width: Get.width,
                      alignment: Alignment.center,
                      child: Text(
                        "Net Weight: ${controller.manualNet.value}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Dimens.boxHeight15,
                ],
              );
            } else {
              // --- MANUAL MODE ---
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _styledInputField(
                          label: "Gross Weight",
                          icon: Icons.scale,
                          onChanged: (v) {
                            controller.manualGross.value = v;
                            controller.calculateManualNet();
                          },
                          showSuffix: true,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      Dimens.boxWidth5,
                      Expanded(
                        child: _styledInputField(
                          label: "Tare Weight",
                          icon: Icons.line_weight,
                          onChanged: (v) {
                            controller.manualTare.value = v;
                            controller.calculateManualNet();
                          },
                          showSuffix: true,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  Dimens.boxHeight15,
                  Obx(
                    () => Container(
                      width: Get.width,
                      alignment: Alignment.center,
                      child: Text(
                        "Net Weight: ${controller.manualNet.value}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Dimens.boxHeight15,
                ],
              );
            }
          }),

          /// Action Buttons
          Padding(
            padding: Dimens.edgeInsets10_0_10_0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ✅ Save Button
                Expanded(
                  flex: 1,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      padding: Dimens.edgeInsets15,

                      shadowColor: Colors.greenAccent,
                    ),
                    onPressed: controller.recordEntryManual,
                    child: const Icon(Icons.add_box, size: 34),
                  ),
                ),
                Dimens.boxWidth5,

                // ✅ Clear Button
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Colors.redAccent,
                      padding: Dimens.edgeInsets15,
                    ),
                    onPressed: controller.clearEntries,
                    child: const Icon(Icons.delete_forever, size: 34),
                  ),
                ),
                Dimens.boxWidth5,
                // ✅ PDF Button
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsValue.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Colors.blueAccent,
                      padding: Dimens.edgeInsets15,
                    ),
                     onPressed: () => _generatePDF(context, controller),
                    child: const Icon(Icons.picture_as_pdf, size: 34),
                  ),
                ),

                // ✅ Disconnect Button
                if (showDisconnect)
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: Dimens.edgeInsets5_0_0_0,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: Dimens.edgeInsets15,
                        ),
                        onPressed: controller.disconnectDevice,
                        child: const Icon(
                          Icons.bluetooth_disabled,
                          color: Colors.red,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Dimens.boxHeight10,
          // 🔹 Section: Recorded Entries
          Text("Recorded Entries", style: _sectionTitle),
          const SizedBox(height: 12),
          _recordedEntries(controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Section title style
  final _sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  Widget _styledInputField({
    required String label,
    required IconData icon,
    required TextInputType keyboard,
    Function(String)? onChanged,
    String? initialValue,
    bool enabled = true,
    bool showSuffix = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: TextField(
        enabled: enabled,
        keyboardType: keyboard,
        controller:
            initialValue != null
                ? TextEditingController(text: initialValue)
                : null,
        decoration: InputDecoration(
          //labelText: label,
          hintText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          suffix: showSuffix ? Text('Kg') : Text(''),
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
      ),
    );
  }

  /// 🔹 Wrapper for SearchableDropdown to match input style
  Widget _styledDropdown({required Widget child}) {
    return Container(

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: child,
      ),
    );
  }

  Widget _recordedEntries(BluetoothController controller) {
    return Obx(() {
      if (controller.recordedEntries.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              "No entries yet",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        );
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.recordedEntries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final e = controller.recordedEntries[i];
          final gross =
              double.tryParse("${e.grossWeight}")?.toStringAsFixed(2) ?? "0.00";
          final tare =
              double.tryParse("${e.tareWeight}")?.toStringAsFixed(2) ?? "0.00";
          final net =
              double.tryParse("${e.netWeight}")?.toStringAsFixed(2) ??
              "0.00"; // 🔹 Color based on category
          Color catColor;
          switch (controller.selectedCategory.value?.name) {
            case "Raw Materials":
              catColor = Colors.blueAccent;
              break;
            case "Finished Goods":
              catColor = Colors.green;
              break;
            case "Scrap":
              catColor = Colors.redAccent;
              break;
            default:
              catColor = Colors.grey;
          }
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      e.category == "Scrap" ?
                      "Scrap ${e.scrap_grade}"  :
                     e.prod_name ?? "-",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      e.category ?? "-",
                      style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip("Gross $gross kg", Colors.orange),
                      _chip("Tare $tare kg", Colors.blueGrey),
                      _chip("Net $net kg", Colors.green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("GRN: ${controller.grnNumber} | Order: ${controller.orderNumber}"),
                  const SizedBox(height: 4),
                  // Text(
                  //   "⏱ ${DateTime.parse(e['timestamp']).toLocal()}",
                  //   style: const TextStyle(color: Colors.grey, fontSize: 12),
                  // ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _chip(String text, Color color) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/constants/sizes.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/widgets/customAppBar.dart';

class TryPrinterPage extends StatelessWidget {
  TryPrinterPage({super.key});
  final dash_controller = Get.put(DashboardController());
  final controller = Get.put(TryPrinterController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hi Energy Wires',
        showScale: false,
        showPrinter: true,
        showUser: false,
        showDrawer: false,
      ),
      body: Container(
        padding: Dimens.edgeInsets10,
        child: Column(
          children: [
            Form(
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.spool,
                    decoration: InputDecoration(
                      labelText: 'Spool No :',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Dimens.boxHeight10,
                  TextFormField(
                    controller: controller.dpcSize,
                    decoration: InputDecoration(
                      labelText: 'DPC Size :',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Dimens.boxHeight10,
                  TextFormField(
                    controller: controller.gross,
                    decoration: InputDecoration(
                      labelText: 'Gross Weight :',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value){
                      controller.grossWeight.value = double.tryParse(controller.gross.text) ?? 0.0;
                      controller.calculateNet();
                    },
                  ),
                  Dimens.boxHeight10,
                  TextFormField(
                    controller: controller.tare,
                    decoration: InputDecoration(
                      labelText: 'Tare Weight :',
                      border: OutlineInputBorder(),

                    ),
                    onChanged: (value){
                      controller.tareWeight.value = double.tryParse(controller.tare.text) ?? 0.0;
                      controller.calculateNet();
                    },
                  ),
                  Dimens.boxHeight10,
                  TextFormField(
                    controller: controller.net,
                    decoration: InputDecoration(
                      labelText: 'Net Weight :',
                      enabled: false,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.printSticker();
        },
        icon: Icon(Icons.add_circle, color: Colors.white),
        backgroundColor: ColorsValue.primaryColor,
        label: Text('Print Label', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class TryPrinterController extends GetxController {
  final dash_controller = Get.find<DashboardController>();
  var date_today = ''.obs;
  @override
  void onInit() {
    super.onInit();

    // Format: DD-MM-YYYY
    date_today.value = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }
  TextEditingController dpcSize = TextEditingController();
  TextEditingController spool = TextEditingController();
  TextEditingController gross = TextEditingController();
  TextEditingController tare = TextEditingController();
  TextEditingController net = TextEditingController();
  RxDouble grossWeight = RxDouble(0.0);
  RxDouble tareWeight = RxDouble(0.0);
  RxDouble netWeight = RxDouble(0.0);
  void calculateNet(){
    netWeight.value = grossWeight.value - tareWeight.value;
    net.text = netWeight.value.toString();
  }
  void printSticker() {
    // dash_controller.printNewSticker(
    //   date: date_today.value,
    //   spoolno: spool.text,
    //   dpcsize: dpcSize.text,
    //   gross: gross.text,
    //   tare: tare.text,
    //   net: net.text,
    //   barcode: '123456'
    // );
  }
}

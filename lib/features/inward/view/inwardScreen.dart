import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/features/inward/batchWise/models/batchList.dart';

import 'package:punit_label/features/inward/batchWise/batchInwardScreen.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchInwardScreen.dart';
import 'package:punit_label/widgets/customAppBar.dart';

import '../../../widgets/customDrawer.dart';
import '../controller/inwardController.dart';
import '../nonBatchWise/nonBatchListScreen.dart';



class InwardScreen extends StatelessWidget {
  InwardScreen({super.key});

  final controller = Get.put(InwardController());

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: CustomAppBar(
        title: 'INWARD',
        showScale: false,
        showPrinter: false,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 20 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Select Batch", isTablet),
            SizedBox(height: isTablet ? 14 : 10),

            Expanded(
              child: Obx((){
                if(controller.initLoading.value){
                    return Container(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator());
                }
                else if(controller.batchList.isEmpty){
                  return Center(child: Text('No Batch Found'),);
                }
                return ListView.separated(
                  itemCount: controller.batchList.length,
                  separatorBuilder: (_, __) => SizedBox(height: isTablet ? 12 : 10),
                  itemBuilder: (context, index) {
                    var data = controller.batchList[index];
                    return GestureDetector(
                      onTap: () => Get.to(()=>BatchInwardScreen(selectedBatchId: data.id.toString(),)),
                      child: _batchTile(index, isTablet,data),
                    );
                  },
                );
              })
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ColorsValue.primaryColor,
        onPressed: () => Get.to(()=>NonBatchListScreen()),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Non Batch Wise Inward',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TILE UI
  // =========================================================
  Widget _batchTile(int index, bool isTablet, batch batchData) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 14,
          vertical: isTablet ? 16 : 12,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: isTablet ? 26 : 22,
              backgroundColor: ColorsValue.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.inventory_2_rounded,
                color: ColorsValue.primaryColor,
                size: isTablet ? 28 : 22,
              ),
            ),

            SizedBox(width: isTablet ? 18 : 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batchData.batchName ?? 'Batch-Name',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  // SizedBox(height: 4),
                  // Text(
                  //   ,
                  //   style: TextStyle(
                  //     fontSize: isTablet ? 14 : 12,
                  //     color: Colors.grey.shade600,
                  //   ),
                  // ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              size: isTablet ? 30 : 24,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SECTION HEADER
  // =========================================================
  Widget _sectionHeader(String title, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Container(
          height: 3,
          width: isTablet ? 70 : 50,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        )
      ],
    );
  }
}


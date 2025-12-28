import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/constants/utility.dart';
import 'package:punit_label/features/dispatch/view/dispatchScreen.dart';
import 'package:punit_label/features/inward/view/inwardScreen.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import '../../constants/styles.dart';
import '../../widgets/customDrawer.dart';
import '/constants/colors.dart';
import '/constants/sizes.dart';
import '/features/bluetooth/bluetoothController.dart';
import '/features/dashboard/dashboardController.dart';
import '/navigation/appPages.dart';
import '/widgets/bluetooth_bottomsheet.dart';

class DashBoardView extends StatelessWidget {
  DashBoardView({super.key});
  final dash = Get.put(DashboardController());
  @override
  Widget build(BuildContext context) {

    final today = DateFormat('dd MMM yyyy').format(DateTime.now());
    final width = MediaQuery.of(context).size.width;

    final bool isTablet = width > 600;
    final int gridCount = width > 900 ? 4 : (isTablet ? 3 : 2);

    return Scaffold(
      backgroundColor: ColorsValue.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: "Dashboard",
        showScale: false,
        showPrinter: false,
        showUser: true,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await dash.getDashboardDetails(),
          child: ListView(
            //crossAxisAlignment: CrossAxisAlignment.start,
            physics: const AlwaysScrollableScrollPhysics(), // ✅ important
            padding: Dimens.edgeInsets10,
            children: [
              // ============================
              // DATE HEADER
              // ============================
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 14),
                decoration: BoxDecoration(
                  color: ColorsValue.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  today,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 28 : 20),


              Row(
                children: [
                  _statCard(
                    "Inward",
                    "12",
                    Icons.keyboard_double_arrow_down,
                    ColorsValue.primaryGrey,
                    isTablet,
                    onTap: (){
                      if(dash.enableInward.value){
                      Get.to(() => InwardScreen());}else{
                        Utility.showDialog('Access Denied');
                      }},
                  ),
                  SizedBox(width: 12),
                  _statCard(
                    "Dispatch",
                    "7",
                    Icons.keyboard_double_arrow_up,
                    Colors.green,
                    isTablet,
                    onTap: (){
                      if(dash.enableDispatch.value){
                        Get.to(() => DispatchScreen());}else{
                        Utility.showDialog('Access Denied');
                      }},
                  ),
                ],
              ),

              SizedBox(height: isTablet ? 26 : 20),

              // ============================
              // INVENTORY TITLE
              // ============================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Inventory",
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Obx(
                    () => Text(
                      "${dash.dashboardDetails.value?.data?.totalInventory} Kg",
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14),
              // ============================
              // FILTER CHIPS
              // ============================
              _filterChips(),

              SizedBox(height: 20),

              // ============================
              // INVENTORY GRID
              // ============================
              Obx(() {
                List<dynamic> listToShow = [];

               if (dash.selectedFilter.value == "top") {
                  listToShow = dash.topProducts;
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: listToShow.length,
                    itemBuilder: (_, i) {
                      var p = listToShow[i];
                      return _inventoryCard(
                        title: p.productName ?? "",
                        qty: double.tryParse(p.qty ?? "0") ?? 0,
                        icon: Icons.grade_sharp,
                        color: ColorsValue.primaryColor,
                        isTablet: isTablet,
                      );
                    },
                  );
                } else {
                  listToShow = dash.lowStockProducts;
                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: listToShow.length,

                    itemBuilder: (_, i) {
                      var p = listToShow[i];
                      return _inventoryCard(
                        title: p.productName ?? "",
                        qty: double.tryParse(p.qty ?? "0") ?? 0,
                        icon: Icons.priority_high,
                        color: ColorsValue.liked,
                        isTablet: isTablet,
                      );
                    },
                  );
                }
              })

            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STATS CARD
  // =========================================================
  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isTablet, {
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: ColorsValue.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
            child: Column(
              children: [
                Icon(icon, color: color, size: isTablet ? 40 : 35),
                SizedBox(height: isTablet ? 10 : 5 ),
                // Text(
                //   value,
                //   style: TextStyle(
                //     fontSize: isTablet ? 26 : 20,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // SizedBox(height: 4),
                Text(
                  title,
                  style: Styles.whiteBold22
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FILTER CHIPS
  // =========================================================
  Widget _filterChips() {
    return Obx(() {
      return Wrap(
        spacing: 10,
        children: [

          ChoiceChip(
            label: Text("Top Products"),
            selected: dash.selectedFilter.value == "top",
            onSelected: (v) => dash.selectedFilter.value = "top",
          ),

          ChoiceChip(
            label: Text("Low Stock"),
            selected: dash.selectedFilter.value == "low",
            onSelected: (v) => dash.selectedFilter.value = "low",
          ),

        ],
      );
    });
  }


  // =========================================================
  // INVENTORY CARD
  // =========================================================
  Widget _inventoryCard({
    required String title,
    double? qty,
    required IconData icon,
    required Color color,
    required bool isTablet,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: 14), // card spacing
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 18 : 14,
        horizontal: isTablet ? 18 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ---------------- ICON ----------------
          CircleAvatar(
            radius: isTablet ? 30 : 26,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, size: isTablet ? 30 : 22, color: color),
          ),

          SizedBox(width: isTablet ? 20 : 14),

          // ---------------- TITLE + QTY ----------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),

                if (qty != null) ...[
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Qty: ${qty.toStringAsFixed(2)} KG",
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

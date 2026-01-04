import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/sizes.dart';
import '../constants/utility.dart';
import '../features/inward/batchWise/models/batchDetails.dart';

class CustomTitle extends StatelessWidget {
  const CustomTitle({super.key, required this.title, required this.titleAlign});
  final String title;
  final TextAlign? titleAlign;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 600;
    return Padding(
      padding: Dimens.edgeInsets10_5_10_5,
      child: Text(
        title,
        textAlign: titleAlign,
        style: TextStyle(
          fontSize: isTablet ? 18 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ProductInfoCard extends StatelessWidget {
  final String productName;
  final List<Combinations> combinations;
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
            return GestureDetector(
              onTap: () {
                if (isClickable) {
                  c.isPrintable.value = !c.isPrintable.value;
                }
              },
              child: Container(
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
                    // Only this part rebuilds on change
                    if (isClickable)
                      Obx(
                        () => Row(
                          children: [
                            Icon(
                              c.isPrintable.value
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: isTablet ? 25 : 20,
                              color: c.isPrintable.value
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            SizedBox(width: 6),
                          ],
                        ),
                      ),

                    Text(
                      "${c.attrName}: ${c.attrValue}",
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class AppDropdownField extends StatelessWidget {
  final String hint;
  final bool isTablet;

  const AppDropdownField({
    super.key,
    required this.hint,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14),
      height: isTablet ? 54 : 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, size: isTablet ? 32 : 26),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isTablet;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 22 : 14,
            vertical: isTablet ? 14 : 10,
          ),
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Icon(icon, size: isTablet ? 40 : 30, color: color),
        ),
      ),
    );
  }
}

class InwardListItem extends StatelessWidget {
  final Barcodes product;
  final bool isTablet;
  // final VoidCallback? onTap;

  const InwardListItem({
    Key? key,
    required this.product,
    required this.isTablet,
    //this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasTare = product.isTareWeight.toString() == 'true';

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
                // Product Name - Professional Typography
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    product.serialNo == null ? SizedBox.shrink() :
                    Text(
                       product.serialNo.toString() + " | ",
                      style: TextStyle(
                        fontSize: isTablet ? 19 : 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Colors.grey[850],
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.batchProductName ?? "Unknown Product",
                      style: TextStyle(
                        fontSize: isTablet ? 19 : 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Colors.grey[850],
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    product.unitConversion == true
                        ? Text(
                            "Units : ${product.units}" ?? "Total Units",
                            style: TextStyle(
                              fontSize: isTablet ? 19 : 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: Colors.green,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : SizedBox.shrink(),
                  ],
                ),

               Dimens.boxHeight5,
                product.time == "" ? SizedBox.shrink() :
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    Dimens.boxWidth5,
                    Text(
                      // Utility.formatTimestamp(product.time),
                      product.time ?? DateTime.now().toIso8601String(),
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
               Dimens.boxHeight5,

                // Weight Chips - Elevated Design
                Wrap(
                  spacing: 10,
                  runSpacing: 9,
                  children: [
                    if (hasTare)
                      _buildWeightChip(
                        label: "Gross",
                        value: "${product.grossWeight} kg",
                        color: const Color(0xFF2196F3), // Material Blue
                        icon: Icons.scale,
                      ),
                    if (hasTare)
                      _buildWeightChip(
                        label: "Tare",
                        value: "${product.tareWeight} kg",
                        color: const Color(0xFFFF9800), // Material Orange
                        icon: Icons.line_weight,
                      ),
                    _buildWeightChip(
                      label: "Net",
                      value: "${product.netWeight} kg",
                      color: const Color(0xFF4CAF50), // Material Green
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

  Widget _buildWeightChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      /* decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),*/
      child: Row(
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
              letterSpacing: 0.4,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20 : 15,
              fontWeight: FontWeight.w900,
              color: Colors.grey[850],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

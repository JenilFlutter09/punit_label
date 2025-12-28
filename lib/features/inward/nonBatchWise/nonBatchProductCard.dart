import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchController.dart';

import 'models/nonBatchInwardModel.dart';

class NonBatchProductCard extends StatelessWidget {
  final NonBatchProducts product;
  final bool isTablet;
  final NonBatchInwardController controller;

  const NonBatchProductCard({
    super.key,
    required this.product,
    required this.isTablet,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleRow(),
              const SizedBox(height: 12),
              if (product.attributes != null && product.attributes!.isNotEmpty)
                _buildAttributeChips(),

              const SizedBox(height: 10),

              _buildBarcodeHeader(),
              const SizedBox(height: 8),

              if (product.barcodes != null)
                ...product.barcodes!.map(
                  (b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Dismissible(
                      key: ValueKey(b.barCodeString),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        color: Colors.redAccent,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (direction) {
                        // 🧨 Notify controller to remove barcode

                        controller.deleteBarcode(product, b);
                      },
                      child: _BarcodeCard(
                        barcode: b,
                        isTablet: isTablet,
                        index: product.productName ?? 'Product Name',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------------------------------------------------
  /// 🔥 PRODUCT TITLE ROW
  /// ---------------------------------------------------------
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            product.productName ?? "Unknown Product",
            style: TextStyle(
              fontSize: isTablet ? 19 : 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: Colors.grey[850],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "x${product.barcodes?.length ?? 0}",
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade800,
            ),
          ),
        ),
      ],
    );
  }

  /// ---------------------------------------------------------
  /// 🔥 ATTRIBUTE CHIPS
  /// ---------------------------------------------------------
  Widget _buildAttributeChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: product.attributes!.map((attr) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.label_important,
                size: 15,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                "${attr.attributeName}: ",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                attr.optionName ?? "",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// ---------------------------------------------------------
  /// 🔥 "Barcode Entries" Header
  /// ---------------------------------------------------------
  Widget _buildBarcodeHeader() {
    return Text(
      "Barcode Entries",
      style: TextStyle(
        fontSize: isTablet ? 17 : 15,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
      ),
    );
  }
}

/// =================================================================
/// 🔥 REUSABLE BARCODE CARD WIDGET
/// =================================================================
class _BarcodeCard extends StatelessWidget {
  final NonBatchBarcodes barcode;
  final bool isTablet;
  final String index;
  const _BarcodeCard({
    required this.barcode,
    required this.isTablet,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final hasTare = barcode.tareWeightEnable == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(index),
            const SizedBox(height: 12),
            _weights(hasTare),
          ],
        ),
      ),
    );
  }

  // Widget _header(String index) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(
  //         index,
  //         style: TextStyle(
  //           fontSize: isTablet ? 18 : 16,
  //           fontWeight: FontWeight.w800,
  //         ),
  //       ),
  //       Icon(Icons.qr_code, color: Colors.grey.shade700, size: 20),
  //     ],
  //   );
  // }

  Widget _header(String index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),

              /// 🕒 Timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatTimestamp(barcode.time),
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Icon(
          Icons.qr_code,
          color: Colors.grey.shade700,
          size: 22,
        ),
      ],
    );
  }

  String formatTimestamp(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  }


  Widget _weights(bool hasTare) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: [
        _weightChip(
          label: "Gross",
          value: "${barcode.grossWeight} kg",
          color: const Color(0xFF2196F3),
          icon: Icons.scale,
        ),
        if (hasTare)
          _weightChip(
            label: "Tare",
            value: "${barcode.tareWeight} kg",
            color: const Color(0xFFFF9800),
            icon: Icons.line_weight,
          ),
        _weightChip(
          label: "Net",
          value: "${barcode.netWeight} kg",
          color: const Color(0xFF4CAF50),
          icon: Icons.balance,
        ),
      ],
    );
  }

  Widget _weightChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w900,
              color: Colors.grey[850],
            ),
          ),
        ],
      ),
    );
  }
}

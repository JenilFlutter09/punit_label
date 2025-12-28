import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportHelper {
  static List<String> calculateTotals(List<List<String>> data) {
    int totalItems = data.length;

    double grossTotal = 0;
    double tareTotal = 0;
    double netTotal = 0;

    for (var row in data) {
      grossTotal += _extractNumber(row[2]); // Gross
      tareTotal += _extractNumber(row[3]);  // Tare
      netTotal += _extractNumber(row[4]);   // Net
    }

    return [
      "Total",
      "$totalItems Items",
      "${grossTotal.toStringAsFixed(2)} kg",
      "${tareTotal.toStringAsFixed(2)} kg",
      "${netTotal.toStringAsFixed(2)} kg",
    ];
  }

  /// Removes "kg" / " KG " and parses safely
  static double _extractNumber(String value) {
    return double.tryParse(
        value.replaceAll("kg", "").replaceAll("KG", "").replaceAll(" ", "")
    ) ?? 0.0;
  }

  /// Main export chooser
  static Future<void> exportReport({
    required BuildContext context,
    required String titlePdf,
    required String titleExcel,

    /// 🔸 Dynamic metadata key–value pairs (e.g. {"Order No": "123", "Client": "ABC Ltd"})
    required Map<String, String> metaData,

    /// 🔸 Table structure
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final List<List<String>> updatedData = [...data];
    // Append the final totals row
    updatedData.add(calculateTotals(data));
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text("Export as PDF"),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _generatePDF(
                    title: titlePdf,
                    metaData: metaData,
                    headers: headers,
                    data: updatedData,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PDF file saved successfully!")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text("Export as Excel"),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _generateExcel(
                    title: titleExcel,
                    metaData: metaData,
                    headers: headers,
                    data: updatedData,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Excel file saved successfully!")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  static Future<void> exportHorizontalClientPDF({
    required BuildContext context,
    required String title,
    required Map<String, String> metaData,
    required List<dynamic> items, // barcodeList
  }) async {

    final pdf = pw.Document();

    double totalWeight = 0;

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {

          final horizontalWidgets = <pw.Widget>[];

          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final weight = double.tryParse(item.netWeight.toString()) ?? 0;
            totalWeight += weight;

            horizontalWidgets.add(
              pw.Container(
                width: 180,
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.only(right: 8, bottom: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.8),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Sr: ${i + 1}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text("Item: ${item.productName}",
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip),
                    pw.SizedBox(height: 4),
                    pw.Text("Weight: ${item.netWeight} kg",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        )),
                  ],
                ),
              ),
            );
          }

          return [
            /// 🏷 Title
            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            /// 🧾 Meta Data
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: metaData.entries.map((e) {
                return pw.Text(
                  "${e.key}: ${e.value}",
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.grey700,
                  ),
                );
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            /// 🔁 Horizontal Flow Layout
            pw.Wrap(
              children: horizontalWidgets,
            ),

            pw.SizedBox(height: 30),

            /// 🔻 Totals Section (Separate)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
                color: PdfColors.grey200,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Total Items: ${items.length}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Total Weight: ${totalWeight.toStringAsFixed(2)} kg",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final outputDir = Directory("/storage/emulated/0/Download");
    final file = File("${outputDir.path}/$title-horizontal.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Horizontal PDF saved successfully")),
    );
  }

  /// 🔹 Generate Dynamic PDF
  static Future<void> _generatePDF({
    required String title,
    required Map<String, String> metaData,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // 🏷 Title
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // 🧾 Dynamic metadata section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: metaData.entries.map((entry) {
              return pw.Text(
                "${entry.key}: ${entry.value}",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              );
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // 📋 Table
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            border: pw.TableBorder.all(width: 0.5),
            cellHeight: 25,
            cellAlignments: {
              for (var i = 0; i < headers.length; i++) i: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    final outputDir = Directory("/storage/emulated/0/Download");
    final filePath = "${outputDir.path}/$title.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    print("✅ PDF saved at: $filePath");
  }

  /// 🔹 Generate Dynamic Excel
  static Future<void> _generateExcel({
    required String title,
    required Map<String, String> metaData,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[title];

    // Add main title
    sheet.appendRow([TextCellValue(title)]);
    sheet.appendRow([]); // spacing

    // 🧾 Dynamic metadata rows
    metaData.forEach((key, value) {
      sheet.appendRow([TextCellValue("$key: $value")]);
    });

    sheet.appendRow([]); // spacing before table

    // Add headers
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Add rows
    for (var row in data) {
      sheet.appendRow(row.map((cell) => TextCellValue(cell)).toList());
    }

    final outputDir = Directory("/storage/emulated/0/Download");
    final file = File("${outputDir.path}/$title.xlsx");
    await file.writeAsBytes(excel.encode()!);
    print("✅ Excel saved at: ${file.path}");
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../features/dispatch/models/dispatchBarcodes.dart';

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
                  await generatePDF(
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
                  await generateExcel(
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

  static List<List<Dispatchbarcodes>> chunk(List<Dispatchbarcodes> list, int size) {
    final chunks = <List<Dispatchbarcodes>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }
  static Future<void> exportHorizontalClientPDF({
    required BuildContext context,
    required String title,
    required Map<String, String> metaData,
    required List<Dispatchbarcodes> items,
  }) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/images/splash.jpeg');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    // 🔹 Group product-wise
    final Map<String, List<Dispatchbarcodes>> grouped = {};
    for (final item in items) {
      final key = item.productName ?? 'Unknown Product';
      grouped.putIfAbsent(key, () => []).add(item);
    }


    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          final widgets = <pw.Widget>[];
          final now = DateTime.now();

          widgets.add(
            buildCompanyHeader(
              logo: logoImage, // or null if not using image
              slipNo: "720725",
              invoiceNo: "INV-${now.microsecondsSinceEpoch}",
              date: now,
            ),
          );

          widgets.add(pw.SizedBox(height: 12));

          // /// 🏷 HEADER
          // widgets.add(
          //   pw.Center(
          //     child: pw.Text(
          //       title,
          //       style: pw.TextStyle(
          //         fontSize: 18,
          //         fontWeight: pw.FontWeight.bold,
          //       ),
          //     ),
          //   ),
          // );
          //
          //
          // widgets.add(pw.SizedBox(height: 8));
          //
          // widgets.add(
          //   pw.Column(
          //     crossAxisAlignment: pw.CrossAxisAlignment.start,
          //     children: metaData.entries
          //         .map(
          //           (e) => pw.Text(
          //         "${e.key} : ${e.value}",
          //         style: const pw.TextStyle(fontSize: 10),
          //       ),
          //     )
          //         .toList(),
          //   ),
          // );
          //
          // widgets.add(pw.SizedBox(height: 12));

          /// 🔁 PRODUCT SECTIONS
          grouped.forEach((productName, productItems) {
            double productWeight = 0;

            for (final e in productItems) {
              productWeight += e.netWeight ?? 0;
            }

            /// 🔹 Product title row
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      productName,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Count : ${productItems.length}   KG : ${productWeight.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );

            /// 🔹 Barcode grid
            final rows = chunk(productItems, 5);
            int sr = 1;

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  for (int i = 0; i < 10; i++)
                    i: const pw.FlexColumnWidth(1),
                },
                children: rows.map((row) {
                  final cells = <pw.Widget>[];

                  for (final item in row) {
                    cells.add(
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          "${sr++}) ${item.barCodeString ?? ''}",
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    );

                    cells.add(
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          "${(item.netWeight ?? 0).toStringAsFixed(2)} kg",
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    );
                  }

                  /// fill empty cells
                  while (cells.length < 10) {
                    cells.add(pw.Container());
                  }

                  return pw.TableRow(children: cells);
                }).toList(),
              ),
            );

            widgets.add(pw.SizedBox(height: 14));
          });

          /// 🔻 FOOTER
          widgets.add(
            pw.Center(
              child: pw.Text(
                "generated from weighing system by https://pinnacle.punitinstrument.com",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ),
          );

          return widgets;
        },
      ),
    );


    final dir = Directory("/storage/emulated/0/Download");
    final file = File("${dir.path}/$title.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Packing slip PDF saved")),
    );
  }

  static pw.Widget buildCompanyHeader({
    pw.ImageProvider? logo,
    required String slipNo,
    required String invoiceNo,
    required DateTime date,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          /// 🔹 LEFT (Logo)
          if (logo != null)
            pw.Container(
              width: 60,
              height: 60,
              child: pw.Image(logo),
            ),

          if (logo != null) pw.SizedBox(width: 8),

          /// 🔹 CENTER (Company Details)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  "SURYA SALES CORPORATION",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  "Distributors For: AGARAWAL & SUKI PLUMBING SOLUTIONS",
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "D. No : 5-2-365, Hyderbasthi, Ranigunj, Secunderabad - 03",
                  style: pw.TextStyle(fontSize: 9, ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "Ph : 27541220, 66901225, 66901221",
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "Email : accounts@sukindia.com",
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 8),

          /// 🔹 RIGHT (Slip Info Box)
          pw.Container(
            width: 140,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide()),
                  ),
                  child: pw.Text(
                    "Packing Slip",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text("Slip No : $slipNo", style: pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    "Date : ${DateFormat('dd/MM/yyyy  HH:mm:ss').format(date)}",
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child:
                  pw.Text("Invoice No : $invoiceNo", style: pw.TextStyle(fontSize: 9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Generate Dynamic PDF
  static Future<void> generatePDF({
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
  static Future<void> generateExcel({
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

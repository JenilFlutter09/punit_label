import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:punit_label/constants/utility.dart';

import '../features/dispatch/models/dispatchBarcodes.dart';

class ExportHelper {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.punitinstrument.punitlabel/downloads',
  );

  static List<String> calculateTotals(List<List<String>> data) {
    int totalItems = data.length;

    double grossTotal = 0;
    double tareTotal = 0;
    double netTotal = 0;

    for (var row in data) {
      grossTotal += _extractNumber(row[2]); // Gross
      tareTotal += _extractNumber(row[3]); // Tare
      netTotal += _extractNumber(row[4]); // Net
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
          value.replaceAll("kg", "").replaceAll("KG", "").replaceAll(" ", ""),
        ) ??
        0.0;
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
                    const SnackBar(
                      content: Text("PDF file saved successfully!"),
                    ),
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
                    const SnackBar(
                      content: Text("Excel file saved successfully!"),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static List<List<Dispatchbarcodes>> chunk(
    List<Dispatchbarcodes> list,
    int size,
  ) {
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
    required String? email,
    required Map<String, String> metaData,

    required List<Dispatchbarcodes> items,
  }) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/images/sukiLogo.jpeg');
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
                decoration: pw.BoxDecoration(border: pw.Border.all()),
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
                  for (int i = 0; i < 10; i++) i: const pw.FlexColumnWidth(1),
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
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
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
    //    final dir = await getDownloadDirectory();
    final file = File("${dir.path}/$title.pdf");
    //await file.writeAsBytes(await pdf.save());
    try {
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("PDF saved at ${file.path}")));
      // Utility.sharePdfFile(file.path);
      await sendPdfEmail(
        filePath: file.path,
        sendingEmail: email ?? 'shahjenil9977@gmail.com',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save PDF: $e")));
    }

    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text("Custom PDF saved")),
    // );
  }

  // ignore: non_constant_identifier_names
  static Future<void> modern_flex_packing_list({
    required String title,
    required Map<String, String> metaData,
    required List<Dispatchbarcodes> items,
    String? email,
    String companyName = 'MODERN FLEX PACKING LIST',
    String companyAddress = 'Generated from weighing system',
    String companyPhone = 'https://pinnacle.punitinstrument.com',
    String companyEmail = '',
    String companyGst = '',
    String companyWebsite = '',
    String listTitle = 'Packing List',
    int maxRowsPerGrid = 27,
    VoidCallback? onBeforeResultDialogShown,
  }) async {
    final pdf = pw.Document();
    final generatedAt = DateTime.now();
    final rowsPerSection = maxRowsPerGrid * 2;

    final grouped = <String, List<Dispatchbarcodes>>{};
    final groupLabels = <String, ({String productName, String structure})>{};

    for (final item in items) {
      final productName = item.productName?.trim().isNotEmpty == true
          ? item.productName!.trim()
          : 'Unknown Product';
      final structure = _variationText(item);
      final key = '$productName||$structure';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
      groupLabels[key] = (productName: productName, structure: structure);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 30),
        footer: (context) => _modernFlexFooter(
          generatedAt: generatedAt,
          pageNumber: context.pageNumber,
          pagesCount: context.pagesCount,
        ),
        build: (context) {
          final widgets = <pw.Widget>[
            _modernFlexHeader(
              companyName: companyName,
              companyAddress: companyAddress,
              companyPhone: companyPhone,
              companyEmail: companyEmail,
              companyGst: companyGst,
              companyWebsite: companyWebsite,
              listTitle: listTitle,
            ),
          ];

          if (items.isEmpty) {
            widgets.add(pw.SizedBox(height: 18));
            widgets.add(
              pw.Center(
                child: pw.Text(
                  'No dispatch items available',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            return widgets;
          }

          var globalSerial = 1;

          grouped.forEach((key, productItems) {
            final labels = groupLabels[key]!;
            final productTotals = _dispatchTotals(productItems);

            for (
              var start = 0;
              start < productItems.length;
              start += rowsPerSection
            ) {
              final end = start + rowsPerSection > productItems.length
                  ? productItems.length
                  : start + rowsPerSection;
              final sectionItems = productItems.sublist(start, end);
              final splitIndex = (sectionItems.length / 2).ceil();
              final leftItems = sectionItems.sublist(0, splitIndex);
              final rightItems = sectionItems.sublist(splitIndex);
              final isContinuation = start > 0;
              final leftStartSerial = globalSerial;
              final rightStartSerial = globalSerial + leftItems.length;

              widgets.add(pw.SizedBox(height: 12));
              widgets.add(
                _modernFlexProductHeader(
                  metaData: metaData,
                  title: title,
                  productName: labels.productName,
                  structure: labels.structure,
                  count: productItems.length,
                  totals: productTotals,
                  isContinuation: isContinuation,
                ),
              );
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _modernFlexGrid(
                        items: leftItems,
                        startSerial: leftStartSerial,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: _modernFlexGrid(
                        items: rightItems,
                        startSerial: rightStartSerial,
                      ),
                    ),
                  ],
                ),
              );

              globalSerial += sectionItems.length;
            }
          });

          widgets.add(pw.SizedBox(height: 14));
          widgets.add(
            _modernFlexTotals(_dispatchTotals(items), totalCount: items.length),
          );
          return widgets;
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await _savePdfBytesToDownloads(fileName: '$title.pdf', bytes: pdfBytes);
    final emailFilePath = await _writeTemporaryPdfFile(
      fileName: '$title.pdf',
      bytes: pdfBytes,
    );

    final recipientEmail = email?.trim();
    if (recipientEmail == null || recipientEmail.isEmpty) {
      onBeforeResultDialogShown?.call();
      await Utility.showDialog(
        'Pdf saved, but no recipient email is configured.',
      );
      return;
    }

    await sendPdfEmail(
      filePath: emailFilePath,
      sendingEmail: recipientEmail,
      onBeforeResultDialogShown: onBeforeResultDialogShown,
    );
  }

  static Future<void> _savePdfBytesToDownloads({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (Platform.isAndroid) {
      await _downloadsChannel.invokeMethod<String>('savePdfToDownloads', {
        'fileName': fileName,
        'bytes': bytes,
      });
      return;
    }

    final dir = await getDownloadDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
  }

  static Future<String> _writeTemporaryPdfFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static pw.Widget _modernFlexHeader({
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    required String companyGst,
    required String companyWebsite,
    required String listTitle,
  }) {
    final detailLines = [
      companyAddress,
      if (companyPhone.trim().isNotEmpty) 'Contact: $companyPhone',
      if (companyEmail.trim().isNotEmpty) 'Email: $companyEmail',
      if (companyGst.trim().isNotEmpty) 'GST: $companyGst',
      if (companyWebsite.trim().isNotEmpty) 'Website: $companyWebsite',
    ].where((line) => line.trim().isNotEmpty).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  ...detailLines.map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        line,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.Text(
              listTitle,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: PdfColors.black),
      ],
    );
  }

  static pw.Widget _modernFlexProductHeader({
    required Map<String, String> metaData,
    required String title,
    required String productName,
    required String structure,
    required int count,
    required ({double gross, double tare, double net, double converted}) totals,
    required bool isContinuation,
  }) {
    final customerName = metaData['Customer Name'] ?? 'Customer';
    final batchId = metaData['Batch ID'] ?? metaData['Dispatch No'] ?? title;
    final structureText = structure.trim();
    final displayProductName = isContinuation
        ? '$productName (continued)'
        : productName;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _modernFlexInfoLine('Customer Name', customerName),
                  pw.SizedBox(height: 4),
                  _modernFlexInfoLine('Product Name', displayProductName),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Container(
              width: 190,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _modernFlexInfoLine('Batch ID', batchId),
                  if (structureText.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      structureText,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Count : $count',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Gross : ${totals.gross.toStringAsFixed(2)}   '
              'Tare : ${totals.tare.toStringAsFixed(2)}   '
              'Net : ${totals.net.toStringAsFixed(2)}   '
              'Conv : ${totals.converted.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Container(height: 0.8, color: PdfColors.black),
      ],
    );
  }

  static pw.Widget _modernFlexInfoLine(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label :  ',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _modernFlexGrid({
    required List<Dispatchbarcodes> items,
    required int startSerial,
  }) {
    final border = pw.TableBorder(
      top: const pw.BorderSide(width: 0.7),
      bottom: const pw.BorderSide(width: 0.7),
      horizontalInside: const pw.BorderSide(width: 0.45),
    );

    return pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.78),
        1: pw.FlexColumnWidth(1.18),
        2: pw.FlexColumnWidth(1.05),
        3: pw.FlexColumnWidth(1.05),
        4: pw.FlexColumnWidth(1.16),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _modernFlexCell('Sr\nNo', bold: true),
            _modernFlexCell('Gross\nWt', bold: true),
            _modernFlexCell('Tare\nWt', bold: true),
            _modernFlexCell('Net\nWt', bold: true),
            _modernFlexCell('Conv Wt', bold: true),
          ],
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return pw.TableRow(
            children: [
              _modernFlexCell('${startSerial + index}'),
              _modernFlexCell(_weightText(item.grossWeight, showUnit: false)),
              _modernFlexCell(_weightText(item.tareWeight, showUnit: false)),
              _modernFlexCell(_weightText(item.netWeight, showUnit: false)),
              _modernFlexCell(_convertedWeightText(item)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _modernFlexCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8.8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _modernFlexTotals(
    ({double gross, double tare, double net, double converted}) totals, {
    required int totalCount,
  }) {
    pw.Widget totalLine(String label, String value) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 125,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            width: 115,
            padding: const pw.EdgeInsets.only(bottom: 2),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1.1)),
            ),
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        totalLine('Total Records :', totalCount.toString()),
        pw.SizedBox(height: 8),
        totalLine('Total Gross Wt :', totals.gross.toStringAsFixed(2)),
        pw.SizedBox(height: 8),
        totalLine('Total Tare Wt :', totals.tare.toStringAsFixed(2)),
        pw.SizedBox(height: 8),
        totalLine('Total Net Wt :', totals.net.toStringAsFixed(2)),
        pw.SizedBox(height: 8),
        totalLine('Total Converted Wt :', totals.converted.toStringAsFixed(2)),
      ],
    );
  }

  static pw.Widget _modernFlexFooter({
    required DateTime generatedAt,
    required int pageNumber,
    required int pagesCount,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          DateFormat('dd-MMM-yyyy').format(generatedAt),
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          DateFormat('HH:mm:ss').format(generatedAt),
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          'Page $pageNumber of $pagesCount',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static ({double gross, double tare, double net, double converted})
  _dispatchTotals(List<Dispatchbarcodes> items) {
    double gross = 0;
    double tare = 0;
    double net = 0;
    double converted = 0;

    for (final item in items) {
      gross += item.grossWeight ?? 0;
      tare += item.tareWeight ?? 0;
      net += item.netWeight ?? 0;
      converted += _convertedWeight(item);
    }

    return (gross: gross, tare: tare, net: net, converted: converted);
  }

  static String _weightText(double? value, {bool showUnit = true}) {
    final text = (value ?? 0).toStringAsFixed(2);
    return showUnit ? '$text KG' : text;
  }

  static double _convertedWeight(Dispatchbarcodes item) {
    if (item.unitConversion != true) return 0;

    final unitValue = double.tryParse((item.unit ?? '').trim());
    if (unitValue == null || unitValue <= 0) return 0;

    return (item.netWeight ?? 0) / unitValue;
  }

  static String _convertedWeightText(Dispatchbarcodes item) {
    return _convertedWeight(item).toStringAsFixed(2);
  }

  static String _variationText(Dispatchbarcodes item) {
    final variation = item.variation ?? [];
    final parts = variation
        .where((e) => e.optionName?.trim().isNotEmpty == true)
        .map((e) {
          final attribute = e.attributeName?.trim();
          final option = e.optionName!.trim();
          return attribute == null || attribute.isEmpty
              ? option
              : '$attribute: $option';
        })
        .toList();

    return parts.join(', ');
  }

  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      final downloadDir = Directory("${dir!.path}/Download");
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  static pw.Widget buildCompanyHeader({
    pw.ImageProvider? logo,
    required String slipNo,
    required String invoiceNo,
    required DateTime date,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          /// 🔹 LEFT (Logo)
          if (logo != null)
            pw.Container(width: 60, height: 60, child: pw.Image(logo)),

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
                  style: pw.TextStyle(fontSize: 9),
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
            decoration: pw.BoxDecoration(border: pw.Border.all()),
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
                  child: pw.Text(
                    "Slip No : $slipNo",
                    style: pw.TextStyle(fontSize: 9),
                  ),
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
                  child: pw.Text(
                    "Invoice No : $invoiceNo",
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Generate Dynamic PDF (With Product-wise Subtotals)
  static Future<void> generatePDF({
    required String title,
    required Map<String, String> metaData,
    required List<String> headers,
    required List<List<String>> data,
    String? email,
    VoidCallback? onBeforeResultDialogShown,
  }) async {
    final pdf = pw.Document();

    /// 🔹 Helper to parse weight
    double parseWeight(String value) {
      return double.tryParse(value.replaceAll("kg", "").trim()) ?? 0.0;
    }

    bool hasHiddenAttributeColumn(List<String> row) {
      return row.length == headers.length + 1;
    }

    List<String> buildVisibleRow(List<String> row) {
      if (!hasHiddenAttributeColumn(row)) {
        return List<String>.from(row);
      }

      return [row[0], row[1], ...row.skip(3)];
    }

    String getAttributeText(List<String> row) {
      if (!hasHiddenAttributeColumn(row)) {
        return "";
      }
      return row[2];
    }

    // /// 🔹 Group rows product-wise (Column index 1 = Product Name)
    // final Map<String, List<List<String>>> grouped = {};
    // for (var row in data) {
    //   final product = row[1];
    //   grouped.putIfAbsent(product, () => []);
    //   grouped[product]!.add(row);
    // }
    /// 🔹 Group rows by Product + Attribute combo
    final Map<String, List<List<String>>> grouped = {};

    for (var row in data) {
      final visibleRow = buildVisibleRow(row);
      final productName = row[1];
      final rawAttributeText = getAttributeText(row);
      final attributeText = rawAttributeText.isEmpty
          ? "No Attributes"
          : rawAttributeText;

      final key = "$productName||$attributeText";

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(visibleRow);
    }

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          List<pw.Widget> widgets = [];

          // 🔹 Title
          widgets.add(
            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 10));

          // 🔹 Metadata
          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: metaData.entries.map((entry) {
                return pw.Text(
                  "${entry.key}: ${entry.value}",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          double grandGross = 0;
          double grandTare = 0;
          double grandNet = 0;

          /// 🔹 Loop product-wise
          grouped.forEach((key, rows) {
            final parts = key.split("||");
            final productName = parts[0];
            final attributeText = parts.length > 1 ? parts[1] : "";
            double subGross = 0;
            double subTare = 0;
            double subNet = 0;

            // 🔹 Section Heading (Product + Attribute)
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    productName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (attributeText.isNotEmpty)
                    pw.Text(
                      attributeText,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 6));

            // 🔹 Table Header Row
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  for (int i = 0; i < headers.length; i++)
                    i: const pw.FlexColumnWidth(),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: headers.map((h) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),

                  /// 🔹 Product Rows
                  ...rows.map((row) {
                    subGross += row.length > 2 ? parseWeight(row[2]) : 0;
                    subTare += row.length > 3 ? parseWeight(row[3]) : 0;
                    subNet += row.length > 4 ? parseWeight(row[4]) : 0;
                    return pw.TableRow(
                      children: row.map((cell) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(cell, textAlign: pw.TextAlign.center),
                        );
                      }).toList(),
                    );
                  }),

                  /// 🔹 Subtotal Row (Styled)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: List.generate(headers.length, (index) {
                      String text = "";
                      pw.TextAlign textAlign = pw.TextAlign.left;

                      if (index == 1) {
                        text = "SUBTOTAL (${rows.length} items)";
                      } else if (index == 2) {
                        text = "${subGross.toStringAsFixed(2)} kg";
                        textAlign = pw.TextAlign.center;
                      } else if (index == 3) {
                        text = "${subTare.toStringAsFixed(2)} kg";
                        textAlign = pw.TextAlign.center;
                      } else if (index == 4) {
                        text = "${subNet.toStringAsFixed(2)} kg";
                        textAlign = pw.TextAlign.center;
                      }

                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          text,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: textAlign,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 18)); // 🔹 spacing between products

            grandGross += subGross;
            grandTare += subTare;
            grandNet += subNet;
          });

          /// 🔹 GRAND TOTAL
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                color: PdfColors.grey300,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "GRAND TOTAL",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    "Gross: ${grandGross.toStringAsFixed(2)} kg   "
                    "Tare: ${grandTare.toStringAsFixed(2)} kg   "
                    "Net: ${grandNet.toStringAsFixed(2)} kg",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    final outputDir = Directory("/storage/emulated/0/Download");
    final filePath = "${outputDir.path}/$title.pdf";
    final file = File(filePath);

    await file.writeAsBytes(await pdf.save());

    await sendPdfEmail(
      filePath: file.path,
      sendingEmail: email ?? 'shahjenil9977@gmail.com',
      onBeforeResultDialogShown: onBeforeResultDialogShown,
    );
  }

  static Future<void> sendPdfEmail({
    required String filePath,
    required String sendingEmail,
    VoidCallback? onBeforeResultDialogShown,
  }) async {
    const String username = 'jenilflutter@gmail.com'; // sender email
    const String appPassword = 'zaha xgeb fnwl szvw'; // Google App Password

    final smtpServer = gmail(username, appPassword);

    final message = Message()
      ..from = Address(username, 'Weighing System')
      ..recipients.add(sendingEmail) // designated email
      ..subject = 'Auto Generated Packing Slip'
      ..text = 'Packing slip generated automatically.'
      ..attachments = [FileAttachment(File(filePath))];

    try {
      print('📧 Sending packing slip email to: $sendingEmail');
      final sendReport = await send(message, smtpServer);
      print('✅ Email sent successfully: $sendReport');
      onBeforeResultDialogShown?.call();
      await Utility.showDialog('Pdf sent by email to $sendingEmail');
    } catch (e) {
      onBeforeResultDialogShown?.call();
      await Utility.showDialog(
        'Pdf saved, but email failed for $sendingEmail. Please check internet or SMTP credentials.',
      );
      print('❌ Email sending failed: $e');
    }
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

import 'dart:math' as math;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/static_label_preview_models.dart';

class SmallSevenStaticLabelPreview extends StatelessWidget {
  const SmallSevenStaticLabelPreview({
    super.key,
    required this.data,
    required this.scale,
  });

  final StaticLabelPreviewData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final layout = data.layout!;
    final left = 20.0;
    final right = data.width - 20.0;
    final headerLeft = left + 10;
    var yPos = 20.0;
    final children = <Widget>[];

    if (!data.isWhiteLabel) {
      if (data.companyName.trim().isNotEmpty) {
        children.add(_text(headerLeft, yPos, data.companyName, 40));
        yPos += 52;
      }
    }

    final dateX = right - 145;
    if (data.printTime) {
      children.add(_text(dateX, yPos, _dateText(), 20));
      children.add(_text(dateX, yPos + 24, _timeText(), 20));
    }

    final productY = yPos;
    children.add(_text(headerLeft, productY, data.productName, 30, true));
    yPos += data.printSerialNumber ? layout.lineHeight - 4 : layout.lineHeight;

    if (data.printSerialNumber && data.serialNumber.isNotEmpty) {
      children.add(_text(headerLeft, yPos, 'Sr No : ${data.serialNumber}', 20));
      yPos += 32;
    }

    final attrFont = 27.0;
    final attrLineHeight = math.max(attrFont + 6, 27.0);
    final columnSpacing = 20.0;
    final col1X = left + 10;
    final totalPrintableWidth = math.max((right - col1X), 200);
    final columnWidth = math.max(
      (totalPrintableWidth - columnSpacing) / 2,
      150,
    );
    final col2X = col1X + columnWidth + columnSpacing;
    final approxCharsPerLine = math.max(
      ((columnWidth * 2.2) / attrFont).floor(),
      10,
    );

    final items = data.attributes.take(10).toList();
    for (int i = 0; i < items.length; i += 2) {
      final first = items[i];
      final second = i + 1 < items.length ? items[i + 1] : null;
      final firstLines = _wrap(
        '${first.key} : ${first.value}',
        approxCharsPerLine,
      );
      final secondLines = second == null
          ? const <String>[]
          : _wrap('${second.key} : ${second.value}', approxCharsPerLine);

      for (int j = 0; j < firstLines.length; j++) {
        children.add(
          _text(col1X, yPos + (j * attrLineHeight), firstLines[j], attrFont),
        );
      }
      for (int j = 0; j < secondLines.length; j++) {
        children.add(
          _text(col2X, yPos + (j * attrLineHeight), secondLines[j], attrFont),
        );
      }

      final rowLines = math.max(firstLines.length, secondLines.length);
      yPos += math.max(rowLines, 1) * attrLineHeight;
    }

    final barcodeY =
        data.height - layout.bottomPadding - 28 - layout.barcodeHeight - 10;
    children.add(
      Positioned(
        left: (left + 25) * scale,
        top: barcodeY * scale,
        width: ((right - left) - 20) * scale,
        height: layout.barcodeHeight * scale,
        child: BarcodeWidget(
          barcode: Barcode.code128(),
          data: data.barcodeData,
          drawText: false,
        ),
      ),
    );

    return Container(
      color: const Color(0xFFFDFDFB),
      child: Stack(children: children),
    );
  }

  Widget _text(
    double x,
    double y,
    String text,
    num fontSize, [
    bool bold = false,
  ]) {
    return Positioned(
      left: x * scale,
      top: y * scale,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize.toDouble() * scale * 0.9,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }

  List<String> _wrap(String text, int maxChars) {
    if (text.trim().isEmpty) return const [];
    final words = text.trim().split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length <= maxChars) {
        current = candidate;
      } else {
        if (current.isNotEmpty) lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  String _dateText() => DateFormat('dd-MM-yyyy').format(data.previewedAt);

  String _timeText() => DateFormat('HH:mm').format(data.previewedAt);
}

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/static_label_preview_models.dart';

class TeaStaticLabelPreview extends StatelessWidget {
  const TeaStaticLabelPreview({
    super.key,
    required this.data,
    required this.scale,
  });

  final StaticLabelPreviewData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final left = 0.0;
    final right = data.width.toDouble();
    final children = <Widget>[];

    final timeStamp = data.printTime
        ? DateFormat('dd-MM-yyyy HH:mm').format(data.previewedAt)
        : '';

    if (!data.isWhiteLabel) {
      children.add(_text(left + 35, 35, data.companyName, 45));
      if (timeStamp.isNotEmpty) {
        children.add(_text(right - 235, 35, timeStamp, 24));
      }
      final productFont = _fitFont(data.productName, right - left - 50, 36, 28);
      children.add(_text(left + 25, 100, data.productName, productFont, true));

      var attributeY = 148.0;
      final attrs = data.attributes.take(3).toList();
      if (attrs.isNotEmpty) {
        for (final item in attrs) {
          final line = '${item.key} : ${item.value}';
          final rowFont = _fitFont(line, right - left - 50, 30, 22);
          children.add(_text(left + 25, attributeY, line, rowFont, true));
          attributeY += rowFont + 6;
        }
      } else {
        final attributeText = data.description.trim().isEmpty
            ? (data.attributeLabel.trim().isEmpty
                  ? 'Description'
                  : data.attributeLabel.trim())
            : '${data.attributeLabel.trim()} : ${data.description.trim()}';
        final lines = _splitByLength(attributeText, 18).take(2).toList();
        for (int i = 0; i < lines.length; i++) {
          children.add(
            _text(left + 25, attributeY + (i * 36), lines[i], 32, true),
          );
        }
        attributeY += lines.length * 36;
      }

      final weightY = attributeY + 10;
      children.add(_text(left + 25, weightY, 'Weight : ', 32, true));
      children.add(_text(left + 260, weightY, data.grossWeight, 32, true));

      children.add(
        Positioned(
          left: (left + 50) * scale,
          top: (data.height - 105).toDouble() * scale,
          width: (data.width - 100) * scale,
          height: 52 * scale,
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: data.barcodeData,
            drawText: false,
          ),
        ),
      );
    } else {
      if (timeStamp.isNotEmpty) {
        children.add(_text(right - 255, 20, timeStamp, 26));
      }
      final productFont = _fitFont(data.productName, right - left - 50, 45, 30);
      children.add(_text(left + 25, 60, data.productName, productFont, true));

      final attributeText = data.description.trim().isEmpty
          ? (data.attributeLabel.trim().isEmpty
                ? 'Description'
                : data.attributeLabel.trim())
          : '${data.attributeLabel.trim()} : ${data.description.trim()}';
      final lines = _splitByLength(attributeText, 16).take(2).toList();
      final attributeY = 120.0;
      for (int i = 0; i < lines.length; i++) {
        children.add(
          _text(left + 25, attributeY + (i * 46), lines[i], 40, true),
        );
      }

      final weightY = attributeY + (lines.length * 46) + 14;
      children.add(_text(left + 25, weightY, 'Weight : ', 40, true));
      children.add(_text(left + 260, weightY, data.grossWeight, 40, true));

      children.add(
        Positioned(
          left: (left + 50) * scale,
          top: (data.height - 170).toDouble() * scale,
          width: (data.width - 100) * scale,
          height: 100 * scale,
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: data.barcodeData,
            drawText: false,
          ),
        ),
      );
    }

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

  double _fitFont(String text, double maxWidth, double preferred, double min) {
    if (text.trim().isEmpty) return preferred;
    final maxFit = (maxWidth * 2.2 / text.length).floorToDouble();
    return maxFit.clamp(min, preferred);
  }

  List<String> _splitByLength(String text, int maxChars) {
    final clean = text.trim();
    if (clean.isEmpty) return const [];
    final result = <String>[];
    for (int i = 0; i < clean.length; i += maxChars) {
      result.add(clean.substring(i, (i + maxChars).clamp(0, clean.length)));
    }
    return result;
  }
}

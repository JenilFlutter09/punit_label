import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/static_label_preview_models.dart';

class DryFruitStaticLabelPreview extends StatelessWidget {
  const DryFruitStaticLabelPreview({
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

    if (timeStamp.isNotEmpty) {
      children.add(_text(right - 255, 14, timeStamp, 22, true));
    }

    final productY = timeStamp.isNotEmpty ? 42.0 : 22.0;
    final productFont = _fitFont(data.productName, right - left - 50, 44, 34);
    children.add(
      _text(left + 25, productY, data.productName, productFont, true),
    );

    var attributeY = timeStamp.isNotEmpty ? 88.0 : 72.0;
    final attrs = data.attributes.take(4).toList();
    if (attrs.isNotEmpty) {
      for (final item in attrs) {
        final value = item.key.toLowerCase() == 'weight'
            ? item.value
            : item.value;
        final line = '${item.key} : $value';
        final rowFont = _fitFont(line, right - left - 50, 36, 28);
        children.add(_text(left + 25, attributeY, line, rowFont, true));
        attributeY += 42;
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
          _text(left + 25, attributeY + (i * 32), lines[i], 30, true),
        );
      }
    }

    children.add(
      Positioned(
        left: (left + 50) * scale,
        top: (data.height - 130).toDouble() * scale,
        width: (data.width - 100) * scale,
        height: 80 * scale,
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

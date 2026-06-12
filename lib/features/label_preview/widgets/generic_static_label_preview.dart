import 'dart:math' as math;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/static_label_preview_models.dart';

class GenericStaticLabelPreview extends StatelessWidget {
  const GenericStaticLabelPreview({
    super.key,
    required this.data,
    required this.scale,
  });

  final StaticLabelPreviewData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final layout = data.layout!;
    final left = 0.0;
    final top = 0.0;
    final right = data.width.toDouble();
    final bottom = data.height.toDouble();
    var yPos = top + 20;
    var companyY = 0.0;

    final children = <Widget>[];

    if (!data.isWhiteLabel) {
      final companyX = left + 20;
      companyY = yPos;
      children.add(_text(companyX, companyY, data.companyName, 40));

      var contactY = companyY + 70;
      for (final line in data.companyInfoLines) {
        if (line.trim().isEmpty) continue;
        children.add(_text(left + 20, contactY, line, 26));
        contactY += 30;
      }
      if (data.businessHours.isNotEmpty) {
        children.add(_text(left + 20, contactY, data.businessHours, 26));
        contactY += 30;
      }
      yPos = contactY + 10;
    }

    if (data.printTime) {
      final dateX = right - 150;
      final dateY = data.businessHours.isNotEmpty ? yPos : companyY;
      if (data.businessHours.isNotEmpty) {
        yPos += 50;
      }
      children.add(_text(dateX, dateY, _dateText(), 20));
      children.add(_text(dateX, dateY + 22, _timeText(), 20));
    }

    if (data.businessHours.isNotEmpty) {
      children.add(_centeredText(yPos, 'Wholesale Pack', 56, FontWeight.w700));
      yPos += 70;
    }

    final displayName =
        data.businessHours.isNotEmpty && data.productName.contains(':- ')
        ? data.productName.split(':- ').last
        : data.productName;
    final productFont = data.businessHours.isNotEmpty
        ? _fitFont(
            text: displayName,
            maxWidth: data.width - 40,
            preferred: 56,
            min: 24,
          )
        : 34.0;
    final productX = data.businessHours.isNotEmpty
        ? _centerX(displayName, productFont)
        : left + 20;
    children.add(_text(productX, yPos, displayName, productFont));
    yPos += data.businessHours.isNotEmpty ? 80 : 40;

    if (data.attributes.isNotEmpty) {
      if (!data.isGrid) {
        for (final item in data.attributes.take(layout.maxAttributes)) {
          if (yPos > bottom - layout.bottomPadding) break;
          final keyX = left + 20;
          final valueX = keyX + layout.columnGap;
          children.add(_text(keyX, yPos, '${item.key}:', layout.keyFont));
          children.add(_text(valueX, yPos, item.value, layout.valueFont));
          yPos += layout.lineHeight;
        }
      } else {
        final col1X = left + 20;
        final col2X = data.width / 2 + 20;
        final items = data.attributes.take(layout.maxAttributes).toList();
        for (int i = 0; i < items.length; i += 2) {
          if (yPos > bottom - layout.bottomPadding) break;
          final first = items[i];
          children.add(_text(col1X, yPos, '${first.key}:', layout.keyFont));
          children.add(
            _text(
              col1X + layout.columnGap,
              yPos,
              first.value,
              layout.valueFont,
            ),
          );
          final second = i + 1 < items.length ? items[i + 1] : null;
          if (second != null) {
            children.add(_text(col2X, yPos, '${second.key}:', layout.keyFont));
            children.add(
              _text(
                col2X + layout.columnGap,
                yPos,
                second.value,
                layout.valueFont,
              ),
            );
          }
          yPos += layout.lineHeight;
        }
      }
    }

    final footerFont = 20.0;
    final footerText = data.footerText;
    final footerY = bottom - (footerFont + 10);
    final barcodeY = footerY - (layout.barcodeHeight + 28) - 12;
    final barcodeX = left + 20;
    final barcodeWidth = math.max((right - left) - 20, 180).toDouble();

    children.add(
      Positioned(
        left: barcodeX * scale,
        top: barcodeY * scale,
        width: barcodeWidth * scale,
        height: layout.barcodeHeight * scale,
        child: BarcodeWidget(
          barcode: Barcode.code128(),
          data: data.barcodeData,
          drawText: false,
        ),
      ),
    );

    if (!data.isWhiteLabel && footerText.isNotEmpty) {
      children.add(
        Positioned(
          left: (left + 20) * scale,
          top: footerY * scale,
          width: ((right - left) - 40) * scale,
          child: Text(
            footerText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: footerFont * scale * 0.9,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFFDFDFB),
      child: Stack(children: children),
    );
  }

  Widget _text(double x, double y, String text, num fontSize) {
    return Positioned(
      left: x * scale,
      top: y * scale,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize.toDouble() * scale * 0.9,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _centeredText(
    double y,
    String text,
    num fontSize,
    FontWeight fontWeight,
  ) {
    return Positioned(
      left: _centerX(text, fontSize.toDouble()) * scale,
      top: y * scale,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize.toDouble() * scale * 0.9,
          fontWeight: fontWeight,
          color: Colors.black87,
        ),
      ),
    );
  }

  double _fitFont({
    required String text,
    required double maxWidth,
    required double preferred,
    required double min,
  }) {
    if (text.trim().isEmpty) return preferred;
    final maxFit = (maxWidth * 2.2 / text.length).floorToDouble();
    return maxFit.clamp(min, preferred);
  }

  double _centerX(String text, double fontSize) {
    final widthEstimate = text.length * fontSize / 2.2;
    return ((data.width - widthEstimate) / 2).clamp(0, data.width.toDouble());
  }

  String _dateText() => DateFormat('dd-MM-yyyy').format(data.previewedAt);

  String _timeText() => DateFormat('HH:mm').format(data.previewedAt);
}

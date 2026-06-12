import 'dart:math' as math;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:punit_label/features/label_template/models/label_template_models.dart';

Future<void> showRuntimeLabelPreviewDialog({
  required BuildContext context,
  required String title,
  required String labelSize,
  required List<ResolvedPrintField> fields,
  List<PrintableAttributeEntry> attributes = const [],
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'Label size: $labelSize',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final labelMm = _labelMm(labelSize);
                      final safeWidth = math.max(
                        120.0,
                        constraints.maxWidth - 8,
                      );
                      final safeHeight = math.max(
                        120.0,
                        constraints.maxHeight - 8,
                      );
                      final widthDrivenScale = safeWidth / labelMm.$1;
                      final heightDrivenScale = safeHeight / labelMm.$2;
                      final scalePxPerMm = math.min(
                        widthDrivenScale,
                        heightDrivenScale,
                      );
                      final designWidth = labelMm.$1 * scalePxPerMm;
                      final designHeight = labelMm.$2 * scalePxPerMm;

                      return Align(
                        alignment: Alignment.topCenter,
                        child: InteractiveViewer(
                          minScale: 0.75,
                          maxScale: 4,
                          constrained: true,
                          child: Container(
                            width: designWidth,
                            height: designHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade400),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x11000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: _RuntimeLabelPreviewCanvas(
                                labelSize: labelSize,
                                width: designWidth,
                                height: designHeight,
                                scalePxPerMm: scalePxPerMm,
                                fields: fields,
                                attributes: attributes,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _RuntimeLabelPreviewCanvas extends StatelessWidget {
  const _RuntimeLabelPreviewCanvas({
    required this.labelSize,
    required this.width,
    required this.height,
    required this.scalePxPerMm,
    required this.fields,
    required this.attributes,
  });

  final String labelSize;
  final double width;
  final double height;
  final double scalePxPerMm;
  final List<ResolvedPrintField> fields;
  final List<PrintableAttributeEntry> attributes;

  @override
  Widget build(BuildContext context) {
    final labelMm = _labelMm(labelSize);
    final specialFields = {'barcode', 'barcode_text', 'footer'};
    final orderedFields = [...fields]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final textFields = orderedFields
        .where((field) => !specialFields.contains(field.fieldKey.toLowerCase()))
        .toList();
    final barcodeField = orderedFields.firstWhere(
      (field) => field.fieldKey.toLowerCase() == 'barcode',
      orElse: () => const ResolvedPrintField(
        fieldKey: 'barcode',
        value: '',
        isVisible: false,
        x: 2,
        y: 67,
        w: 65,
        h: 12,
        fontSize: 10,
        lineHeight: 12,
        fontWeight: 'normal',
        orderIndex: 0,
      ),
    );
    final barcodeTextField = orderedFields.firstWhere(
      (field) => field.fieldKey.toLowerCase() == 'barcode_text',
      orElse: () => const ResolvedPrintField(
        fieldKey: 'barcode_text',
        value: '',
        isVisible: false,
        x: 10,
        y: 80,
        w: 40,
        h: 4,
        fontSize: 10,
        lineHeight: 10,
        fontWeight: 'normal',
        orderIndex: 0,
      ),
    );
    final footerField = orderedFields.firstWhere(
      (field) => field.fieldKey.toLowerCase() == 'footer',
      orElse: () => const ResolvedPrintField(
        fieldKey: 'footer',
        value: '',
        isVisible: false,
        x: 6,
        y: 92,
        w: 58,
        h: 4,
        fontSize: 8,
        lineHeight: 10,
        fontWeight: 'normal',
        orderIndex: 0,
      ),
    );

    double textBottom = 0;
    for (final field in textFields) {
      if (!field.isVisible || field.value.trim().isEmpty) continue;
      final y = _mmToPxY(field.y, labelMm.$2);
      final h = math.max(_mmToPxY(field.h, labelMm.$2), 16);
      textBottom = math.max(textBottom, y + h);
    }

    final barcodeTop = _mmToPxY(barcodeField.y, labelMm.$2);
    final attributeX = textFields.isEmpty
        ? _mmToPxX(2, labelMm.$1)
        : textFields
              .map((field) => _mmToPxX(field.x, labelMm.$1))
              .reduce(math.min);
    final attributeStartY = math.max(textBottom + 8, _mmToPxY(48, labelMm.$2));
    final attributeMaxY = math.max(barcodeTop - 20, attributeStartY);

    return Container(
      color: const Color(0xFFFDFDFB),
      child: Stack(
        children: [
          for (final field in textFields)
            if (field.isVisible && field.value.trim().isNotEmpty)
              _buildTextField(field, labelMm),
          if (attributes.isNotEmpty)
            Positioned(
              left: attributeX,
              top: attributeStartY,
              width: width - attributeX - 12,
              height: math.max(attributeMaxY - attributeStartY, 20),
              child: _AttributePreviewList(
                attributes: attributes,
                maxHeight: math.max(attributeMaxY - attributeStartY, 20),
              ),
            ),
          if (barcodeField.isVisible && barcodeField.value.trim().isNotEmpty)
            Positioned(
              left: _mmToPxX(barcodeField.x, labelMm.$1),
              top: _mmToPxY(barcodeField.y, labelMm.$2),
              width: math.max(_mmToPxX(barcodeField.w, labelMm.$1), 80),
              height: math.max(_mmToPxY(barcodeField.h, labelMm.$2), 40),
              child: _BarcodePreview(value: barcodeField.value),
            ),
          if (barcodeTextField.isVisible &&
              barcodeTextField.value.trim().isNotEmpty)
            Positioned(
              left: _mmToPxX(barcodeTextField.x, labelMm.$1),
              top: _mmToPxY(barcodeTextField.y, labelMm.$2),
              width: math.max(_mmToPxX(barcodeTextField.w, labelMm.$1), 60),
              child: Text(
                barcodeTextField.value,
                textAlign: TextAlign.center,
                style: _textStyle(barcodeTextField),
              ),
            ),
          if (footerField.isVisible && footerField.value.trim().isNotEmpty)
            Positioned(
              left: _mmToPxX(footerField.x, labelMm.$1),
              top: _mmToPxY(footerField.y, labelMm.$2),
              width: math.max(_mmToPxX(footerField.w, labelMm.$1), width - 20),
              child: Text(
                footerField.value,
                textAlign: TextAlign.center,
                style: _textStyle(
                  footerField,
                ).copyWith(color: Colors.grey[800]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(ResolvedPrintField field, (double, double) labelMm) {
    final isAttributeField = field.fieldKey.trim().toLowerCase().startsWith(
      'attr_',
    );
    final fieldWidth = math.max(_mmToPxX(field.w, labelMm.$1), 40).toDouble();
    final fieldHeight = math.max(_mmToPxY(field.h, labelMm.$2), 16).toDouble();
    final fieldLeft = _mmToPxX(field.x, labelMm.$1);
    final previewWidth = isAttributeField
        ? math.max(width - fieldLeft - 4, fieldWidth).toDouble()
        : fieldWidth;

    return Positioned(
      left: fieldLeft,
      top: _mmToPxY(field.y, labelMm.$2),
      width: previewWidth,
      height: fieldHeight,
      child: isAttributeField
          ? Text(
              field.value,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: _textStyle(field),
            )
          : Text(
              field.value,
              maxLines: _lineCount(field, labelMm.$2),
              overflow: TextOverflow.clip,
              softWrap: true,
              style: _textStyle(field),
            ),
    );
  }

  int _lineCount(ResolvedPrintField field, double labelHeightMm) {
    final h = math.max(_mmToPxY(field.h, labelHeightMm), 16);
    final lineHeight = math.max(field.lineHeight, field.fontSize + 1);
    return math.max(1, (h / _fontPx(lineHeight)).floor());
  }

  TextStyle _textStyle(ResolvedPrintField field) {
    return TextStyle(
      fontSize: _fontPx(field.fontSize),
      height: (field.lineHeight <= 0 || field.fontSize <= 0)
          ? null
          : field.lineHeight / field.fontSize,
      fontWeight: field.fontWeight.toLowerCase() == 'bold'
          ? FontWeight.w700
          : FontWeight.w400,
      color: Colors.black87,
    );
  }

  double _fontPx(double value) {
    final printerLikeScale = math.min(width, height) / 240.0;
    return math.max(6, value * printerLikeScale);
  }

  double _mmToPxX(double mm, double labelWidthMm) {
    return (mm / labelWidthMm) * width;
  }

  double _mmToPxY(double mm, double labelHeightMm) {
    return (mm / labelHeightMm) * height;
  }
}

class _AttributePreviewList extends StatelessWidget {
  const _AttributePreviewList({
    required this.attributes,
    required this.maxHeight,
  });

  final List<PrintableAttributeEntry> attributes;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: attributes
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${item.name} : ${item.value}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _BarcodePreview extends StatelessWidget {
  const _BarcodePreview({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return BarcodeWidget(
          barcode: Barcode.code128(),
          data: value,
          drawText: false,
          color: Colors.black,
          backgroundColor: Colors.transparent,
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
      },
    );
  }
}

(double, double) _labelMm(String labelSize) {
  final parts = labelSize.split('x');
  if (parts.length == 2) {
    final width = double.tryParse(parts[0]) ?? 75;
    final height = double.tryParse(parts[1]) ?? 75;
    return (width, height);
  }
  return (75, 75);
}

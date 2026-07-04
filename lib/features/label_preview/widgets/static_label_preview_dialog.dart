import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../constants/enums.dart';
import '../models/static_label_preview_models.dart';
import 'dry_fruit_static_label_preview.dart';
import 'generic_static_label_preview.dart';
import 'small_seven_static_label_preview.dart';
import 'tea_static_label_preview.dart';

Future<void> showStaticLabelPreviewDialog({
  required BuildContext context,
  required StaticLabelPreviewData data,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 780),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Label Preview',
                        style: TextStyle(
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
                  'Format: ${data.format.name}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final safeWidth = math.max(
                        140.0,
                        constraints.maxWidth - 8,
                      );
                      final safeHeight = math.max(
                        140.0,
                        constraints.maxHeight - 8,
                      );
                      final scale = math.min(
                        safeWidth / data.width,
                        safeHeight / data.height,
                      );
                      final previewWidth = data.width * scale;
                      final previewHeight = data.height * scale;

                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: InteractiveViewer(
                            minScale: 0.75,
                            maxScale: 4,
                            child: Container(
                              width: previewWidth,
                              height: previewHeight,
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
                                child: _buildPreview(data, scale),
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

Widget _buildPreview(StaticLabelPreviewData data, double scale) {
  switch (data.format) {
    case LabelFormat.MajedarTea:
      return TeaStaticLabelPreview(data: data, scale: scale);
    case LabelFormat.DryFruit:
      return DryFruitStaticLabelPreview(data: data, scale: scale);
    case LabelFormat.SmallSeven:
      return SmallSevenStaticLabelPreview(data: data, scale: scale);
    case LabelFormat.Small:
    case LabelFormat.Medium:
    case LabelFormat.Large:
    case LabelFormat.ExtraLarge:
    case LabelFormat.WholesalePack:
    case LabelFormat.large100by150:
      return GenericStaticLabelPreview(data: data, scale: scale);

  }
}

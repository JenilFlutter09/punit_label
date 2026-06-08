class CustomLabelPrintPayload {
  final int width;
  final int height;
  final String labelSize;
  final bool whiteLabel;
  final bool showSrNo;
  final bool showDatetime;
  final String footerText;
  final String barcodeData;
  final String companyName;
  final List<CustomLabelPrintField> fields;

  const CustomLabelPrintPayload({
    required this.width,
    required this.height,
    required this.labelSize,
    required this.whiteLabel,
    required this.showSrNo,
    required this.showDatetime,
    required this.footerText,
    required this.barcodeData,
    required this.companyName,
    required this.fields,
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'labelSize': labelSize,
      'whiteLabel': whiteLabel,
      'showSrNo': showSrNo,
      'showDatetime': showDatetime,
      'footerText': footerText,
      'barcodeData': barcodeData,
      'companyName': companyName,
      'fields': fields.map((field) => field.toMap()).toList(),
    };
  }
}

class CustomLabelPrintField {
  final String fieldKey;
  final String value;
  final int x;
  final int y;
  final int w;
  final int h;
  final int fontSize;
  final int lineHeight;
  final int fontWeight;
  final String align;
  final int orderIndex;
  final Map<String, dynamic> extraJson;

  const CustomLabelPrintField({
    required this.fieldKey,
    required this.value,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    required this.align,
    required this.orderIndex,
    required this.extraJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'field_key': fieldKey,
      'value': value,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
      'font_size': fontSize,
      'line_height': lineHeight,
      'font_weight': fontWeight,
      'align': align,
      'order_index': orderIndex,
      'extra_json': extraJson,
    };
  }
}

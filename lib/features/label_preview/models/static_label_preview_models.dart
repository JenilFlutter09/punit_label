import '../../../constants/enums.dart';

class StaticLabelPreviewAttribute {
  final String key;
  final String value;

  const StaticLabelPreviewAttribute({required this.key, required this.value});
}

class StaticLabelPreviewLayout {
  final int maxAttributes;
  final int lineHeight;
  final int keyFont;
  final int valueFont;
  final int bottomPadding;
  final int columnGap;
  final int barcodeHeight;

  const StaticLabelPreviewLayout({
    required this.maxAttributes,
    required this.lineHeight,
    required this.keyFont,
    required this.valueFont,
    required this.bottomPadding,
    required this.columnGap,
    required this.barcodeHeight,
  });
}

class StaticLabelPreviewData {
  final LabelFormat format;
  final int width;
  final int height;
  final bool isWhiteLabel;
  final bool printTime;
  final bool printSerialNumber;
  final bool isGrid;
  final String companyName;
  final List<String> companyInfoLines;
  final String address;
  final String phone;
  final String email;
  final String productName;
  final String barcodeData;
  final String serialNumber;
  final String footerText;
  final String businessHours;
  final String attributeLabel;
  final String description;
  final String grossWeight;
  final DateTime previewedAt;
  final StaticLabelPreviewLayout? layout;
  final List<StaticLabelPreviewAttribute> attributes;

  const StaticLabelPreviewData({
    required this.format,
    required this.width,
    required this.height,
    required this.isWhiteLabel,
    required this.printTime,
    required this.printSerialNumber,
    required this.isGrid,
    required this.companyName,
    required this.companyInfoLines,
    required this.address,
    required this.phone,
    required this.email,
    required this.productName,
    required this.barcodeData,
    required this.serialNumber,
    required this.footerText,
    required this.businessHours,
    required this.attributeLabel,
    required this.description,
    required this.grossWeight,
    required this.previewedAt,
    required this.layout,
    required this.attributes,
  });
}

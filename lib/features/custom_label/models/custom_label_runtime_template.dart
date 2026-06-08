class CustomLabelRuntimeResponse {
  final bool status;
  final CustomLabelRuntimeData data;

  CustomLabelRuntimeResponse({required this.status, required this.data});

  factory CustomLabelRuntimeResponse.fromJson(Map<String, dynamic> json) {
    return CustomLabelRuntimeResponse(
      status: json['status'] == true,
      data: CustomLabelRuntimeData.fromJson(
        Map<String, dynamic>.from(json['data'] ?? const {}),
      ),
    );
  }
}

class CustomLabelRuntimeData {
  final String labelMode;
  final String? templateKey;
  final CustomLabelRuntimeTemplate? template;
  final CompanyProfileRuntimeData? companyProfile;
  final String? footerText;

  const CustomLabelRuntimeData({
    required this.labelMode,
    this.templateKey,
    this.template,
    this.companyProfile,
    this.footerText,
  });

  bool get isCustom => labelMode.toLowerCase() == 'custom' && template != null;

  factory CustomLabelRuntimeData.fromJson(Map<String, dynamic> json) {
    return CustomLabelRuntimeData(
      labelMode: (json['label_mode'] ?? 'existing').toString(),
      templateKey: json['template_key']?.toString(),
      template: json['template'] == null
          ? null
          : CustomLabelRuntimeTemplate.fromJson(
              Map<String, dynamic>.from(json['template'] as Map),
            ),
      companyProfile: json['company_profile'] == null
          ? null
          : CompanyProfileRuntimeData.fromJson(
              Map<String, dynamic>.from(json['company_profile'] as Map),
            ),
      footerText: json['footer_text']?.toString(),
    );
  }
}

class CustomLabelRuntimeTemplate {
  final String? labelSize;
  final bool whiteLabel;
  final bool showSrNo;
  final bool showDatetime;
  final List<CustomLabelField> fields;

  const CustomLabelRuntimeTemplate({
    this.labelSize,
    this.whiteLabel = false,
    this.showSrNo = false,
    this.showDatetime = false,
    this.fields = const [],
  });

  factory CustomLabelRuntimeTemplate.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'] as List? ?? const [];
    return CustomLabelRuntimeTemplate(
      labelSize: json['label_size']?.toString(),
      whiteLabel: json['white_label'] == true || json['white_label'] == 1,
      showSrNo: json['show_sr_no'] == true || json['show_sr_no'] == 1,
      showDatetime: json['show_datetime'] == true || json['show_datetime'] == 1,
      fields: rawFields
          .map(
            (field) => CustomLabelField.fromJson(
              Map<String, dynamic>.from(field as Map),
            ),
          )
          .toList(),
    );
  }
}

class CustomLabelField {
  final String fieldKey;
  final bool isVisible;
  final double x;
  final double y;
  final double w;
  final double h;
  final double fontSize;
  final double lineHeight;
  final int fontWeight;
  final String align;
  final int orderIndex;
  final Map<String, dynamic> extraJson;

  const CustomLabelField({
    required this.fieldKey,
    required this.isVisible,
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

  factory CustomLabelField.fromJson(Map<String, dynamic> json) {
    return CustomLabelField(
      fieldKey: (json['field_key'] ?? '').toString(),
      isVisible: json['is_visible'] == true || json['is_visible'] == 1,
      x: _toDouble(json['x']),
      y: _toDouble(json['y']),
      w: _toDouble(json['w']),
      h: _toDouble(json['h']),
      fontSize: _toDouble(json['font_size'], fallback: 24),
      lineHeight: _toDouble(json['line_height'], fallback: 28),
      fontWeight: _toInt(json['font_weight'], fallback: 400),
      align: (json['align'] ?? 'left').toString(),
      orderIndex: _toInt(json['order_index']),
      extraJson: json['extra_json'] is Map
          ? Map<String, dynamic>.from(json['extra_json'] as Map)
          : const {},
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? fallback;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}

class CompanyProfileRuntimeData {
  final String? companyName;
  final String? companyEmail;
  final String? companyContactNo;
  final String? companyGstNo;
  final String? companyWebsite;
  final String? companyAddress;

  const CompanyProfileRuntimeData({
    this.companyName,
    this.companyEmail,
    this.companyContactNo,
    this.companyGstNo,
    this.companyWebsite,
    this.companyAddress,
  });

  factory CompanyProfileRuntimeData.fromJson(Map<String, dynamic> json) {
    return CompanyProfileRuntimeData(
      companyName: json['company_name']?.toString(),
      companyEmail: json['company_email']?.toString(),
      companyContactNo: json['company_contact_no']?.toString(),
      companyGstNo: json['company_gst_no']?.toString(),
      companyWebsite: json['company_website']?.toString(),
      companyAddress: json['company_address']?.toString(),
    );
  }
}

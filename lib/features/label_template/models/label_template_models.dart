class LabelTemplateOptionsResponse {
  final bool? status;
  final String? message;
  final LabelTemplateOptionsData? data;

  LabelTemplateOptionsResponse({this.status, this.message, this.data});

  factory LabelTemplateOptionsResponse.fromJson(Map<String, dynamic> json) {
    return LabelTemplateOptionsResponse(
      status: json['status'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? LabelTemplateOptionsData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class LabelTemplateOptionsData {
  final List<LabelTemplateOption> options;

  LabelTemplateOptionsData({required this.options});

  factory LabelTemplateOptionsData.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? const [];
    return LabelTemplateOptionsData(
      options: rawOptions
          .whereType<Map>()
          .map(
            (item) =>
                LabelTemplateOption.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class LabelTemplateOption {
  final String id;
  final String name;
  final String mode;
  final String? labelSize;
  final int? productId;
  final bool isDefault;

  const LabelTemplateOption({
    required this.id,
    required this.name,
    required this.mode,
    this.labelSize,
    this.productId,
    required this.isDefault,
  });

  factory LabelTemplateOption.fromJson(Map<String, dynamic> json) {
    return LabelTemplateOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'existing',
      labelSize: json['label_size']?.toString(),
      productId: _toInt(json['product_id']),
      isDefault: _toBool(json['is_default']),
    );
  }

  bool get isCustom => mode.trim().toLowerCase() == 'custom';
  bool get isExisting => mode.trim().toLowerCase() == 'existing';
}

class RuntimeLabelTemplateResponse {
  final bool? status;
  final String? message;
  final RuntimeLabelTemplateData? data;

  RuntimeLabelTemplateResponse({this.status, this.message, this.data});

  factory RuntimeLabelTemplateResponse.fromJson(Map<String, dynamic> json) {
    return RuntimeLabelTemplateResponse(
      status: json['status'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? RuntimeLabelTemplateData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class RuntimeLabelTemplateData {
  final String? labelMode;
  final String? templateKey;
  final RuntimeTemplate? template;
  final List<String> lockedFields;
  final RuntimeCompanyProfile? companyProfile;
  final String? footerText;
  final bool footerLocked;
  final String? footerMessage;

  RuntimeLabelTemplateData({
    this.labelMode,
    this.templateKey,
    this.template,
    required this.lockedFields,
    this.companyProfile,
    this.footerText,
    required this.footerLocked,
    this.footerMessage,
  });

  factory RuntimeLabelTemplateData.fromJson(Map<String, dynamic> json) {
    final lockedFields = json['locked_fields'] as List? ?? const [];
    return RuntimeLabelTemplateData(
      labelMode: json['label_mode']?.toString(),
      templateKey: json['template_key']?.toString(),
      template: json['template'] is Map<String, dynamic>
          ? RuntimeTemplate.fromJson(json['template'] as Map<String, dynamic>)
          : null,
      lockedFields: lockedFields
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
      companyProfile: json['company_profile'] is Map<String, dynamic>
          ? RuntimeCompanyProfile.fromJson(
              json['company_profile'] as Map<String, dynamic>,
            )
          : null,
      footerText: json['footer_text']?.toString(),
      footerLocked: _toBool(json['footer_locked']),
      footerMessage: json['footer_message']?.toString(),
    );
  }

  bool get isCustom => labelMode?.trim().toLowerCase() == 'custom';
  bool get isExisting => labelMode?.trim().toLowerCase() == 'existing';
}

class RuntimeTemplate {
  final int? id;
  final int? adminId;
  final int? productId;
  final String? name;
  final String? labelSize;
  final bool isActive;
  final bool isDefault;
  final bool whiteLabel;
  final bool showSrNo;
  final bool showDatetime;
  final Map<String, dynamic>? canvasConfigJson;
  final List<RuntimeTemplateField> fields;

  RuntimeTemplate({
    this.id,
    this.adminId,
    this.productId,
    this.name,
    this.labelSize,
    required this.isActive,
    required this.isDefault,
    required this.whiteLabel,
    required this.showSrNo,
    required this.showDatetime,
    this.canvasConfigJson,
    required this.fields,
  });

  factory RuntimeTemplate.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'] as List? ?? const [];
    return RuntimeTemplate(
      id: _toInt(json['id']),
      adminId: _toInt(json['admin_id']),
      productId: _toInt(json['product_id']),
      name: json['name']?.toString(),
      labelSize: json['label_size']?.toString(),
      isActive: _toBool(json['is_active']),
      isDefault: _toBool(json['is_default']),
      whiteLabel: _toBool(json['white_label']),
      showSrNo: _toBool(json['show_sr_no']),
      showDatetime: _toBool(json['show_datetime']),
      canvasConfigJson: json['canvas_config_json'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['canvas_config_json'] as Map<String, dynamic>,
            )
          : null,
      fields:
          rawFields
              .whereType<Map>()
              .map(
                (item) => RuntimeTemplateField.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
    );
  }
}

class RuntimeTemplateField {
  final String fieldKey;
  final bool isVisible;
  final double x;
  final double y;
  final double w;
  final double h;
  final double fontSize;
  final double lineHeight;
  final String fontWeight;
  final int orderIndex;
  final Map<String, dynamic>? extraJson;

  RuntimeTemplateField({
    required this.fieldKey,
    required this.isVisible,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    required this.orderIndex,
    this.extraJson,
  });

  factory RuntimeTemplateField.fromJson(Map<String, dynamic> json) {
    return RuntimeTemplateField(
      fieldKey: json['field_key']?.toString() ?? '',
      isVisible: _toBool(json['is_visible']),
      x: _toDouble(json['x']),
      y: _toDouble(json['y']),
      w: _toDouble(json['w']),
      h: _toDouble(json['h']),
      fontSize: _toDouble(json['font_size']),
      lineHeight: _toDouble(json['line_height']),
      fontWeight: json['font_weight']?.toString() ?? 'normal',
      orderIndex: _toInt(json['order_index']) ?? 0,
      extraJson: json['extra_json'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['extra_json'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class RuntimeCompanyProfile {
  final String? name;
  final String? email;
  final String? contactNo;
  final String? gstNo;
  final String? website;
  final String? address;
  final Map<String, dynamic>? labelFields;

  RuntimeCompanyProfile({
    this.name,
    this.email,
    this.contactNo,
    this.gstNo,
    this.website,
    this.address,
    this.labelFields,
  });

  factory RuntimeCompanyProfile.fromJson(Map<String, dynamic> json) {
    return RuntimeCompanyProfile(
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      contactNo: json['contact_no']?.toString(),
      gstNo: json['gst_no']?.toString(),
      website: json['website']?.toString(),
      address: json['address']?.toString(),
      labelFields: json['label_fields'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['label_fields'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String valueForField(String fieldKey) {
    final key = fieldKey.trim().toLowerCase();
    switch (key) {
      case 'company_name':
        return _isCompanyFieldEnabled('name') ? (name ?? '') : '';
      case 'company_email':
        return _isCompanyFieldEnabled('email') ? (email ?? '') : '';
      case 'company_contact_no':
        return _isCompanyFieldEnabled('contact_no') ? (contactNo ?? '') : '';
      case 'company_gst_no':
        return _isCompanyFieldEnabled('gst_no') ? (gstNo ?? '') : '';
      case 'company_website':
        return _isCompanyFieldEnabled('website') ? (website ?? '') : '';
      case 'company_address':
        return _isCompanyFieldEnabled('address') ? (address ?? '') : '';
      default:
        return '';
    }
  }

  bool _isCompanyFieldEnabled(String key) {
    if (labelFields == null) return true;
    final value = labelFields![key];
    if (value == null) return true;
    return value.toString().trim().toLowerCase() == 'on';
  }
}

class ResolvedPrintField {
  final String fieldKey;
  final String value;
  final bool isVisible;
  final double x;
  final double y;
  final double w;
  final double h;
  final double fontSize;
  final double lineHeight;
  final String fontWeight;
  final int orderIndex;
  final Map<String, dynamic>? extraJson;

  const ResolvedPrintField({
    required this.fieldKey,
    required this.value,
    required this.isVisible,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    required this.orderIndex,
    this.extraJson,
  });

  factory ResolvedPrintField.fromTemplateField(
    RuntimeTemplateField field,
    String value,
  ) {
    return ResolvedPrintField(
      fieldKey: field.fieldKey,
      value: value,
      isVisible: field.isVisible,
      x: field.x,
      y: field.y,
      w: field.w,
      h: field.h,
      fontSize: field.fontSize,
      lineHeight: field.lineHeight,
      fontWeight: field.fontWeight,
      orderIndex: field.orderIndex,
      extraJson: field.extraJson,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'field_key': fieldKey,
      'value': value,
      'is_visible': isVisible,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
      'font_size': fontSize,
      'line_height': lineHeight,
      'font_weight': fontWeight,
      'order_index': orderIndex,
      'extra_json': extraJson,
    };
  }
}

class PrintableAttributeEntry {
  final String name;
  final String value;

  const PrintableAttributeEntry({required this.name, required this.value});

  Map<String, dynamic> toMap() {
    return {'name': name, 'value': value};
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'on';
}

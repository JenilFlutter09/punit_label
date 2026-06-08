class LabelTemplateOptionsResponse {
  final bool status;
  final LabelTemplateOptionsData data;

  LabelTemplateOptionsResponse({required this.status, required this.data});

  factory LabelTemplateOptionsResponse.fromJson(Map<String, dynamic> json) {
    return LabelTemplateOptionsResponse(
      status: json['status'] == true,
      data: LabelTemplateOptionsData.fromJson(
        Map<String, dynamic>.from(json['data'] ?? const {}),
      ),
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
          .map(
            (option) => LabelTemplateOption.fromJson(
              Map<String, dynamic>.from(option as Map),
            ),
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
  final int? maxAllowed;

  const LabelTemplateOption({
    required this.id,
    required this.name,
    required this.mode,
    this.labelSize,
    this.productId,
    this.isDefault = false,
    this.maxAllowed,
  });

  bool get isCustom => mode.toLowerCase() == 'custom';
  bool get isExisting => mode.toLowerCase() == 'existing';

  factory LabelTemplateOption.fromJson(Map<String, dynamic> json) {
    return LabelTemplateOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      mode: (json['mode'] ?? 'existing').toString(),
      labelSize: json['label_size']?.toString(),
      productId: json['product_id'] is num
          ? (json['product_id'] as num).toInt()
          : int.tryParse((json['product_id'] ?? '').toString()),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      maxAllowed: json['max_allowed'] is num
          ? (json['max_allowed'] as num).toInt()
          : int.tryParse((json['max_allowed'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mode': mode,
      'label_size': labelSize,
      'product_id': productId,
      'is_default': isDefault,
      'max_allowed': maxAllowed,
    };
  }
}

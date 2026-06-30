class DispatchModel {
  bool? status;
  String? message;
  List<Data>? data;

  DispatchModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];

    if (json['data'] != null && json['data'] is List) {
      data = (json['data'] as List).map((e) => Data.fromJson(e)).toList();
    }
  }
}

class DispatchSubmitResponse {
  bool? status;
  String? message;
  DispatchSubmitData? data;

  DispatchSubmitResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] is Map<String, dynamic>
        ? DispatchSubmitData.fromJson(json['data'])
        : null;
  }
}

class DispatchSubmitData {
  String? dispatchId;
  String? dispatchedAt;

  DispatchSubmitData.fromJson(Map<String, dynamic> json) {
    dispatchId = json['dispatch_id'];
    dispatchedAt = json['dispatched_at'];
  }
}

class Data {
  int? stockId;
  int? productId;
  String? productName;
  bool? unitConversion;
  String? unit;
  List<Variation>? variation;
  List<Barcodes>? barcodes;

  Data({
    this.stockId,
    this.productId,
    this.productName,
    this.unitConversion,
    this.unit,
    this.variation,
    this.barcodes,
  });

  Data.fromJson(Map<String, dynamic> json) {
    stockId = json['stock_id'];
    productId = json['product_id'];
    productName = json['product_name'];
    unitConversion = json['unit_conversion'];
    unit = json['unit'];
    variation = (json['variation'] as List? ?? [])
        .map((e) => Variation.fromJson(e))
        .toList();
    barcodes = (json['barcodes'] as List? ?? [])
        .map((e) => Barcodes.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['stock_id'] = this.stockId;
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['unit_conversion'] = this.unitConversion;
    data['unit'] = this.unit;
    if (variation != null) {
      data['variation'] = variation!.map((v) => v.toJson()).toList();
    }
    if (barcodes != null) {
      data['barcodes'] = barcodes!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class Variation {
  int? attributeId;
  String? attributeName;
  int? optionId;
  String? optionName;

  Variation({
    this.attributeId,
    this.attributeName,
    this.optionId,
    this.optionName,
  });

  Variation.fromJson(Map<String, dynamic> json) {
    attributeId = json['attribute_id'];
    attributeName = json['attribute_name'];
    optionId = json['option_id'];
    optionName = json['option_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['attribute_id'] = this.attributeId;
    data['attribute_name'] = this.attributeName;
    data['option_id'] = this.optionId;
    data['option_name'] = this.optionName;
    return data;
  }
}

class Barcodes {
  int? id;
  String? barCodeString;
  // String? isTareWeight;
  // String? tareWeight;
  // String? grossWeight;
  // String? netWeight;
  bool? isTareWeight;
  double? tareWeight;
  double? grossWeight;
  double? netWeight;
  int? stockId;
  String? serialNo;
  String? time;

  Barcodes({
    this.id,
    this.barCodeString,
    this.isTareWeight,
    this.tareWeight,
    this.grossWeight,
    this.netWeight,
    this.stockId,
    this.serialNo,
    this.time,
  });

  Barcodes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    barCodeString = json['bar_code_string'];
    isTareWeight = _toBool(json['is_tare_weight']);
    tareWeight = _toDouble(json['tare_weight']);
    grossWeight = _toDouble(json['gross_weight']);
    netWeight = _toDouble(json['net_weight']);
    stockId = json['stock_id'];
    serialNo = json['serial_no'];
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['bar_code_string'] = this.barCodeString;
    data['is_tare_weight'] = this.isTareWeight;
    data['tare_weight'] = this.tareWeight;
    data['gross_weight'] = this.grossWeight;
    data['net_weight'] = this.netWeight;
    data['stock_id'] = this.stockId;
    data['serial_no'] = this.serialNo;
    data['time'] = this.time;
    return data;
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
  return false;
}

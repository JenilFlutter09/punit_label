import 'dispatchModel.dart';

class Dispatchbarcodes {
  int? id;
  String? barCodeString;
  String? productName;
  bool? isTareWeight;
  double? tareWeight;
  double? grossWeight;
  double? netWeight;
  int? stockId;
  bool? unitConversion;
  String? unit;
  List<Variation>? variation;

  Dispatchbarcodes({
    this.id,
    this.barCodeString,
    this.productName,
    this.isTareWeight,
    this.tareWeight,
    this.grossWeight,
    this.netWeight,
    this.stockId,
    this.unitConversion,
    this.unit,
    this.variation,
  });

  Dispatchbarcodes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    barCodeString = json['bar_code_string'];
    isTareWeight =
        json['is_tare_weight'] == 1 || json['is_tare_weight'] == true;
    tareWeight = _toDouble(json['tare_weight']);
    grossWeight = _toDouble(json['gross_weight']);
    netWeight = _toDouble(json['net_weight']);
    stockId = json['stock_id'] ?? json['stockId'];
    unitConversion =
        json['unit_conversion'] == 1 || json['unit_conversion'] == true;
    unit = json['unit']?.toString();
    variation = (json['variation'] as List? ?? [])
        .map((e) => Variation.fromJson(e))
        .toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['bar_code_string'] = this.barCodeString;
    data['is_tare_weight'] = this.isTareWeight;
    data['tare_weight'] = this.tareWeight;
    data['gross_weight'] = this.grossWeight;
    data['net_weight'] = this.netWeight;
    data['stockId'] = this.stockId;
    data['unit_conversion'] = this.unitConversion;
    data['unit'] = this.unit;
    return data;
  }
}

class DispatchBarcode {
  List<VerifiedBarcode>? data;
  int? customerId;
  DispatchBarcode({this.data, required this.customerId});

  DispatchBarcode.fromJson(Map<String, dynamic> json) {
    customerId = json['customer_id'];
    if (json['data'] != null) {
      data = <VerifiedBarcode>[];
      json['data'].forEach((v) {
        data!.add(new VerifiedBarcode.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['customer_id'] = this.customerId;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VerifiedBarcode {
  int? stockId;
  int? barcodeId;

  VerifiedBarcode({this.stockId, this.barcodeId});

  VerifiedBarcode.fromJson(Map<String, dynamic> json) {
    stockId = json['stock_id'];
    barcodeId = json['barcode_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['stock_id'] = this.stockId;
    data['barcode_id'] = this.barcodeId;
    return data;
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

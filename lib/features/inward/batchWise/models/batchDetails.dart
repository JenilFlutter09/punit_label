import 'package:get/get.dart';
class BatchDetails {
  bool? status;
  String? message;
  Data? data;

  BatchDetails({this.status, this.message, this.data});

  BatchDetails.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Batch? batch;
  List<Products>? products;
  bool? isPaused;
  List<Barcodes>? barcodes;

  Data({this.batch, this.products, this.isPaused, this.barcodes});

  Data.fromJson(Map<String, dynamic> json) {
    batch = json['batch'] != null ? new Batch.fromJson(json['batch']) : null;
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(new Products.fromJson(v));
      });
    }
    isPaused = json['is_paused'];
    if (json['barcodes'] != null) {
      barcodes = <Barcodes>[];
      json['barcodes'].forEach((v) {
        barcodes!.add(new Barcodes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.batch != null) {
      data['batch'] = this.batch!.toJson();
    }
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    data['is_paused'] = this.isPaused;
    if (this.barcodes != null) {
      data['barcodes'] = this.barcodes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Batch {
  int? id;
  String? batchName;

  Batch({this.id, this.batchName});

  Batch.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    batchName = json['batch_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['batch_name'] = this.batchName;
    return data;
  }
}

class Products {
  int? batchProductId;
  //String? productId;
  int? productId;
  String? productName;
  String? labelId;
  //String? tareWeight;
  double? tareWeight;
  bool? autoWeight;
  double? minAutoWeight;
  double? maxAutoWeight;
  double? autoWeightSeconds;
  bool? unitConversion;
  String? unit;

  List<Combinations>? combinations;

  Products(
      {this.batchProductId,
        this.productId,
        this.productName,
        this.labelId,
        this.tareWeight,
        this.autoWeight,
        this.minAutoWeight,
        this.maxAutoWeight,
        this.autoWeightSeconds,
        this.unitConversion,
        this.unit,
        this.combinations});

  /*Products.fromJson(Map<String, dynamic> json) {
    batchProductId = json['batch_product_id'];
    productId = json['product_id'];
    productName = json['product_name'];
    labelId = json['label_id'];
    autoWeight = json['auto_weight'];
    tareWeight = json['tare_weight'].toDouble();
    minAutoWeight = json['min_auto_weight'].toDouble();
    maxAutoWeight = json['max_auto_weight'].toDouble();
    autoWeightSeconds = json['auto_weight_seconds'].toDouble();
    unitConversion = json['unit_conversion'];
    unit = json['unit'];
    if (json['combinations'] != null) {
      combinations = <Combinations>[];
      json['combinations'].forEach((v) {
        combinations!.add(new Combinations.fromJson(v));
      });
    }
  }*/
  Products.fromJson(Map<String, dynamic> json) {
    batchProductId = json['batch_product_id'];
    productId = json['product_id'];
    productName = json['product_name'];
    labelId = json['label_id'];
    autoWeight = json['auto_weight'];

    tareWeight = (json['tare_weight'] as num?)?.toDouble();
    minAutoWeight = (json['min_auto_weight'] as num?)?.toDouble();
    maxAutoWeight = (json['max_auto_weight'] as num?)?.toDouble();
    autoWeightSeconds = (json['auto_weight_seconds'] as num?)?.toDouble();

    unitConversion = json['unit_conversion'];
    unit = json['unit'];

    if (json['combinations'] != null) {
      combinations = (json['combinations'] as List)
          .map((v) => Combinations.fromJson(v))
          .toList();
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['batch_product_id'] = this.batchProductId;
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['label_id'] = this.labelId;
    data['tare_weight'] = this.tareWeight;
    data['auto_weight'] = this.autoWeight;
    data['min_auto_weight'] = this.minAutoWeight;
    data['max_auto_weight'] = this.maxAutoWeight;
    data['auto_weight_seconds'] = this.autoWeightSeconds;
    data['unit_conversion'] = this.unitConversion;
    data['unit'] = this.unit;
    if (this.combinations != null) {
      data['combinations'] = this.combinations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}


class Barcodes {
  int? batchProductId;
  String? batchProductName;
  String? barCodeString;
  String? isTareWeight;
  String? tareWeight;
  String? grossWeight;
  String? netWeight;
  String? units;
  bool? unitConversion;
  DateTime? time;
  int? serialNo;

  Barcodes(
      {this.batchProductId,
        this.batchProductName,
        this.barCodeString,
        this.isTareWeight,
        this.tareWeight,
        this.grossWeight,
        this.units,
        this.unitConversion,
        this.netWeight,this.time,this.serialNo});

  Barcodes.fromJson(Map<String, dynamic> json) {
    batchProductId = json['batch_product_id'];
    batchProductName = json['batch_product_name'];
    barCodeString = json['bar_code_string'];
    isTareWeight = json['is_tare_weight'];
    tareWeight = json['tare_weight'];
    grossWeight = json['gross_weight'];
    netWeight = json['net_weight'];
    time = json['time'] != null
        ? DateTime.parse(json['time'])
        : null;
    serialNo = json['serial_no'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['batch_product_id'] = this.batchProductId;
    data['batch_product_name'] = this.batchProductName;
    data['bar_code_string'] = this.barCodeString;
    data['is_tare_weight'] = this.isTareWeight;
    data['tare_weight'] = this.tareWeight;
    data['gross_weight'] = this.grossWeight;
    data['net_weight'] = this.netWeight;
    data['time'] = time?.toIso8601String(); // 🕒
    data['serial_no'] = serialNo.toString();
    return data;
  }
}


class Combinations {
  int? id;
  String? attrName;
  String? attrValue;
  RxBool isPrintable = false.obs;  // <-- ADD THIS

  Combinations({
    this.id,
    this.attrName,
    this.attrValue,
    dynamic isPrintable,
  }) {
    this.isPrintable.value = (isPrintable == "1" || isPrintable == 1);
  }

  factory Combinations.fromJson(Map<String, dynamic> json) {
    return Combinations(
      id: json["id"],
      attrName: json["attr_name"],
      attrValue: json["attr_value"],
      isPrintable: json["is_printable"],
    );
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['attr_name'] = this.attrName;
    data['attr_value'] = this.attrValue;
    data['is_printable'] = this.isPrintable;
    return data;
  }
}

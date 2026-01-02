class NonBatchDetailModel {
  bool? status;
  String? message;
  Data? data;

  NonBatchDetailModel({this.status, this.message, this.data});

  NonBatchDetailModel.fromJson(Map<String, dynamic> json) {
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
  int? transactionId;
  String? transactionName;
  List<Products>? products;
  bool? isPaused;

  Data(
      {this.transactionId, this.transactionName, this.products, this.isPaused});

  Data.fromJson(Map<String, dynamic> json) {
    transactionId = json['transaction_id'];
    transactionName = json['transaction_name'];
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(new Products.fromJson(v));
      });
    }
    isPaused = json['is_paused'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['transaction_id'] = this.transactionId;
    data['transaction_name'] = this.transactionName;
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    data['is_paused'] = this.isPaused;
    return data;
  }
}

class Products {
  int? productId;
  String? productName;
  bool? autoWeight;
  double? minAutoWeight;
  double? maxAutoWeight;
  double? autoWeightSeconds;
  double? tareWeight;
  List<Combinations>? combinations;
  List<Barcodes>? barcodes;

  Products(
      {this.productId,
        this.productName,
        this.autoWeight,
        this.minAutoWeight,
        this.maxAutoWeight,
        this.autoWeightSeconds,
        this.combinations,
        this.barcodes});

  Products.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    autoWeight = json['auto_weight'];
    // minAutoWeight = json['min_auto_weight'];
    // maxAutoWeight = json['max_auto_weight'];
    // autoWeightSeconds = json['auto_weight_seconds'];
    tareWeight = _toDouble(json['tare_weight']);
    minAutoWeight = _toDouble(json['min_auto_weight']);
    maxAutoWeight = _toDouble(json['max_auto_weight']);
    autoWeightSeconds = _toDouble(json['auto_weight_seconds']);
    if (json['combinations'] != null) {
      combinations = <Combinations>[];
      json['combinations'].forEach((v) {
        combinations!.add(new Combinations.fromJson(v));
      });
    }
    if (json['barcodes'] != null) {
      barcodes = <Barcodes>[];
      json['barcodes'].forEach((v) {
        barcodes!.add(new Barcodes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['auto_weight'] = this.autoWeight;
    data['min_auto_weight'] = this.minAutoWeight;
    data['max_auto_weight'] = this.maxAutoWeight;
    data['auto_weight_seconds'] = this.autoWeightSeconds;
    if (this.combinations != null) {
      data['combinations'] = this.combinations!.map((v) => v.toJson()).toList();
    }
    if (this.barcodes != null) {
      data['barcodes'] = this.barcodes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Combinations {
  int? id;
  int? attributeId;
  String? attributeName;
  String? optionValue;
  int? optionId;

  Combinations(
      {this.id,
        this.attributeId,
        this.attributeName,
        this.optionValue,
        this.optionId});

  Combinations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    attributeId = json['attribute_id'];
    attributeName = json['attribute_name'];
    optionValue = json['option_value'];
    optionId = json['option_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['attribute_id'] = this.attributeId;
    data['attribute_name'] = this.attributeName;
    data['option_value'] = this.optionValue;
    data['option_id'] = this.optionId;
    return data;
  }
}
double? _toDouble(dynamic value) {
  return (value as num?)?.toDouble();
}

class Barcodes {
  int? productId;
  String? productName;
  String? barCodeString;
  int? isTareWeight;
  double? tareWeight;
  double? grossWeight;
  double? netWeight;

  Barcodes(
      {this.productId,
        this.productName,
        this.barCodeString,
        this.isTareWeight,
        this.tareWeight,
        this.grossWeight,
        this.netWeight});

  Barcodes.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    barCodeString = json['bar_code_string'];
    isTareWeight = json['is_tare_weight'];
    tareWeight = _toDouble(json['tare_weight']);
    grossWeight = _toDouble(json['gross_weight']);
    netWeight = _toDouble(json['net_weight']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['bar_code_string'] = this.barCodeString;
    data['is_tare_weight'] = this.isTareWeight;
    data['tare_weight'] = this.tareWeight;
    data['gross_weight'] = this.grossWeight;
    data['net_weight'] = this.netWeight;
    return data;
  }
}

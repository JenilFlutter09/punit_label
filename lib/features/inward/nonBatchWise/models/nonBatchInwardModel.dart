class NonBatchInwardModel {
  int? transactionId;
  String? transactionName;
  String? status;
  List<NonBatchProducts>? products;

  NonBatchInwardModel({
    this.transactionId,
    this.transactionName,
    this.status,
    this.products,
  });

  NonBatchInwardModel.fromJson(Map<String, dynamic> json) {
    transactionId = json['transaction_id'];
    transactionName = json['transaction_name'];
    status = json['status'];
    if (json['products'] != null) {
      products = <NonBatchProducts>[];
      json['products'].forEach((v) {
        products!.add(new NonBatchProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['transaction_id'] = this.transactionId;
    data['transaction_name'] = this.transactionName;
    data['status'] = this.status;
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NonBatchProducts {
  int? productId;
  String? productName;
  List<NonBatchAttributes>? attributes;
  List<NonBatchBarcodes>? barcodes;

  NonBatchProducts({
    this.productId,
    this.productName,
    this.attributes,
    this.barcodes,
  });

  NonBatchProducts.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    if (json['combinations'] != null) {
      attributes = <NonBatchAttributes>[];
      json['combinations'].forEach((v) {
        attributes!.add(new NonBatchAttributes.fromJson(v));
      });
    }
    if (json['barcodes'] != null) {
      barcodes = <NonBatchBarcodes>[];
      json['barcodes'].forEach((v) {
        barcodes!.add(new NonBatchBarcodes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    if (this.attributes != null) {
      data['combinations'] = this.attributes!.map((v) => v.toJson()).toList();
    }
    if (this.barcodes != null) {
      data['barcodes'] = this.barcodes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NonBatchAttributes {
  int? attributeId;
  String? attributeName;
  int? optionId;
  String? optionName;

  NonBatchAttributes({
    this.attributeId,
    this.attributeName,
    this.optionId,
    this.optionName,
  });
  NonBatchAttributes.fromJson(Map<String, dynamic> json) {
    attributeId = json['attribute_id'];
    attributeName = json['attribute_name'];
    optionId = json['option_id'];
    optionName = json['option_name'];
  }
  Map<String, dynamic> toJson() {
    return {
      "attribute_id": attributeId,
      "attribute_name": attributeName,
      "option_id": optionId,
      "option_name": optionName,
    };
  }
}

class NonBatchBarcodes {
  String? barCodeString;
  bool? tareWeightEnable;
  double? tareWeight;
  double? grossWeight;
  double? netWeight;
  DateTime? time;
  int? serialNo;
  NonBatchBarcodes({
    this.barCodeString,
    this.tareWeightEnable,
    this.tareWeight,
    this.grossWeight,
    this.netWeight,
    this.time,
    this.serialNo,
  });

  NonBatchBarcodes.fromJson(Map<String, dynamic> json) {
    barCodeString = json['bar_code_string'];
    tareWeightEnable = json['tare_weight_enable'];
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
    data['bar_code_string'] = this.barCodeString;
    data['tare_weight_enable'] = this.tareWeightEnable;
    data['tare_weight'] = this.tareWeight;
    data['gross_weight'] = this.grossWeight;
    data['net_weight'] = this.netWeight;
    data['time'] = time?.toIso8601String(); // 🕒
    data['serial_no'] = serialNo.toString();
    return data;
  }
}

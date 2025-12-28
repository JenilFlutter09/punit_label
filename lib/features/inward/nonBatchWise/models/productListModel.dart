class productListModel {
  bool? status;
  String? message;
  List<Data>? data;

  productListModel({this.status, this.message, this.data});

  productListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? productId;
  String? productName;
  bool? autoWeight;
  double? minAutoWeight;
  double? maxAutoWeight;
  double? autoWeightSeconds;
  double? tareWeight;
  bool? unitConversion;
  String? unit;

  Data(
      {this.productId,
        this.productName,
        this.autoWeight,
        this.minAutoWeight,
        this.maxAutoWeight,
        this.autoWeightSeconds,this.tareWeight,this.unitConversion,
        this.unit});

  Data.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    autoWeight = json['auto_weight'];
    // minAutoWeight = json['min_auto_weight'].toDouble();
    // maxAutoWeight = json['max_auto_weight'].toDouble();
    // autoWeightSeconds = json['auto_weight_seconds'].toDouble();
    // tareWeight = json['tare_weight'].toDouble();
    tareWeight = (json['tare_weight'] as num?)?.toDouble();
    minAutoWeight = (json['min_auto_weight'] as num?)?.toDouble();
    maxAutoWeight = (json['max_auto_weight'] as num?)?.toDouble();
    autoWeightSeconds = (json['auto_weight_seconds'] as num?)?.toDouble();
    unitConversion = json['unit_conversion'];
    unit = json['unit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['auto_weight'] = this.autoWeight;
    data['min_auto_weight'] = this.minAutoWeight;
    data['max_auto_weight'] = this.maxAutoWeight;
    data['auto_weight_seconds'] = this.autoWeightSeconds;
    data['tare_weight'] = this.tareWeight;
    data['unit_conversion'] = this.unitConversion;
    data['unit'] = this.unit;
    return data;
  }
}

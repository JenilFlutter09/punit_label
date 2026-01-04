import '../../constants/utility.dart';

class TareProductListModel {
  bool? status;
  String? message;
  List<TareBarcode>? data;

  TareProductListModel({this.status, this.message, this.data});

  TareProductListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <TareBarcode>[];
      json['data'].forEach((v) {
        data!.add(new TareBarcode.fromJson(v));
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

class TareBarcode {
  String? productName;
  double? weight;
  String? barCodeString;

  TareBarcode({this.productName, this.weight, this.barCodeString});

  TareBarcode.fromJson(Map<String, dynamic> json) {
    productName = json['product_name'];
    weight = Utility.toDouble(json['weight']);
    barCodeString = json['bar_code_string'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_name'] = this.productName;
    data['weight'] = this.weight;
    data['bar_code_string'] = this.barCodeString;
    return data;
  }
}

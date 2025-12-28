class TareModel {
  List<TareProducts>? products;

  TareModel({this.products});

  TareModel.fromJson(Map<String, dynamic> json) {
    if (json['products'] != null) {
      products = <TareProducts>[];
      json['products'].forEach((v) {
        products!.add(new TareProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TareProducts {
  String? productName;
  double? weight;
  String? barCodeString;

  TareProducts({this.productName, this.weight, this.barCodeString});

  TareProducts.fromJson(Map<String, dynamic> json) {
    productName = json['product_name'];
    weight = json['weight'];
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

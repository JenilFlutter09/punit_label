class batchInwardModel {
  String? status;
  String? scaleName;
  String? scaleMac;
  List<InwardProducts>? products;

  batchInwardModel({this.status, this.scaleName, this.scaleMac,this.products});

  batchInwardModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    scaleName = json['scale_name'];
    scaleMac = json['scale_mac'];
    if (json['products'] != null) {
      products = <InwardProducts>[];
      json['products'].forEach((v) {
        products!.add(new InwardProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['scale_name'] = this.scaleName;
    data['scale_mac'] = this.scaleMac;
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class InwardProducts {
  int? batchProductId;
  List<BarCodes>? barCodes;

  InwardProducts({this.batchProductId, this.barCodes});

  InwardProducts.fromJson(Map<String, dynamic> json) {
    batchProductId = json['batch_product_id'];
    if (json['bar_codes'] != null) {
      barCodes = <BarCodes>[];
      json['bar_codes'].forEach((v) {
        barCodes!.add(new BarCodes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['batch_product_id'] = this.batchProductId;
    if (this.barCodes != null) {
      data['bar_codes'] = this.barCodes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BarCodes {
  String? barCodeString;
  bool? tareWeightEnable;
  double? tareWeight;
  double? grossWeight;
  double? netWeight;
  int? serialNo;

  BarCodes(
      {this.barCodeString,
        this.tareWeightEnable,
        this.tareWeight,
        this.grossWeight,
        this.netWeight,
        this.serialNo});

  BarCodes.fromJson(Map<String, dynamic> json) {
    barCodeString = json['bar_code_string'];
    tareWeightEnable = json['tare_weight_enable'];
    tareWeight = json['tare_weight'];
    grossWeight = json['gross_weight'];
    netWeight = json['net_weight'];
    serialNo = json['serial_no'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bar_code_string'] = this.barCodeString;
    data['tare_weight_enable'] = this.tareWeightEnable;
    data['tare_weight'] = this.tareWeight;
    data['gross_weight'] = this.grossWeight;
    data['net_weight'] = this.netWeight;
    data['serial_no'] = this.serialNo;
    return data;
  }
}


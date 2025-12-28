class dashboardModel {
  bool? status;
  String? message;
  Data? data;

  dashboardModel({this.status, this.message, this.data});

  dashboardModel.fromJson(Map<String, dynamic> json) {
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
  int? totalProducts;
  int? totalVariants;
  String? totalInventory;
  List<TopProducts>? topProducts;
  List<RecentProducts>? recentProdcts;
  List<LowStockProducts>? lowStockProducts;

  Data(
      {this.totalProducts,
        this.totalVariants,
        this.totalInventory,
        this.topProducts,
        this.recentProdcts,
        this.lowStockProducts});

  Data.fromJson(Map<String, dynamic> json) {
    totalProducts = json['total_products'];
    totalVariants = json['total_variants'];
    totalInventory = json['total_inventory'] == 0 ? "0" : json['total_inventory'];
    if (json['top_products'] != null) {
      topProducts = <TopProducts>[];
      json['top_products'].forEach((v) {
        topProducts!.add(new TopProducts.fromJson(v));
      });
    }
    if (json['recent_prodcts'] != null) {
      recentProdcts = <RecentProducts>[];
      json['recent_prodcts'].forEach((v) {
        recentProdcts!.add(new RecentProducts.fromJson(v));
      });
    }
    if (json['lowStockProducts'] != null) {
      lowStockProducts = <LowStockProducts>[];
      json['lowStockProducts'].forEach((v) {
        lowStockProducts!.add(new LowStockProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_products'] = this.totalProducts;
    data['total_variants'] = this.totalVariants;
    data['total_inventory'] = this.totalInventory;
    if (this.topProducts != null) {
      data['top_products'] = this.topProducts!.map((v) => v.toJson()).toList();
    }
    if (this.recentProdcts != null) {
      data['recent_prodcts'] =
          this.recentProdcts!.map((v) => v.toJson()).toList();
    }
    if (this.lowStockProducts != null) {
      data['lowStockProducts'] =
          this.lowStockProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TopProducts {
  dynamic productId;
  String? productNameSnapshot;
  String? productName;
  String? qty;

  TopProducts(
      {this.productId, this.productNameSnapshot, this.productName, this.qty});

  TopProducts.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productNameSnapshot = json['product_name_snapshot'];
    productName = json['product_name'];
    qty = json['qty'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name_snapshot'] = this.productNameSnapshot;
    data['product_name'] = this.productName;
    data['qty'] = this.qty;
    return data;
  }
}

class RecentProducts {
  int? id;
  dynamic adminId;
  String? productName;
  String? createdAt;
  String? updatedAt;
  dynamic autoWeight;
  dynamic autoWeightSeconds;
  dynamic minAutoWeight;
  dynamic maxAutoWeight;
  String? deletedAt;

  RecentProducts(
      {this.id,
        this.adminId,
        this.productName,
        this.createdAt,
        this.updatedAt,
        this.autoWeight,
        this.autoWeightSeconds,
        this.minAutoWeight,
        this.maxAutoWeight,
        this.deletedAt});

  RecentProducts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    adminId = json['admin_id'];
    productName = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    autoWeight = json['auto_weight'];
    autoWeightSeconds = json['auto_weight_seconds'];
    minAutoWeight = json['min_auto_weight'];
    maxAutoWeight = json['max_auto_weight'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['admin_id'] = this.adminId;
    data['name'] = this.productName;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['auto_weight'] = this.autoWeight;
    data['auto_weight_seconds'] = this.autoWeightSeconds;
    data['min_auto_weight'] = this.minAutoWeight;
    data['max_auto_weight'] = this.maxAutoWeight;
    data['deleted_at'] = this.deletedAt;
    return data;
  }
}
class LowStockProducts {
  dynamic productId;
  String? productNameSnapshot;
  String? productName;
  String? qty;

  LowStockProducts(
      {this.productId, this.productNameSnapshot, this.productName, this.qty});

  LowStockProducts.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productNameSnapshot = json['product_name_snapshot'];
    productName = json['product_name'];
    qty = json['qty'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name_snapshot'] = this.productNameSnapshot;
    data['product_name'] = this.productName;
    data['qty'] = this.qty;
    return data;
  }
}
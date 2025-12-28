class customerModel {
  bool? status;
  String? message;
  List<Customer>? data;

  customerModel({this.status, this.message, this.data});

  customerModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Customer>[];
      json['data'].forEach((v) {
        data!.add(new Customer.fromJson(v));
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

class Customer {
  int? id;
  int? adminId;
  String? name;
  String? mobile;
  String? email;
  String? address;
  String? notes;
  String? enabled;
  String? createdAt;
  String? updatedAt;

  Customer(
      {this.id,
        this.adminId,
        this.name,
        this.mobile,
        this.email,
        this.address,
        this.notes,
        this.enabled,
        this.createdAt,
        this.updatedAt});

  Customer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    adminId = json['admin_id'];
    name = json['name'];
    mobile = json['mobile'];
    email = json['email'];
    address = json['address'];
    notes = json['notes'];
    enabled = json['enabled'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['admin_id'] = this.adminId;
    data['name'] = this.name;
    data['mobile'] = this.mobile;
    data['email'] = this.email;
    data['address'] = this.address;
    data['notes'] = this.notes;
    data['enabled'] = this.enabled;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

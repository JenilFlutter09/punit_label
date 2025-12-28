class CompanyDetailsModel {
  bool? status;
  String? message;
  Data? data;

  CompanyDetailsModel({this.status, this.message, this.data});

  CompanyDetailsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}
class Data {
  String? name;
  String? email;
  String? contactNo;
  String? gstNo;
  String? address;
  String? logo;
  Map<String, dynamic>? labelFields; // <-- DYNAMIC

  Data({
    this.name,
    this.email,
    this.contactNo,
    this.gstNo,
    this.address,
    this.logo,
    this.labelFields,
  });

  Data.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    contactNo = json['contact_no'];
    gstNo = json['gst_no'];
    address = json['address'];
    logo = json['logo'];

    // Store full dynamic map
    labelFields = json['label_fields'] != null
        ? Map<String, dynamic>.from(json['label_fields'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'contact_no': contactNo,
      'gst_no': gstNo,
      'address': address,
      'logo': logo,
      'label_fields': labelFields,
    };
  }
}

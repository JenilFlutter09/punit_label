class CompanyDetailsModel {
  bool? status;
  String? message;
  CompanyData? data;

  CompanyDetailsModel({this.status, this.message, this.data});

  CompanyDetailsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? CompanyData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}
class CompanyData {
  String? name;
  String? email;
  String? contactNo;
  String? gstNo;
  String? address;
  String? website;
  String? logo;
  Map<String, dynamic>? labelFields; // <-- DYNAMIC

  CompanyData({
    this.name,
    this.email,
    this.contactNo,
    this.gstNo,
    this.address,
    this.website,
    this.logo,
    this.labelFields,
  });

  CompanyData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    contactNo = json['contact_no'];
    gstNo = json['gst_no'];
    address = json['address'];
    address = json['website'];
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
      'website': website,
      'logo': logo,
      'label_fields': labelFields,
    };
  }
}

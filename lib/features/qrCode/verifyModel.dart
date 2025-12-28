class verifyModel {
  bool? isVerified;
  int? mechanicId;
  String? message;

  verifyModel({this.isVerified, this.mechanicId, this.message});

  verifyModel.fromJson(Map<String, dynamic> json) {
    isVerified = json['is_verified'];
    mechanicId = json['mechanic_id'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_verified'] = this.isVerified;
    data['mechanic_id'] = this.mechanicId;
    data['message'] = this.message;
    return data;
  }
}

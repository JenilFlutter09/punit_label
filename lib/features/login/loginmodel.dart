class loginModel {
  bool? status;
  String? message;
  String? error;
  Data? data;

  loginModel({this.status, this.message, this.error, this.data});

  loginModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    error = json['error'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['error'] = this.error;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? accessToken;
  String? tokenType;
  int? expiresIn;
  UserProfile? userProfile;

  Data({this.accessToken, this.tokenType, this.expiresIn, this.userProfile});

  Data.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'];
    expiresIn = json['expires_in'];
    userProfile = json['user_profile'] != null
        ? UserProfile.fromJson(json['user_profile'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['access_token'] = this.accessToken;
    data['token_type'] = this.tokenType;
    data['expires_in'] = this.expiresIn;
    if (this.userProfile != null) {
      data['user_profile'] = this.userProfile!.toJson();
    }
    return data;
  }
}

class UserProfile {
  String? name;
  String? email;
  bool? inventoryUser;
  bool? dispatchUser;
  String? companyCode;

  UserProfile(
      {this.name,
        this.email,
        this.inventoryUser,
        this.dispatchUser,
        this.companyCode});

  UserProfile.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    inventoryUser = json['inventory_user'];
    dispatchUser = json['dispatch_user'];
    companyCode = json['company_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['inventory_user'] = this.inventoryUser;
    data['dispatch_user'] = this.dispatchUser;
    data['company_code'] = this.companyCode;
    return data;
  }
}

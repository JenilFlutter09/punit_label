class NonBatchListModel {
  bool? status;
  String? message;
  List<Entity>? data;

  NonBatchListModel({this.status, this.message, this.data});

  NonBatchListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Entity>[];
      json['data'].forEach((v) {
        data!.add(new Entity.fromJson(v));
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

class Entity {
  int? id;
  String? name;
  String? scaleName;
  String? scaleMac;

  Entity({this.id, this.name, this.scaleName, this.scaleMac});

  Entity.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    scaleName = json['scale_name'];
    scaleMac = json['scale_mac'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['scale_name'] = this.scaleName;
    data['scale_mac'] = this.scaleMac;
    return data;
  }
}

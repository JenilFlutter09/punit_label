class attributesListModel {
  bool? status;
  String? message;
  List<Attribute>? data;

  attributesListModel({this.status, this.message, this.data});

  attributesListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Attribute>[];
      json['data'].forEach((v) {
        data!.add(new Attribute.fromJson(v));
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

class Attribute {
  int? attributeId;
  String? attributeName;
  List<Options>? options;

  Attribute({this.attributeId, this.attributeName, this.options});

  Attribute.fromJson(Map<String, dynamic> json) {
    attributeId = json['attribute_id'];
    attributeName = json['attribute_name'];
    if (json['options'] != null) {
      options = <Options>[];
      json['options'].forEach((v) {
        options!.add(new Options.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['attribute_id'] = this.attributeId;
    data['attribute_name'] = this.attributeName;
    if (this.options != null) {
      data['options'] = this.options!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Options {
  int? optionsId;
  String? optionsName;

  Options({this.optionsId, this.optionsName});

  Options.fromJson(Map<String, dynamic> json) {
    optionsId = json['options_id'];
    optionsName = json['options_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['options_id'] = this.optionsId;
    data['options_name'] = this.optionsName;
    return data;
  }
}

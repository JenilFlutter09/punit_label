class batchListModel {
  bool? status;
  String? message;
  List<batch>? data;

  batchListModel({this.status, this.message, this.data});

  batchListModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <batch>[];
      json['data'].forEach((v) {
        data!.add(new batch.fromJson(v));
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

class batch {
  int? id;
  String? batchName;

  batch({this.id, this.batchName});

  batch.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    batchName = json['batch_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['batch_name'] = this.batchName;
    return data;
  }
}

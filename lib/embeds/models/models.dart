class FileModel {
  String? url;
  // local or web
  String? type;
  String? uuid;
  String? description;

  FileModel({this.url, this.type, this.uuid, this.description});

  FileModel.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    type = json['type'];
    uuid = json['uuid'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['type'] = type;
    data['uuid'] = uuid;
    data['description'] = description;
    return data;
  }

  bool validate() {
    return url != null && type != null && uuid != null;
  }
}

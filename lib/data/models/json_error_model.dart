class JsonErrorModel {
  List<Errors>? errors;

  JsonErrorModel({this.errors});

  JsonErrorModel.fromJson(Map<String, dynamic> json) {
    if (json['errors'] != null) {
      errors = <Errors>[];
      json['errors'].forEach((v) {
        errors!.add(Errors.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (errors != null) {
      data['errors'] = errors!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Errors {
  String? type;
  String? originalText;
  String? suggestedFix;

  Errors({this.type, this.originalText, this.suggestedFix});

  Errors.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    originalText = json['original_text'];
    suggestedFix = json['suggested_fix'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['original_text'] = originalText;
    data['suggested_fix'] = suggestedFix;
    return data;
  }
}

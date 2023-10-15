class AminoModel {
  String? code;
  double? weight;

  AminoModel({
    this.code,
    this.weight,
  });

  AminoModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    weight = json['weight'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['weight'] = weight;
    return data;
  }
}

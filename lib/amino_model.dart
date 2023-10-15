class AminoModel {
  String? code;
  double? waterWeight;
  double? weight;

  AminoModel({
    this.code,
    this.waterWeight,
    this.weight,
  });

  AminoModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    waterWeight = json['waterWeight'];
    weight = json['weight'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['waterWeight'] = waterWeight;
    data['weight'] = weight;
    return data;
  }
}

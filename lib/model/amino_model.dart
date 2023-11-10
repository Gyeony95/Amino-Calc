class AminoModel {
  String? code;
  double? totalWeight;
  double? waterWeight;
  double? weight;

  AminoModel({
    this.code,
    this.totalWeight,
    this.waterWeight,
    this.weight,
  });

  AminoModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    totalWeight = json['totalWeight'];
    waterWeight = json['waterWeight'];
    weight = json['weight'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['totalWeight'] = totalWeight;
    data['waterWeight'] = waterWeight;
    data['weight'] = weight;
    return data;
  }
}

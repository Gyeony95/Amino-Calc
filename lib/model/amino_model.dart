import 'package:mass_finder/widget/formylation_selector.dart';
import 'package:mass_finder/widget/ion_selector.dart';

class AminoModel {
  String? code;
  double? totalWeight;
  double? waterWeight;
  double? weight;


  // 결과를 그려주기 위한 값들
  FormyType? formyType;
  IonType? ionType;
  String? essentialSeq;

  AminoModel({
    this.code,
    this.totalWeight,
    this.waterWeight,
    this.weight,
    this.formyType,
    this.ionType,
    this.essentialSeq,
  });

  AminoModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    totalWeight = json['totalWeight'];
    waterWeight = json['waterWeight'];
    weight = json['weight'];
    formyType = FormyType.decode(json['formyType']);
    ionType = IonType.decode(json['ionType']);
    essentialSeq = json['essentialSeq'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['totalWeight'] = totalWeight;
    data['waterWeight'] = waterWeight;
    data['weight'] = weight;
    data['formyType'] = formyType?.text;
    data['ionType'] = ionType?.text;
    data['essentialSeq'] = essentialSeq;
    return data;
  }
}

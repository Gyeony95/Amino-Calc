import 'package:mass_finder/model/amino_model.dart';

class BaseModel {
  int? resultCode;
  String? resultMessage;
  List<AminoModel>? data;

  BaseModel({this.resultCode, this.resultMessage, this.data});

  BaseModel.fromJson(Map<String, dynamic> json) {
    resultCode = json['resultCode'];
    resultMessage = json['resultMessage'];
    if (json['data'] != null) {
      data = <AminoModel>[];
      json['data'].forEach((v) {
        data!.add(AminoModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['resultCode'] = resultCode;
    data['resultMessage'] = resultMessage;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
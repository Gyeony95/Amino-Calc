
import 'package:mass_finder/model/amino_model.dart';
import 'package:mass_finder/model/base_model.dart';
import 'package:mass_finder/network/dio_network.dart';

class DioConnect {
  DioConnect._() : super() {
    _instance = this;
  }

  // lazy initialization
  factory DioConnect() => _instance ?? DioConnect._();

  // single tone member
  static DioConnect? _instance;

  final _dio = DioNetwork().dio;

  Future<List<AminoModel>?> calcMass({
    required double totalWeight,
    required String initAmino,
    required String currentFormyType,
    required String currentIonType,
    required Map<String, double> inputAminos,
  }) async {
    final dio = await _dio;
    final res = await dio.post(
      'mass_finder_app/api/calc_mass',
      data: {
        'totalWeight': totalWeight,
        'initAmino': initAmino,
        'currentFormyType': currentFormyType,
        'currentIonType': currentIonType,
        'inputAminos': inputAminos,
      },
    );
    final resModel = BaseModel.fromJson(res.data);
    if(resModel.resultCode != 200) return null;
    return resModel.data;
  }
}

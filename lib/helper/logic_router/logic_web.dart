part of 'logic_helper.dart';

class _LogicWeb extends _LogicRepository {
  @override
  void init(Function(dynamic) callback) {

  }

  @override
  List<AminoModel>? onTapCalc(
    double totalWeight,
    String initAmino,
    String formyType,
    String ionType,
    Map<String, double> inputAminos,
    BuildContext context,
  ) {
    double w = totalWeight;
    String a = initAmino;
    String f = formyType;
    String i = ionType;
    Map<String, double> ia = inputAminos;
    final message = MassFinderHelperV2.calcByIonType(null, w, a, f, i, ia);

    var mapList = message as List<Map<String, dynamic>>;
    var responseList = mapList.map((e) => AminoModel.fromJson(e)).toList();
    if (responseList.isEmpty) {
      AlertToast.show(context: context, msg: '결과값을 찾지 못했습니다.');
    }
    return responseList;
  }
}

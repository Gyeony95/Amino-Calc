part of 'logic_helper.dart';

class _LogicApp extends _LogicRepository {
  final _receivePort = ReceivePort();

  @override
  void init(Function(dynamic) callback) {
    _receivePort.listen(callback);
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
    try {
      Isolate.spawn<SendPort>(
        (sp) => MassFinderHelperV2.calcByIonType(sp, w, a, f, i, ia),
        _receivePort.sendPort,
      );
    } catch (e) {
      AlertToast.show(context: context, msg: 'error occurred!!');
    }
    return null;
  }
}

part of 'logic_helper.dart';

abstract class _LogicRepository {
  void init(Function(dynamic) callback);

  void onTapCalc(
    double totalWeight,
    String initAmino,
    String formyType,
    String ionType,
    Map<String, double> inputAminos,
    BuildContext context,
  );
}

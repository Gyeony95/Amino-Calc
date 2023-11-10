import 'dart:isolate';

import 'package:mass_finder/util/alert_toast.dart';
import 'package:mass_finder/mass_finder_helper.dart';
import 'package:mass_finder/model/amino_model.dart';
import 'package:mass_finder/widget/loading_overlay.dart';
import 'package:mass_finder/widget/normal_text_field.dart';
import 'package:flutter/material.dart';

class MassFinderScreen extends StatefulWidget {
  const MassFinderScreen({Key? key}) : super(key: key);

  @override
  State<MassFinderScreen> createState() => _MassFinderScreenState();
}

class _MassFinderScreenState extends State<MassFinderScreen> {
  TextEditingController targetWeight = TextEditingController();
  TextEditingController targetSize = TextEditingController();
  TextEditingController initAmino = TextEditingController();

  double get _targetWeight => textToDouble(targetWeight.text);

  List<AminoModel> resultList = [];

  final _receivePort = ReceivePort();
  bool isLoading = false;

  static double? totalWeight;

  @override
  void initState() {
    super.initState();
    _receivePort.listen((message) {
      setState(() {
        var mapList = message as List<Map<String, dynamic>>;
        resultList = mapList.map((e) => AminoModel.fromJson(e)).toList();
        isLoading = false;
      });
    });

    targetWeight.addListener(() {
      totalWeight = _targetWeight * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: LoadingOverlay(
            color: Colors.black12,
            isLoading: isLoading,
            child: SelectionArea(child: Center(child: _buildBody())),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.all(40),
      constraints: const BoxConstraints(
        maxWidth: 500,
        minWidth: 300,
      ),
      child: Column(
        children: [
          const Text(
            'Mass finder',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          NormalTextField(
            textController: targetWeight,
            labelText: 'Exact Mass', // 총 단백질의 무게
            digitOnly: false,
            hintText: 'please enter exact mass(only digit)', // 숫자만 입력
          ),
          const SizedBox(height: 10),
          NormalTextField(
            textController: initAmino,
            labelText: 'Essential Sequence (Option)',
            hintText: 'please enter essential sequence (olny alphabet)',
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => onTapCalc(context),
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              child: const Text('Calcualtion!'),
            ),
          ),
          const SizedBox(height: 10),
          _resultArea(),
        ],
      ),
    );
  }

  Widget _resultArea() {
    return Expanded(
      child: SingleChildScrollView(
        child: _examplePERList(),
      ),
    );
  }

  Widget _examplePERList() {
    return ListView.builder(
      itemCount: resultList.length,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (_, index) {
        return _exampleListItem(resultList[index]);
      },
    );
  }

  Widget _exampleListItem(AminoModel item) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sequence : ${item.code}'),
          // Text('물 증발 전 무게 : ${item.totalWeight}'),
          // Text('물 증발량 : ${item.waterWeight}'),
          Text('Exact Mass : ${item.weight}'),
        ],
      ),
    );
  }

  double textToDouble(String value) {
    var convert = double.tryParse(value);
    if (convert == null) {
      print('계산에 오류가 발생했습니다.');
      // Fluttertoast.showToast(msg: '계산에 오류가 발생했습니다.');
      return 1.0;
    }
    return convert;
  }

  int textToInt(String value) {
    var convert = int.tryParse(value);
    if (convert == null) {
      print('계산에 오류가 발생했습니다.');
      // Fluttertoast.showToast(msg: '계산에 오류가 발생했습니다.');
      return 1;
    }
    return convert;
  }

  /// 계산하기 클릭 이벤트
  Future<void> onTapCalc(BuildContext context) async {
    if (totalWeight == null) {
      AlertToast.show(context: context, msg: 'please enter extra mass!');
      return;
    }
    resultList.clear();
    isLoading = true;
    setState(() {});
    double w = totalWeight ?? 0.0;
    String a = initAmino.text;

    try{
      Isolate.spawn<SendPort>(
            (sp) => MassFinderHelper.calc(sp, w, 20, a),
        _receivePort.sendPort,
      );
    }catch(e){
      AlertToast.show(context: context, msg: 'error occurred!!');
    }

  }
}

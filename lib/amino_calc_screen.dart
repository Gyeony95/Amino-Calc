import 'dart:isolate';

import 'package:amino_calc/alert_toast.dart';
import 'package:amino_calc/amino_calc_helper.dart';
import 'package:amino_calc/amino_model.dart';
import 'package:amino_calc/loading_overlay.dart';
import 'package:amino_calc/normal_text_field.dart';
import 'package:flutter/material.dart';

class AminoCalcScreen extends StatefulWidget {
  const AminoCalcScreen({Key? key}) : super(key: key);

  @override
  State<AminoCalcScreen> createState() => _AminoCalcScreenState();
}

class _AminoCalcScreenState extends State<AminoCalcScreen> {
  TextEditingController targetWeight = TextEditingController();
  TextEditingController targetSize = TextEditingController();
  TextEditingController initAmino = TextEditingController();

  double get _targetWeight => textToDouble(targetWeight.text);

  int get _targetSize => textToInt(targetSize.text);

  List<AminoModel> resultList = [];

  final _receivePort = ReceivePort();
  bool isLoading = false;

  static double? totalWeight;
  static int? totalSize;

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
    targetSize.addListener(() {
      totalSize = _targetSize;
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
            labelText: '총 단백질 무게 (필수)',
            digitOnly: false,
            hintText: '총 단백질 무게를 입력하세요(숫자만 입력)',
          ),
          const SizedBox(height: 10),
          NormalTextField(
            textController: targetSize,
            labelText: '출력할 조합의 수 (필수)',
            digitOnly: true,
            hintText: '출력하고자 하는 조합의 수 입력(숫자만 입력)',
          ),
          const SizedBox(height: 10),
          NormalTextField(
            textController: initAmino,
            labelText: '필수 아미노산 시퀀스 (선택)',
            hintText: '출력하고자 하는 조합의 수 입력(알파벳만 입력)',
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => onTapCalc(context),
            child: Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              child: const Text('계산하기'),
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
          Text('아미노산 조합 : ${item.code}'),
          // Text('물 증발 전 무게 : ${item.totalWeight}'),
          // Text('물 증발량 : ${item.waterWeight}'),
          Text('분자량 : ${item.weight}'),
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
    if (totalWeight == null || totalSize == null) {
      AlertToast.show(context: context, msg: '필수값을 입력해주세요.');
      return;
    }
    resultList.clear();
    isLoading = true;
    setState(() {});
    double w = totalWeight ?? 0.0;
    int s = totalSize ?? 0;
    String a = initAmino.text;
    Isolate.spawn<SendPort>(
      (sp) => AminoCalcHelper.calc(sp, w, s, a),
      _receivePort.sendPort,
    );
  }
}

import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:mass_finder/helper/mass_finder_helper.dart';
import 'package:mass_finder/util/alert_toast.dart';
import 'package:mass_finder/model/amino_model.dart';
import 'package:mass_finder/widget/amino_map_selector.dart';
import 'package:mass_finder/widget/formylation_selector.dart';
import 'package:mass_finder/widget/ion_selector.dart';
import 'package:mass_finder/widget/loading_overlay.dart';
import 'package:mass_finder/widget/ncaa_input_area.dart';
import 'package:mass_finder/widget/normal_text_field.dart';
import 'package:flutter/material.dart';

import 'widget/highlight_text.dart';

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

  FormyType currentFormyType = FormyType.unknown;
  IonType currentIonType = IonType.H;

  // 계산시에 사용할 아미노산 리스트 , 최초에는 모든 아미노산을 포함한다.
  Map<String, double> inputAminos = Map.from(aminoMap);

  // ncaa의 입력값을 받는 변수
  Map<String, double> ncaaMap = {};

  double get _maxWidth => 500;
  double get _minWidth => 300;

  late BuildContext screenContext;

  @override
  void initState() {
    super.initState();
    _receivePort.listen((message) {
      setState(() {
        var mapList = message as List<Map<String, dynamic>>;
        var responseList = mapList.map((e) => AminoModel.fromJson(e)).toList();
        resultList.addAll(responseList);
        if(resultList.isEmpty){
          AlertToast.show(context: screenContext, msg: '결과값을 찾지 못했습니다.');
        }
        isLoading = false;
      });
    });

    targetWeight.addListener(() {
      totalWeight = _targetWeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenContext = context;
    return Scaffold(
      backgroundColor: Colors.white,
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
      constraints: BoxConstraints(
        maxWidth: _maxWidth,
        minWidth: _minWidth,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _maxWidth,
              child: const Text(
                'Mass finder',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            NormalTextField(
              textController: targetWeight,
              labelText: 'Exact Mass', // 총 단백질의 무게
              hintText: 'please enter exact mass(only digit)', // 숫자만 입력
            ),
            const SizedBox(height: 10),
            NormalTextField(
              textController: initAmino,
              labelText: 'Essential Sequence (Option)',
              inputFormatters: [UpperCaseTextFormatter()],
              hintText: 'please enter essential sequence (olny alphabet)',
            ),
            const SizedBox(height: 10),
            // f 있는지 여부
            FormylationSelector(
              fomyType: currentFormyType,
              onChange: (newType) {
                setState(() {
                  currentFormyType = newType;
                });
              },
            ),
            const SizedBox(height: 5),
            // 이온 선택
            IonSelector(
              fomyType: currentIonType,
              onChange: (newType) {
                setState(() {
                  currentIonType = newType;
                });
              },
            ),
            const SizedBox(height: 5),
            // 아미노산 종류 선택부분
            AminoMapSelector(
              onChangeAminos: (aminos) {
                var selectedAminos = Map.from(aminos);
                selectedAminos.removeWhere((k, v) => v == false);
                inputAminos.clear();
                for (var e in selectedAminos.keys) {
                  inputAminos[e] = aminoMap[e] ?? 0;
                }
              },
            ),
            const SizedBox(height: 10),
            NcAAInputArea(
              initNcAA: ncaaMap,
              onChangeNcAA: (_map){
              _map.removeWhere((k, v) => v == 0.0);
              ncaaMap = _map;
            },),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => onTapCalc(context),
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                child: const Text('Calculate!'),
              ),
            ),
            const SizedBox(height: 10),
            _aminoList(),
          ],
        ),
      ),
    );
  }

  Widget _aminoList() {
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
          // Text('Sequence : ${item.code}'),
          seqStringBuilder(item),
          // Text('물 증발 전 무게 : ${item.totalWeight}'),
          // Text('물 증발량 : ${item.waterWeight}'),
          Text('Exact Mass : ${item.weight}'),
          // Text('Similarity : ${item.similarity}%'),
          Text('Difference : ${((totalWeight ?? 0) - (item.weight ?? 0)).abs()}')
        ],
      ),
    );
  }

  /// init값, ion값 등에 따라 텍스트를 만들어주는 위젯
  Widget seqStringBuilder(AminoModel item) {

    String code = '';
    String ncaa = '';
    item.code = (item.code ?? '').replaceFirst(item.essentialSeq ?? '', '');
    List<String> seqList = (item.code ?? '').split('');
    for(var seq in seqList){
      if(isNcAA(seq)){
        ncaa = '$ncaa$seq';
      }else{
        code = '$code$seq';
      }
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(text: code),
          TextSpan(text: item.essentialSeq ?? '', style: const TextStyle(color: Colors.blue)),
          TextSpan(text: ncaa, style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: ' + ${item.ionType?.text ?? ''}'),
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
    if (validate(context) == false) return;
    resultList.clear();
    isLoading = true;
    setState(() {});
    double w = totalWeight ?? 0.0;
    String a = initAmino.text;
    String f = currentFormyType.text;
    String i = currentIonType.text;
    Map<String, double> ia = inputAminos;
    // ncaa 적용
    ia.addAll(ncaaMap);
    try {
      Isolate.spawn<SendPort>(
        (sp) => MassFinderHelperV2.calcByIonType(sp, w, a, f, i, ia),
        _receivePort.sendPort,
      );
    } catch (e) {
      AlertToast.show(context: context, msg: 'error occurred!!');
    }
  }

  // 계산 시작전 각종 조건을 체크하는 부분
  bool validate(BuildContext context) {
    String? validText = getValidateMsg();
    if (validText == null) return true;
    AlertToast.show(msg: validText, context: context);
    return false;
  }

  // 실제 각 조건별 메세지를 셋팅하는 부분
  String? getValidateMsg() {
    String? msg;
    // 체크박스에 포함되지 않은값을 초기값으로 넣으려고 할때
    initAmino.text = initAmino.text.replaceAll(' ', '');
    String initAminoText = initAmino.text;
    initAminoText.split('').forEach((e) {
      if (inputAminos[e] == null && ncaaMap[e] == null) {
        msg = '체크박스와 ncAA에 포함 되어있지 않은 값이 Essential Sequence에 들어있음';
      }
    });
    // exact mass 값을 안넣었을때
    if (totalWeight == null || targetWeight.text.isEmpty) {
      msg = 'please enter exact mass!';
    }

    Map<String, double> ia = inputAminos;
    ia.addAll(ncaaMap);
    if(ia.isEmpty){
      msg = '사용 가능한 아미노산이 없습니다.';
    }
    return msg;
  }
}

/// 아미노산들의 리스트
final aminoMap = {
  'G': 75.03,
  'A': 89.05,
  'S': 105.04,
  'T': 119.06,
  'C': 121.02,
  'V': 117.08,
  'L': 131.09,
  'I': 131.09,
  'M': 149.05,
  'P': 115.06,
  'F': 165.08,
  'Y': 181.07,
  'W': 204.09,
  'D': 133.04,
  'E': 147.05,
  'N': 132.05,
  'Q': 146.07,
  'H': 155.07,
  'K': 146.11,
  'R': 174.11,
};

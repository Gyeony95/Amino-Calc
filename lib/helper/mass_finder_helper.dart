import 'dart:isolate';

import 'package:mass_finder/model/amino_model.dart';
import 'package:mass_finder/widget/formylation_selector.dart';

part 'mass_finder_helper_support.dart';

// 총무게까지만 계산하면 물 증발량 계산이 안돼서 여유있게 넣어놓는 가중치
double addWeight = 100000.0;
// formylation 의 무게(실제로는 27.99지만 모든 아미노산의 무게에 100을 곱해서 정수로 처리함)
double fWeight = 2799.0;

class MassFinderHelper {
  static FormyType _formyType = FormyType.unknown;

  /// [totalWeight] : 단백질의 총 무게
  /// [totalSize] : 출력할 아미노산 조합의 숫자
  /// [initAminos] : 필수로 포함되어야하는 아미노산들
  static calc(SendPort sendPort, double totalWeight, String initAminos,
      String fomyType, Map<String, int> aminoMap) {
    _formyType = FormyType.decode(fomyType);

    // 케이스 별로 리스트 담아줄곳
    List<AminoModel> aminoList = [];

    // 필수 아미노산이 있다면 총 무게에서 제거처리
    if (initAminos.isNotEmpty) {
      initAminos = initAminos.toUpperCase();
      List<String> aminos = initAminos.split('');
      aminos.map((e) {
        totalWeight = totalWeight - (aminoMap[e] ?? 0);
      }).toList();
    }

    switch (_formyType) {
      case FormyType.y:
        aminoList = getHaveFormyList(
            aminoMap, totalWeight - fWeight, initAminos);
        break;
      case FormyType.n:
        aminoList =
            getDonHaveFormyList(aminoMap, totalWeight, initAminos);
        break;
      case FormyType.unknown:
        aminoList = getUnknownFormyList(aminoMap, totalWeight, initAminos);
        break;
    }

    // isolate 로 리턴할 수 있는 형태로 바꿔줌
    List<Map<String, dynamic>> sendData =
        aminoList.map((e) => e.toJson()).toList();
    sendPort.send(sendData);
  }

  /// f 있을때
  static List<AminoModel> getHaveFormyList(
      Map<String, int> aminoMap, double totalWeight, String initAminos) {
    List<AminoModel> aminoList = [];
    aminoList = findClosestWeightCombinations(
        aminoMap, totalWeight + addWeight, initAminos);
    aminoList.map((e) {
      e.weight = (e.weight ?? 0) + fWeight / 100;
      e.code = 'f${e.code}';
    }).toList();
    return aminoList;
  }

  /// f 없을때
  static List<AminoModel> getDonHaveFormyList(
      Map<String, int> aminoMap, double totalWeight, String initAminos) {
    List<AminoModel> aminoList = [];
    aminoList = findClosestWeightCombinations(
        aminoMap, totalWeight + addWeight, initAminos);
    return aminoList;
  }

  /// f 있는지 없는지 모를때 있는거 없는거 둘다 뽑고 나열해서 재정렬한 뒤 20개로 자름
  static List<AminoModel> getUnknownFormyList(
      Map<String, int> aminoMap, double totalWeight, String initAminos) {
    List<AminoModel> aminoList = [];
    List<AminoModel> haveList = getHaveFormyList(
        aminoMap, totalWeight - fWeight, initAminos);
    List<AminoModel> donHaveList =
        getDonHaveFormyList(aminoMap, totalWeight, initAminos);
    aminoList = [...haveList, ...donHaveList];
    double initAminoWeight = _getInitAminoWeight(initAminos, aminoMap);
    double compareValue = (totalWeight + initAminoWeight - addWeight) / 100;
    int _totalSize = aminoList.length > 20 ? 20 : aminoList.length;
    return sortAmino(aminoList, compareValue).sublist(0,_totalSize);
  }

  /// 결과값(분자량)과 아미노산의 종류, 필수로 들어갈 아미노산 들을 입력받고
  /// 결과값에 가장 가까운 무게를 가지는 조합순으로 리턴해줌
  /// 이 함수에 넣어줄 totalWeight 에는 가중치 (addWeight) 를 더해서 전달
  static List<AminoModel> findClosestWeightCombinations(
      Map<String, int> aminoMap, double totalWeight, String initAminos) {
    // 총 무게만큼의 리스트 생성
    List<double> dp = List.filled(totalWeight.toInt() + 1, double.infinity);
    // 총 무게 만큼의 빈 리스트 생성
    List<List<String>> combinations = List.filled(totalWeight.toInt() + 1, []);
    List<AminoModel> resultList = [];
    dp[0] = 0;

    // 사용되는 아미노맵의 숫자만큼 반복
    for (var weight in aminoMap.values) {
      // 각 아미노산의 무게부터 총 무게가 될때까지 반복
      for (var i = weight.toInt(); i <= totalWeight; i++) {
        if (dp[i] > dp[i - weight.toInt()] + 1) {
          dp[i] = dp[i - weight.toInt()] + 1;
          combinations[i] = List.from(combinations[i - weight.toInt()])
            ..add(_getAminoByWeight(aminoMap, weight));
        }
      }
    }

    if (dp[totalWeight.toInt()] == double.infinity) {
      print("불가능한 조합입니다.");
    } else {
      for (var i = 0; i < combinations.length; i++) {
        // 각 조합의 맨 앞에 필수값 추가
        combinations[i] = [...initAminos.split(''), ...combinations[i]];
        // 각 아미노산 총 무게
        final sum = combinations[i]
                .map((amino) => aminoMap[amino] ?? 0)
                .fold(0.0, (sum, e) => sum + e) /
            100;
        // 물 증발량
        final waterWeight = _getWaterWeight(combinations[i].length);
        var aminoString = combinations[i].join('');
        // print('$aminoString, $waterWeight, $sum, ${sum - waterWeight}');
        resultList.add(AminoModel(
          code: aminoString,
          totalWeight: sum,
          waterWeight: waterWeight,
          weight: sum - waterWeight,
        ));
      }
    }
    // 예외처리 해놨던 아미노산들의 무게
    double initAminoWeight = _getInitAminoWeight(initAminos, aminoMap);
    // 크기순으로 정렬
    resultList.sort((a, b) => (a.weight ?? 0).compareTo(b.weight ?? 0));
    double compareValue = (totalWeight + initAminoWeight - addWeight) / 100;
    // 가장 목표값에 가까운 index 도출
    int mustIndex = 0;
    for (var i = 0; i < resultList.length; i++) {
      double currentValue =
          ((resultList[mustIndex].weight ?? 0) - compareValue).abs();
      double newValue = ((resultList[i].weight ?? 0) - compareValue).abs();
      if (currentValue > newValue) {
        mustIndex = i;
      }
    }
    resultList = sortAmino(resultList, compareValue);
    // // 입력값에 가까운 순서대로 정렬
    // resultList.sort((a, b) {
    //   if (a.weight == null && b.weight == null) {
    //     return 0;
    //   } else if (a.weight == null) {
    //     return 1;
    //   } else if (b.weight == null) {
    //     return -1;
    //   } else {
    //     final double diffA = (a.weight! - compareValue).abs();
    //     final double diffB = (b.weight! - compareValue).abs();
    //     return diffA.compareTo(diffB);
    //   }
    // });

    int _totalSize = resultList.length > 20 ? 20 : resultList.length;
    return resultList.sublist(0, _totalSize);
  }
}

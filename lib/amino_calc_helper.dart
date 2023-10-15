import 'dart:isolate';

import 'package:amino_calc/amino_model.dart';

class AminoCalcHelper {
  /// [totalWeight] : 단백질의 총 무게
  /// [totalSize] : 출력할 아미노산 조합의 숫자
  /// [initAminos] : 필수로 포함되어야하는 아미노산들
  static calc(
      SendPort sendPort, double totalWeight, int totalSize, String initAminos) {
    final aminoMap = {
      'G': 75030,
      'A': 89050,
      'S': 10504,
      'T': 11906,
      'C': 12102,
      'V': 11708,
      'L': 13109,
      'I': 13109,
      'M': 14905,
      'P': 11506,
      'F': 16508,
      'Y': 18107,
      'W': 20409,
      'D': 13304,
      'E': 14705,
      'N': 13205,
      'Q': 14607,
      'H': 15507,
      'K': 14611,
      'R': 17411,
    };
    // 필수 아미노산이 있다면 총 무게에서 제거처리
    if (initAminos.isNotEmpty) {
      initAminos = initAminos.toUpperCase();
      List<String> aminos = initAminos.split('');
      aminos.map((e) {
        totalWeight = totalWeight - (aminoMap[e] ?? 0);
      }).toList();
    }
    List<AminoModel> aminoList = findClosestWeightCombinations(
        aminoMap, totalWeight, totalSize, initAminos);
    List<Map<String, dynamic>> sendData =
        aminoList.map((e) => e.toJson()).toList();
    sendPort.send(sendData);
  }

  static List<AminoModel> findClosestWeightCombinations(
      Map<String, int> aminoMap,
      double totalWeight,
      int totalSize,
      String initAminos) {
    List<double> dp = List.filled(totalWeight.toInt() + 1, double.infinity);
    List<List<String>> combinations = List.filled(totalWeight.toInt() + 1, []);
    List<AminoModel> resultList = [];
    dp[0] = 0;

    for (var weight in aminoMap.values) {
      for (var i = weight.toInt(); i <= totalWeight; i++) {
        if (dp[i] > dp[i - weight.toInt()] + 1) {
          dp[i] = dp[i - weight.toInt()] + 1;
          combinations[i] = List.from(combinations[i - weight.toInt()])
            ..add(getAminoByWeight(aminoMap, weight));
        }
      }
    }

    if (dp[totalWeight.toInt()] == double.infinity) {
      print("불가능한 조합입니다.");
    } else {
      var resultCombinations = combinations.sublist(
          combinations.length - totalSize, combinations.length);
      for (var i = 0; i < resultCombinations.length; i++) {
        resultCombinations[i] = [
          ...initAminos.split(''),
          ...resultCombinations[i]
        ];
        // 각 아미노산 총 무게
        final sum = resultCombinations[i]
                .map((amino) => aminoMap[amino] ?? 0)
                .fold(0.0, (sum, e) => sum + e) /
            100;
        // 물 증발량
        final waterWeight = 18.01 * (resultCombinations[i].length - 1);
        var aminoString = groupAndCount(resultCombinations[i].join(''));
        print('$aminoString, $waterWeight, $sum');
        resultList.add(AminoModel(
          code: aminoString,
          totalWeight: sum,
          waterWeight: waterWeight,
          weight: sum - waterWeight,
        ));
      }
    }
    return resultList;
  }

  static String getAminoByWeight(Map<String, int> aminoMap, int weight) {
    for (var entry in aminoMap.entries) {
      if (entry.value == weight) {
        return entry.key;
      }
    }
    return "";
  }

  static String groupAndCount(String input) {
    if (input.isEmpty) {
      return ""; // 빈 문자열에 대한 처리
    }

    String result = "";
    int count = 1;

    for (int i = 1; i < input.length; i++) {
      if (input[i] == input[i - 1]) {
        count++;
      } else {
        result += "${input[i - 1]}$count";
        count = 1;
      }
    }

    // 마지막 알파벳과 그 횟수를 추가
    result += "${input[input.length - 1]}$count";

    return result;
  }
}

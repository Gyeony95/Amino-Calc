import 'dart:isolate';

import 'package:amino_calc/amino_model.dart';

class AminoCalcHelper {
  static calc(SendPort sendPort, double totalWeight, int totalSize){
    final aminoMap = {
      'G': 57021,
      'A': 71037,
      'S': 87032,
      'P': 97052,
      'V': 99068,
      'T': 101047,
      'C': 103009,
      'I': 113084,
      'L': 113084,
      'N': 114042,
      'D': 115026,
      'Q': 128058,
      'K': 128094,
      'E': 129042,
      'M': 131040,
      'H': 137058,
      'F': 147068,
      'R': 156101,
      'Y': 163063,
      'W': 186079
    };
    List<AminoModel> aminoList = findClosestWeightCombinations(aminoMap, totalWeight, totalSize);
    List<Map<String, dynamic>> sendData = aminoList.map((e) => e.toJson()).toList();
    sendPort.send(sendData);
  }


  static List<AminoModel> findClosestWeightCombinations(Map<String, int> aminoMap, double totalWeight, int totalSize) {
    List<double> dp = List.filled(totalWeight.toInt() + 1, double.infinity);
    List<List<String>> combinations = List.filled(totalWeight.toInt() + 1, []);
    List<AminoModel> resultList = [];
    dp[0] = 0;

    for (var weight in aminoMap.values) {
      for (var i = weight.toInt(); i <= totalWeight; i++) {
        if (dp[i] > dp[i - weight.toInt()] + 1) {
          dp[i] = dp[i - weight.toInt()] + 1;
          combinations[i] = List.from(combinations[i - weight.toInt()])..add(getAminoByWeight(aminoMap, weight));
        }
      }
    }

    if (dp[totalWeight.toInt()] == double.infinity) {
      print("불가능한 조합입니다.");
    } else {
      var resultCombinations = combinations.sublist(combinations.length -totalSize, combinations.length);
      for(var i = 0; i < resultCombinations.length; i++){
        final sum = resultCombinations[i].map((amino) => aminoMap[amino] ?? 0).fold(0.0, (sum, e) => sum + e);
        var aminoString = groupAndCount(resultCombinations[i].join(''));
        print('$aminoString, ${sum/ 1000}');
        resultList.add(AminoModel(code: aminoString, weight: sum/ 1000));
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
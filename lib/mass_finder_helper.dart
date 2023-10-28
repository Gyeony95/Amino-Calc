import 'dart:isolate';

import 'package:mass_finder/amino_model.dart';

// 총무게까지만 계산하면 물 증발량 계산이 안돼서 여유있게 넣어놓는 가중치
double addWeight = 100000.0;

class MassFinderHelper {
  /// [totalWeight] : 단백질의 총 무게
  /// [totalSize] : 출력할 아미노산 조합의 숫자
  /// [initAminos] : 필수로 포함되어야하는 아미노산들
  static calc(
      SendPort sendPort, double totalWeight, int totalSize, String initAminos) {
    final aminoMap = {
      'G': 7503,
      'A': 8905,
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
        aminoMap, totalWeight + addWeight, totalSize, initAminos);
    List<Map<String, dynamic>> sendData =
        aminoList.map((e) => e.toJson()).toList();
    sendPort.send(sendData);
  }

  static List<AminoModel> findClosestWeightCombinations(
      Map<String, int> aminoMap,
      double totalWeight,
      int totalSize,
      String initAminos) {
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
            ..add(getAminoByWeight(aminoMap, weight));
        }
      }
    }

    if (dp[totalWeight.toInt()] == double.infinity) {
      print("불가능한 조합입니다.");
    } else {
      for (var i = 0; i < combinations.length; i++) {
        // 각 조합의 맨 앞에 필수값 추가
        combinations[i] = [
          ...initAminos.split(''),
          ...combinations[i]
        ];
        // 각 아미노산 총 무게
        final sum = combinations[i]
            .map((amino) => aminoMap[amino] ?? 0)
            .fold(0.0, (sum, e) => sum + e) /
            100;
        // 물 증발량
        final waterWeight = 18.01 * (combinations[i].length - 1);
        // var aminoString = groupAndCount(combinations[i].join(''));
        var aminoString = combinations[i].join('');
        print('$aminoString, $waterWeight, $sum, ${sum - waterWeight}');
        resultList.add(AminoModel(
          code: aminoString,
          totalWeight: sum,
          waterWeight: waterWeight,
          weight: sum - waterWeight,
        ));
      }
    }

    // 예외처리 해놨던 아미노산들의 무게
    double initAminoWeight = 0;
    if (initAminos.isNotEmpty) {
      for (var i in initAminos.split('')) {
        initAminoWeight += aminoMap[i] ?? 0;
      }
    }
    resultList.sort((a, b) => (a.weight ?? 0).compareTo(b.weight ?? 0));
    double compareValue = (totalWeight + initAminoWeight - addWeight) / 100;
    // 가장 목표값에 가까운 index 도출
    int mustIndex = 0;
    for (var i = 0; i < resultList.length; i++) {
      double currentValue = ((resultList[mustIndex].weight ?? 0) - compareValue)
          .abs();
      double newValue = ((resultList[i].weight ?? 0) - compareValue).abs();
      if (currentValue > newValue) {
        mustIndex = i;
      }
    }

    // 입력값에 가까운 순서대로 정렬
    resultList.sort((a, b) {
      if (a.weight == null && b.weight == null) {
        return 0;
      } else if (a.weight == null) {
        return 1;
      } else if (b.weight == null) {
        return -1;
      } else {
        final double diffA = (a.weight! - compareValue).abs();
        final double diffB = (b.weight! - compareValue).abs();
        return diffA.compareTo(diffB);
      }
    });

    int _totalSize = resultList.length > totalSize ? totalSize : resultList.length;
    return resultList.sublist(0, _totalSize);
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

  static double getWaterWeight(int aminoLength) {
    return 18.01 * (aminoLength - 1);
  }
}

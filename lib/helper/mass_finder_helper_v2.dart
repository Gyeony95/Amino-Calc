import 'dart:isolate';
import 'dart:math';

import 'package:mass_finder/mass_finder_screen.dart';
import 'package:mass_finder/model/amino_model.dart';
import 'package:mass_finder/widget/formylation_selector.dart';
import 'package:mass_finder/widget/ion_selector.dart';
import 'package:tuple/tuple.dart';

final random = Random();
const int topSolutionsCount = 20;
const int saIterations = 100; // 시뮬레이티드 어닐링 반복 횟수
const double initialTemperature = 10000.0; // 초기 온도
const double coolingRate = 0.99; // 냉각률
const double absoluteTemperature = 0.00001; // 최소 온도
const double fWeight = 27.99; // 포밀레이스의 분자량
// calc 함수에서 초기화 될 사용가능한 아미노산의 리스트
Map<String, double> dataMap = {};

class MassFinderHelperV2 {
  static FormyType _formyType = FormyType.unknown;
  static IonType _ionType = IonType.unknown;

  static calcByIonType(SendPort sendPort, double targetMass, String initAminos,
      String fomyType, String ionType, Map<String, double> aminoMap) {
    _ionType = IonType.decode(ionType);
    List<AminoModel> bestSolutions = [];
    switch (_ionType) {
      case IonType.none: // 없으면 그냥 그대로 계산
        bestSolutions =
            calc(sendPort, targetMass, initAminos, fomyType, ionType, aminoMap);
      case IonType.unknown:
        // IonType을 모르면 unKnown을 제외함 모든타입을 계산해야함
        for(var i in IonType.values){
          if(i == IonType.unknown) continue;
          bestSolutions.addAll(calc(sendPort, targetMass - i.weight, initAminos,
              fomyType, ionType, aminoMap));
        }
        // calc 함수에서는 targetMass 를 낮춰놔서 낮춘만큼 다시 더해줌
        bestSolutions.map((e) => e.weight = e.weight! + e.ionType!.weight).toList();
        // 다시 정렬 후 20개 자름
        bestSolutions = sortAmino(bestSolutions, targetMass);
        bestSolutions = bestSolutions.take(topSolutionsCount).toList();
      default: // H, Na, k 일때 총 무게에서만 제외해서 계산
        bestSolutions = calc(sendPort, targetMass - _ionType.weight, initAminos,
            fomyType, ionType, aminoMap);
        // calc 함수에서는 targetMass 를 낮춰놔서 낮춘만큼 다시 더해줌
        bestSolutions.map((e) => e.weight = e.weight! + e.ionType!.weight).toList();
    }
    List<Map<String, dynamic>> returnList =
        bestSolutions.map((e) => e.toJson()).toList();
    sendPort.send(returnList);
  }

  static List<AminoModel> calc(
      SendPort sendPort,
      double targetMass,
      String initAminos,
      String fomyType,
      String ionType,
      Map<String, double> aminoMap) {
    _formyType = FormyType.decode(fomyType);
    dataMap = Map.from(aminoMap);
    List<AminoModel> bestSolutions = []; // 최적의 해를 저장할 리스트

    // 계산들어갈때 초기값은 빼고 계산하게 처리
    double initAminoWeight = getInitAminoWeight(initAminos);
    targetMass -= initAminoWeight;

    // 아미노산의 길이에 필수로 입력되어야 하는 seq 길이 더해줌
    Tuple2<int, int> range = getMinMaxRange(_formyType, targetMass);

    // 물의 무게를 빼주기 위해 가능한 범위만큼 가중치를 조절해가며 반복해서 계산
    for (var i = range.item1; i < range.item2; i++) {
      var addWeight = getWaterWeight(i);
      var solutions = calcByFType(_formyType, targetMass + addWeight);
      solutions = removeDuplicates(solutions); // 중복제거
      bestSolutions.addAll(solutions);
    }

    // 목표값에 가까운 순서대로 해들을 정렬하고 상위 20개를 선택
    bestSolutions = sortAmino(bestSolutions, targetMass);
    bestSolutions = bestSolutions.take(topSolutionsCount).toList();

    bestSolutions =
        setInitAminoToResult(bestSolutions, initAminos, initAminoWeight);
    bestSolutions =
        setMetaData(bestSolutions, _formyType, _ionType, initAminos);
    // 결과 출력
    for (var solution in bestSolutions) {
      print('combins : ${solution.code}, result : ${solution.weight}');
    }

    // isolate 로 리턴할 수 있는 형태로 바꿔줌
    return bestSolutions;
  }

  // 선택된 [FormyType] 에 따라 다르게 계산
  static List<AminoModel> calcByFType(FormyType fType, double targetMass) {
    List<AminoModel> bestSolutions = []; // 최적의 해를 저장할 리스트

    // 최적의 해를 정해진 횟수만큼 반복해서 구함
    for (int i = 0; i < saIterations; i++) {
      switch (fType) {
        case FormyType.n:
          Map<String, double> solution = simulatedAnnealing(targetMass);
          var key = solution.keys.first;
          bestSolutions.add(AminoModel(code: key, weight: getWeightSum(key)));
          break;
        case FormyType.y:
          Map<String, double> solution =
              simulatedAnnealing(targetMass - fWeight);
          solution = {'f${solution.keys.first}': solution.values.first};
          var key = solution.keys.first;
          bestSolutions.add(AminoModel(code: key, weight: getWeightSum(key)));
          break;
        case FormyType.unknown: // y,n 일때의 값을 모두 가짐
          Map<String, double> solution1 = simulatedAnnealing(targetMass);
          Map<String, double> solution2 =
              simulatedAnnealing(targetMass - fWeight);
          solution2 = {'f${solution2.keys.first}': solution2.values.first};
          var key1 = solution1.keys.first;
          var key2 = solution2.keys.first;
          bestSolutions.add(AminoModel(code: key1, weight: getWeightSum(key1)));
          bestSolutions.add(AminoModel(code: key2, weight: getWeightSum(key2)));
          break;
      }
    }
    return bestSolutions;
  }
}

Map<String, double> simulatedAnnealing(double targetMass) {
  double temperature = initialTemperature;

  // 1차 비교군을 위한 조합 추출해서 목표값과의 차이 저장
  List<String> currentSolution = randomSolution(targetMass);
  double currentEnergy = evaluate(currentSolution, targetMass);

  // 1차 비교군을 베스트로지정해놓음
  List<String> bestSolution = List.from(currentSolution);
  double bestEnergy = currentEnergy;

  // 초기온도에 계속해서 0.99를 곱해서 최소온도가 될때까지 반복해서 최적의 해를 구함
  while (temperature > absoluteTemperature) {
    // 기존 조합을 기준으로 새로운 조합 추출
    List<String> newSolution = neighborSolution(currentSolution, targetMass);
    double newEnergy = evaluate(newSolution, targetMass);

    // 새 조합이 합격되는지 체크
    if (acceptanceProbability(currentEnergy, newEnergy, temperature) >
        random.nextDouble()) {
      currentSolution = newSolution;
      currentEnergy = newEnergy;
    }

    // 새 조합이 목표값과의 차이가 더 적으면 새로운 베스트로 셋팅
    if (currentEnergy < bestEnergy) {
      bestSolution = List.from(currentSolution);
      bestSolution.sort();
      bestEnergy = currentEnergy;
    }

    temperature *= coolingRate;
  }

  return {bestSolution.join(): bestEnergy};
}

// 초기에 사용될 기준이 되는 조합을 랜덤으로 만드는 함수
List<String> randomSolution(double targetMass) {
  List<String> solution = [];
  double mass = 0.0;
  while (mass < targetMass) {
    String aminoAcid = dataMap.keys.elementAt(random.nextInt(dataMap.length));
    double aminoAcidMass = dataMap[aminoAcid]!;
    if (mass + aminoAcidMass > targetMass) break;
    solution.add(aminoAcid);
    mass += aminoAcidMass;
  }
  return solution;
}

// 기존 선택된 조합에서 아미노산을 새걸로 갈아치워서 새로운 조합 생성
List<String> neighborSolution(List<String> currentSolution, double targetMass) {
  List<String> newSolution = List.from(currentSolution);
  if (newSolution.isNotEmpty) {
    int index = random.nextInt(newSolution.length);
    String newAminoAcid =
        dataMap.keys.elementAt(random.nextInt(dataMap.length));
    newSolution[index] = newAminoAcid;

    // 혹시라도 newSolution 이 너무 클경우를 대비해 targetMass보다 작아질때까지 삭제처리
    while (evaluate(newSolution, targetMass) > targetMass) {
      newSolution.removeAt(random.nextInt(newSolution.length));
    }
  }
  return newSolution;
}

// 도출된 솔루션의 전체 질량과 목표값의 차이 도출
double evaluate(List<String> solution, double targetMass) {
  // 솔루션 조합의 총 질량
  double mass = solution.fold(0, (sum, gene) => sum + dataMap[gene]!);
  // 목표값 - 솔루션질량의 절대값
  return (targetMass - mass).abs();
}

// newEnergy < currentEnergy 이면 합격
// currentEnergy 가 작아도 exp 함수에 따라 자연로그 e의 currentEnergy - newEnergy 승을 현재 온도로 나눠서 합격할수도 있음
double acceptanceProbability(
    double currentEnergy, double newEnergy, double temperature) {
  return newEnergy < currentEnergy
      ? 1.0
      : exp((currentEnergy - newEnergy) / temperature);
}

// 넘어온 code로 무게를 계산하고 포멜레이스 포함이면 그 무게까지 더해줌
double getWeightSum(String solutionCombine) {
  double result =
      solutionCombine.split('').fold(0.0, (sum, e) => sum + (dataMap[e] ?? 0));
  if (solutionCombine.startsWith('f')) {
    result += fWeight;
  }
  // 물 증발량 제거
  result = result - getWaterWeight(solutionCombine.length);
  return result;
}

double getWaterWeight(int aminoLength) {
  if (aminoLength == 0) return 0;
  return 18.01 * (aminoLength - 1);
}

// 기준 크기로 정렬
List<AminoModel> sortAmino(List<AminoModel> list, double compareValue) {
  list.sort((a, b) {
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
  return list;
}

// 리스트 중복제거
List<AminoModel> removeDuplicates(List<AminoModel> inputList) {
  Map<String?, AminoModel> uniqueMap = {};
  for (var aminoModel in inputList) {
    uniqueMap[aminoModel.code] = aminoModel;
  }
  return uniqueMap.values.toList();
}

// 물 증발량 계산을위해 가능한 아미노산의 갯수 범위를 산정힘
Tuple2<int, int> getMinMaxRange(FormyType type, double targetMass) {
  int min = 0;
  int max = 0;
  // 사용 가능한 아미노산의 종류들의 최대 최소 값
  double minValue =
      dataMap.values.reduce((minValue, e) => minValue < e ? minValue : e);
  double maxValue =
      dataMap.values.reduce((maxValue, e) => maxValue > e ? maxValue : e);
  // 포밀레이스가 들어갈수도 있다면 [fWeight] 값이 제일 작은값
  if (type == FormyType.y || type == FormyType.unknown) {
    max = (targetMass / fWeight).ceil();
  } else {
    max = (targetMass / minValue).ceil();
  }
  min = (targetMass / maxValue).floor();
  return Tuple2(min, max);
}

// 초기 입력된 아미노산의 총 무게에서 물 증발량을 제거한 값
double getInitAminoWeight(String initAmino) {
  // 초기 입력값의 물 증발량, 근데 init 의 물 증발량 구할떄는 길이에 -1 해주면 안됨 나중에 또 -1 해줄거라서
  double initAminoWaterWeight = getWaterWeight(initAmino.length + 1);
  double initAminoWeight = 0;
  if (initAmino.isNotEmpty) {
    for (var i in initAmino.split('')) {
      initAminoWeight += aminoMap[i] ?? 0;
    }
  }
  return initAminoWeight - initAminoWaterWeight;
}

/// 기존 베스트 솔루션 에서 init 값을 앞에 붙여주는 로직
List<AminoModel> setInitAminoToResult(
    List<AminoModel> bestSolutions, String initAmino, double initAminoWeight) {
  if (initAmino.isEmpty) return bestSolutions;
  for (var i = 0; i < bestSolutions.length; i++) {
    var item = bestSolutions[i];
    var firstString = item.code!.substring(0, 1);
    if (firstString == 'f') {
      bestSolutions[i].code =
          bestSolutions[i].code?.replaceFirst('f', 'f$initAmino');
    } else {
      bestSolutions[i].code = bestSolutions[i]
          .code
          ?.replaceFirst(firstString, '$initAmino$firstString');
    }
    bestSolutions[i].weight = bestSolutions[i].weight! + initAminoWeight;
  }
  return bestSolutions;
}

/// FormyType, IonType, essential seq 붙여주는 부분
List<AminoModel> setMetaData(List<AminoModel> bestSolutions,
    FormyType formyType, IonType ionType, String essentialSeq) {
  return bestSolutions.map((e) {
    e.formyType = formyType;
    e.ionType = ionType;
    e.essentialSeq = essentialSeq;
    return e;
  }).toList();
}

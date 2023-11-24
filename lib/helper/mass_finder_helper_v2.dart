import 'dart:isolate';
import 'dart:math';

import 'package:mass_finder/widget/formylation_selector.dart';

final random = Random();
const int topSolutionsCount = 20;
const int saIterations = 100; // 시뮬레이티드 어닐링 반복 횟수
const double initialTemperature = 10000.0; // 초기 온도
const double coolingRate = 0.99; // 냉각률
const double absoluteTemperature = 0.00001; // 최소 온도
// calc 함수에서 초기화 될 사용가능한 아미노산의 리스트
Map<String, double> dataMap = {};

class MassFinderHelperV2 {
  static FormyType _formyType = FormyType.unknown;

  static calc(SendPort sendPort, double targetMass, String initAminos,
      String fomyType, Map<String, double> aminoMap) {
    _formyType = FormyType.decode(fomyType);
    dataMap = Map.from(aminoMap);
    List<Map<String, double>> bestSolutions = []; // 최적의 해를 저장할 리스트
    // 최적의 해를 정해진 횟수만큼 반복해서 구함
    for (int i = 0; i < saIterations; i++) {
      Map<String, double> solution = simulatedAnnealing(targetMass);
      bestSolutions.add(solution);
    }

    // 에너지(오차)에 따라 해들을 정렬하고 상위 20개를 선택
    bestSolutions.sort((a, b) => a.values.single.compareTo(b.values.single));
    bestSolutions = bestSolutions.take(topSolutionsCount).toList();
    // 결과 출력
    for (Map<String, double> solution in bestSolutions) {
      var splitList = solution.keys.join().split('');
      double  result = splitList.fold(0.0, (sum, e) => sum + (aminoMap[e] ?? 0));
      print('combins : ${splitList.join()}, result : $result');
    }

    // isolate 로 리턴할 수 있는 형태로 바꿔줌
    sendPort.send(bestSolutions);
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

import 'dart:math';

// 초기 해를 임의로 생성하고, 그 에너지(목표 질량과의 차이)를 평가합니다.
// 온도가 충분히 낮아질 때까지 다음 과정을 반복합니다:
// 이웃 해를 생성합니다.
// 이웃 해의 에너지를 평가합니다.
// 확률적으로 이웃 해를 현재 해로 수락합니다.
// 현재 해가 최적의 해보다 나으면 최적의 해를 업데이트합니다.
// 온도를 감소시킵니다.
// 최적의 해를 출력합니다.

// randomSolution: 임의로 생성한 초기 해를 반환합니다. 이 때 해의 총 질량이 targetMass를 넘지 않도록 합니다.
// neighborSolution: 현재 해의 이웃 해를 생성하는데, 이웃 해는 현재 해의 한 아미노산을 무작위로 다른 아미노산으로 대체하여 생성합니다. 이웃 해의 질량이 targetMass를 넘지 않도록 합니다.
// evaluate: 해의 총 질량을 계산하고, 이를 targetMass와 비교하여 차이를 반환합니다. 이 차이가 에너지(오차)로 사용됩니다.
// acceptanceProbability: 새로운 해를 수락할 확률을 계산합니다. 새로운 에너지가 현재 에너지보다 낮으면 확률은 1이고, 그렇지 않으면 보츠만 분포에 기반한 확률을 계산합니다.

final dataMap = {
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

final random = Random();
const int topSolutionsCount = 20;
const int saIterations = 100; // 시뮬레이티드 어닐링 반복 횟수
const double initialTemperature = 10000.0; // 초기 온도
const double coolingRate = 0.99; // 냉각률
const double absoluteTemperature = 0.00001; // 최소 온도

void main() {
  double targetMass = 5000.4;
  List<Map<String, double>> bestSolutions = []; // 최적의 해를 저장할 리스트

  for (int i = 0; i < saIterations; i++) {
    Map<String, double> solution = simulatedAnnealing(targetMass);
    bestSolutions.add(solution);
  }

  // 에너지(오차)에 따라 해들을 정렬하고 상위 20개를 선택
  bestSolutions.sort((a, b) => a.values.single.compareTo(b.values.single));
  bestSolutions = bestSolutions.take(topSolutionsCount).toList();

  // 결과 출력
  for (var solution in bestSolutions) {
    print(
        'Combination: ${solution.keys.join()} with mass ${(targetMass - solution.values.single).abs()} (Error: ${solution.values.single})');
  }
}

Map<String, double> simulatedAnnealing(double targetMass) {
  double temperature = initialTemperature;

  List<String> currentSolution = randomSolution(targetMass);
  double currentEnergy = evaluate(currentSolution, targetMass);

  List<String> bestSolution = List.from(currentSolution);
  double bestEnergy = currentEnergy;

  while (temperature > absoluteTemperature) {
    List<String> newSolution = neighborSolution(currentSolution, targetMass);
    double newEnergy = evaluate(newSolution, targetMass);

    if (acceptanceProbability(currentEnergy, newEnergy, temperature) >
        random.nextDouble()) {
      currentSolution = newSolution;
      currentEnergy = newEnergy;
    }

    if (currentEnergy < bestEnergy) {
      bestSolution = List.from(currentSolution);
      bestEnergy = currentEnergy;
    }

    temperature *= coolingRate;
  }

  return {bestSolution.join(): bestEnergy};
}

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

List<String> neighborSolution(List<String> currentSolution, double targetMass) {
  List<String> newSolution = List.from(currentSolution);
  if (newSolution.isNotEmpty) {
    int index = random.nextInt(newSolution.length);
    String newAminoAcid =
        dataMap.keys.elementAt(random.nextInt(dataMap.length));
    newSolution[index] = newAminoAcid;
    // Ensure the new solution is within the target mass
    while (evaluate(newSolution, targetMass) > targetMass) {
      newSolution.removeAt(random.nextInt(newSolution.length));
    }
  }
  return newSolution;
}

double evaluate(List<String> solution, double targetMass) {
  double mass = solution.fold(0, (sum, gene) => sum + dataMap[gene]!);
  return (targetMass - mass).abs(); // 목표 질량과의 차이
}

double acceptanceProbability(
    double currentEnergy, double newEnergy, double temperature) {
  return newEnergy < currentEnergy
      ? 1.0
      : exp((currentEnergy - newEnergy) / temperature);
}

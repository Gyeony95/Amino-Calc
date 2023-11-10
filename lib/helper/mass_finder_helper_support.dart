part of 'mass_finder_helper.dart';

/// 무게에 맞는 아미노산 도출
String _getAminoByWeight(Map<String, int> aminoMap, int weight) {
  for (var entry in aminoMap.entries) {
    if (entry.value == weight) {
      return entry.key;
    }
  }
  return '';
}

/// 수분량 = (아미노산 갯수 - 1) * 18.01
double _getWaterWeight(int aminoLength) {
  return 18.01 * (aminoLength - 1);
}

/// 필수 아미노산으로 입력받은 무게 계산
double _getInitAminoWeight(String initAminos, Map<String, int> aminoMap) {
  double initAminoWeight = 0;
  if (initAminos.isNotEmpty) {
    for (var i in initAminos.split('')) {
      initAminoWeight += aminoMap[i] ?? 0;
    }
  }
  return initAminoWeight;
}


/// 아미노산리스트 타겟크기와 가까운 순으로 정렬
List<AminoModel> sortAmino(List<AminoModel> list, double compareValue){
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
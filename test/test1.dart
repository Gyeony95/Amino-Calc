

import 'package:collection/collection.dart';

void main() {
  final dataMap = {
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
  int targetWeight = 500040;
  var closestCombinations = findClosestCombinations(dataMap, targetWeight, 20);
  for (var combo in closestCombinations) {
    print("Combination: ${combo.map((e) => e.key).join('')} - Total Weight: ${combo.fold(0, (p, e) => p + e.value)}");
  }
}

List<List<MapEntry<String, int>>> findClosestCombinations(Map<String, int> dataMap, int target, int count) {
  List<MapEntry<String, int>> items = dataMap.entries.toList();
  items.sort((a, b) => b.value.compareTo(a.value)); // Sort items by weight in descending order

  PriorityQueue<Node> queue = PriorityQueue<Node>((a, b) => a.diff.compareTo(b.diff));
  List<List<MapEntry<String, int>>> results = [];
  int bestDiff = target;

  // Initial node
  queue.add(Node([], 0, 0));

  while (queue.isNotEmpty) {
    Node current = queue.removeFirst();

    // Check if the current node can lead to a solution better than the best one
    if (current.index < items.length && (results.isEmpty || current.diff < bestDiff)) {
      // Include the current item
      List<MapEntry<String, int>> newCombination = List.from(current.combination)
        ..add(items[current.index]);
      int newWeight = current.weight + items[current.index].value;
      int newDiff = (target - newWeight).abs();

      if (newDiff <= bestDiff) {
        results.add(newCombination);
        if (results.length > count) {
          results.sort((a, b) => (a.fold(0, (sum, e) => sum + e.value) - target).abs().compareTo((b.fold(0, (sum, e) => sum + e.value) - target).abs()));
          results.removeLast();
          bestDiff = (results.last.fold(0, (sum, e) => sum + e.value) - target).abs();
        }
        queue.add(Node(newCombination, newWeight, newDiff));
      }

      // Exclude the current item and move to the next
      if (current.index + 1 < items.length) {
        queue.add(Node(current.combination, current.weight, current.diff, current.index + 1));
      }
    }
  }

  return results;
}

class Node {
  List<MapEntry<String, int>> combination;
  int weight;
  int diff;
  int index;

  Node(this.combination, this.weight, int target, [this.index = 0]) : diff = (target - weight).abs();
}

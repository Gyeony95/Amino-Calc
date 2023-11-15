import 'package:flutter/material.dart';

// ignore: must_be_immutable
class AminoMapSelector extends StatefulWidget {
  Function(Map<String, bool> selectedAminos) onChangeAminos;
  AminoMapSelector({super.key, required this.onChangeAminos});
  @override
  _AminoMapSelectorState createState() => _AminoMapSelectorState();
}

class _AminoMapSelectorState extends State<AminoMapSelector> {
  Map<String, bool> selectedAminos = {
    'G': true,
    'A': true,
    'S': true,
    'T': true,
    'C': true,
    'V': true,
    'L': true,
    'I': true,
    'M': true,
    'P': true,
    'F': true,
    'Y': true,
    'W': true,
    'D': true,
    'E': true,
    'N': true,
    'Q': true,
    'H': true,
    'K': true,
    'R': true,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: selectedAminos.keys.map((String amino) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: selectedAminos[amino]!,
              onChanged: (bool? value) {
                setState(
                  () {
                    selectedAminos[amino] = value!;
                    widget.onChangeAminos(selectedAminos);
                  },
                );
              },
            ),
            Text(amino),
            const SizedBox(width: 10)
          ],
        );
      }).toList(),
    );
  }
}

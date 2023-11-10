import 'package:flutter/material.dart';

// 아미노산중에 f 가 들어가는지 여부
enum FomyType {
  y('yes'),
  n('no'),
  unknown('unknown');

  final String text;

  const FomyType(this.text);

  static FomyType decode(String value){
    return FomyType.values.firstWhere((e) => e.text == value);
  }
}

class FomylationSelector extends StatefulWidget {
  final FomyType fomyType;
  final Function(FomyType) onChange;

  const FomylationSelector(
      {Key? key, required this.fomyType, required this.onChange})
      : super(key: key);

  @override
  State<FomylationSelector> createState() => _FomylationSelectorState();
}

class _FomylationSelectorState extends State<FomylationSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contain Formulation'),
        Row(
          children: [
            ...List.generate(
              FomyType.values.length,
                  (index) => Row(
                children: [
                  Radio(
                    value: widget.fomyType,
                    groupValue: FomyType.values[index],
                    onChanged: (_) => widget.onChange(FomyType.values[index]),
                  ),
                  Text((FomyType.values[index]).text, style: const TextStyle(height: 1.0),),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  _FomylationSelectorState();
}

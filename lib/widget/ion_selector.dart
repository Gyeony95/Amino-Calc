import 'package:flutter/material.dart';
//+H : 1.008더함
// +Na : 22.990더함
// +K : 39.098더함
enum IonType {
  H('H', 1.008),
  Na('Na', 22.990),
  K('K', 39.098),
  // none('none', 0),
  unknown('unknown', 0);

  final String text;
  final double weight;

  const IonType(this.text, this.weight);

  static IonType decode(String value){
    return IonType.values.firstWhere((e) => e.text == value);
  }
}

class IonSelector extends StatefulWidget {
  final IonType fomyType;
  final Function(IonType) onChange;

  const IonSelector(
      {Key? key, required this.fomyType, required this.onChange})
      : super(key: key);

  @override
  State<IonSelector> createState() => _IonSelectorState();
}

class _IonSelectorState extends State<IonSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Adduct'),
        Row(
          children: [
            ...List.generate(
              IonType.values.length,
                  (index) => Row(
                children: [
                  Radio(
                    value: widget.fomyType,
                    groupValue: IonType.values[index],
                    onChanged: (_) => widget.onChange(IonType.values[index]),
                  ),
                  Text((IonType.values[index]).text, style: const TextStyle(height: 1.0),),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// 아미노산중에 f 가 들어가는지 여부
/// Fomylation 무게는 27.99
enum FormyType {
  y('yes'),
  n('no'),
  unknown('unknown');

  final String text;

  const FormyType(this.text);

  static FormyType decode(String value){
    return FormyType.values.firstWhere((e) => e.text == value);
  }
}

class FormylationSelector extends StatefulWidget {
  final FormyType fomyType;
  final Function(FormyType) onChange;

  const FormylationSelector(
      {Key? key, required this.fomyType, required this.onChange})
      : super(key: key);

  @override
  State<FormylationSelector> createState() => _FormylationSelectorState();
}

class _FormylationSelectorState extends State<FormylationSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Formylation'),
        Row(
          children: [
            ...List.generate(
              FormyType.values.length,
                  (index) => Row(
                children: [
                  Radio(
                    value: widget.fomyType,
                    groupValue: FormyType.values[index],
                    onChanged: (_) => widget.onChange(FormyType.values[index]),
                  ),
                  Text((FormyType.values[index]).text, style: const TextStyle(height: 1.0),),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mass_finder/widget/normal_text_field.dart';

// B,J,O,U,X,Z 의 기존에 아미노맵에 포함되지 않는 임의의 아미노산을 만들어내는 부분
class NcAAInputArea extends StatefulWidget {
  NcAAInputArea({Key? key, required this.onChangeNcAA, required this.initNcAA}) : super(key: key);
  final Function(Map<String, double> ncaaMap) onChangeNcAA;
  final Map<String, double> initNcAA;

  @override
  State<NcAAInputArea> createState() => _NcAAInputAreaState();
}

class _NcAAInputAreaState extends State<NcAAInputArea> {

  @override
  void initState() {
    super.initState();
    for(var key in _ncaaMap.keys){
      double newValue = widget.initNcAA[key] ?? 0.0;
      _ncaaMap[key] = newValue;
      if(newValue != 0){
        _controllerMap[key]!.text = newValue.toString() ?? '';
      }
    }
  }

  Map<String, double> _ncaaMap = {
    'B': 0.0,
    'J': 0.0,
    'O': 0.0,
    'U': 0.0,
    'X': 0.0,
    'Z': 0.0,
  };

  final Map<String, TextEditingController> _controllerMap = {
    'B': TextEditingController(),
    'J': TextEditingController(),
    'O': TextEditingController(),
    'U': TextEditingController(),
    'X': TextEditingController(),
    'Z': TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: List.generate(_controllerMap.length,
          (index) => _ncaaInputNode(_controllerMap.keys.toList()[index])),
    );
  }

  Widget _ncaaInputNode(String key) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$key : '),
        SizedBox(
          width: 100,
          child: NormalTextField(
            textController: _controllerMap[key]!,
            onChange: (value){
              double? doubleValue = double.tryParse(value);
              _ncaaMap[key] = doubleValue ?? 0.0;
              widget.onChangeNcAA.call(_ncaaMap);
            },
          ),
        )
      ],
    );
  }
}

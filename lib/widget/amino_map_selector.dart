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

  // 버튼이 전체 선택 되었는지 체크
  bool buttonAllCheck = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleRow(),
        Wrap(
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
                    _checkButtonAllSelected();
                  },
                ),
                Text(amino),
                const SizedBox(width: 10)
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        const Text('Amino acid'),
        const SizedBox(width: 10),
        ElevatedButton(onPressed: ()  => _buttonTap(), child: Text(buttonAllCheck ? 'All Uncheck' : 'All Check')),
        const SizedBox(width: 10),
        ElevatedButton(onPressed: _strepButtonTap, child: const Text('STREF')),
      ],
    );
  }


  // 모든체크박스가 눌려있는지 체크하는 부분
  void _checkButtonAllSelected(){
    bool isAllTrue = true;
    for(var key in selectedAminos.keys){
      if(selectedAminos[key] == false){
        isAllTrue = false;
      }
    }
    buttonAllCheck = isAllTrue;
    setState(() {});
  }

  // 전체 활성/비활성 버튼
  void _buttonTap() {
    setState(
      () {
        for(var key in selectedAminos.keys){
          selectedAminos[key] = !buttonAllCheck;
        }
        widget.onChangeAminos(selectedAminos);
      },
    );
    _checkButtonAllSelected();
  }

  void _strepButtonTap(){
    List<String> strep = ['W','S','H','P','Q','F','E','K'];
    for(var key in selectedAminos.keys){
      selectedAminos[key] = strep.contains(key);
    }
    _checkButtonAllSelected();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// inputFormatters: [FilteringTextInputFormatter.digitsOnly],
// ignore: use_key_in_widget_constructors
class NormalTextField extends StatefulWidget {
  final TextEditingController textController;
  final String? hintText;
  final String? labelText;
  final Function(String)? onChange;
  final List<TextInputFormatter>? inputFormatters;

  const NormalTextField({
    required this.textController,
    this.hintText,
    this.labelText,
    this.onChange,
    this.inputFormatters,
  });

  @override
  _NormalTextFieldState createState() => _NormalTextFieldState();
}

class _NormalTextFieldState extends State<NormalTextField> {
  @override
  Widget build(BuildContext context) {
    OutlineInputBorder _border = OutlineInputBorder(
      // 외곽선 스타일
      borderRadius: BorderRadius.circular(10.0), // 둥근 모서리 반지름
    );

    return TextFormField(
      controller: widget.textController,
      inputFormatters: widget.inputFormatters ?? [],
      onChanged: (value){
        if(widget.onChange != null){
          widget.onChange!.call(value);
        }
      },
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: _border,
        isDense: true,
        focusedBorder: _border.copyWith(
            borderSide: const BorderSide(color: Colors.blue, width: 2.0)),
        errorBorder: _border.copyWith(
            borderSide: const BorderSide(color: Colors.red, width: 2.0)),
        focusedErrorBorder: _border.copyWith(
            borderSide: const BorderSide(color: Colors.red, width: 2.0)),
      ),
    );
  }
}

/// 소문자 -> 대문자 포매터
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 새로운 값을 대문자로 변환하여 반환합니다.
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
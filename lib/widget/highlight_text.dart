import 'package:flutter/material.dart';

class HighLightText extends StatelessWidget {
  HighLightText({
    Key? key,
    required this.text,
    required this.word,
    required this.style,
    this.singleMatch = true,
    this.overflow = TextOverflow.ellipsis,
    Color highLightColor = Colors.blueAccent,
    this.align,
    this.maxLine,
    this.caseSensitive = true,
  })  : _highLightStyle = style.copyWith(color: highLightColor),
        super(key: key) {
    if (word.isNotEmpty) {
      if(caseSensitive) {
        _disassembleByMultiMatches(word.allMatches(text));
      } else {
        _disassembleByMultiMatches((word.toLowerCase()).allMatches(text.toLowerCase()));
      }
      _entities.removeWhere((e) => e.isEmpty);
    }
  }

  /// 원본 텍스트
  final String text;

  /// 하이라이트할 텍스트
  final String word;

  /// 텍스트의 스타일
  final TextStyle style;

  /// 하이라이트되는 텍스트의 스타일
  final TextStyle _highLightStyle;

  /// 일치 항목 중 하나만 사용할지 결정하는 값
  final bool singleMatch;

  /// 텍스트 오버플로우 속성
  final TextOverflow overflow;

  /// 텍스트 정렬
  final TextAlign? align;

  /// 텍스트 최대 라인수
  final int? maxLine;

  /// 영어의 경우, 대/소문자 구분 여부. 기본값은 true(대소문자 구분)
  final bool caseSensitive;

  /// 원본 텍스트를 파싱하여 하이라이트될 텍스트와 아닌 텍스트를 구분하여 리스트로 저장한다.
  final List<_HighLightEntity> _entities = [];

  /// 일치하는 문자열이 존재하고, [Match]가 하나 이상인 경우, 원본 문자열을 쪼개어서
  /// [_entities]에 추가하는 작업.
  void _disassembleByMultiMatches(Iterable<Match> matches) {
    if (matches.isEmpty) {
      return;
    }
    // 하나만 사용하는 경우 나머지 제거
    if (singleMatch) {
      matches = matches.take(1);
    }

    int cursor = 0;
    matches.forEach((e) {
      _entities
        ..add(_HighLightEntity(
          text: text.substring(cursor, e.start),
          isMatched: false,
        ))
        ..add(_HighLightEntity(
          text: text.substring(e.start, e.end),
          isMatched: true,
        ));
      cursor = e.end;
    });
    if (cursor != text.length) {
      _entities.add(_HighLightEntity(
        text: text.substring(cursor),
        isMatched: false,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // if no matches exist, just return text
    if (_entities.isEmpty) {
      return Text(
        text.replaceAll('null', '-'),
        style: style,
        maxLines: maxLine,
        overflow: overflow,
        textAlign: align,
      );
    }

    return Text.rich(
      TextSpan(
        children: _entities.map(_textSpanBuilder).toList(),
      ),
      maxLines: maxLine,
      overflow: overflow,
      textAlign: align,
    );
  }

  /// [_HighLightEntity]를 [TextSpan]으로 변환
  TextSpan _textSpanBuilder(_HighLightEntity entity) => TextSpan(
      text: entity.text.replaceAll('null', '-'), style: entity.isMatched ? _highLightStyle : style);
}

/// ## 원본 텍스트를 파싱하여 분할한 문자열 조각
class _HighLightEntity {
  _HighLightEntity({required this.text, required this.isMatched});

  /// 문자열 조각
  final String text;

  /// 특정 문자열과 일치하는 조각인지 확인하는 값.
  final bool isMatched;

  /// 해당 인스턴스의 [text]가 비어있는지 확인하는 변수
  bool get isEmpty => text.isEmpty;
}

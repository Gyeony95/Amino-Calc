import 'dart:async';

import 'package:flutter/material.dart';

/// # 토스트 위젯
/// 10월 마이너 배포 버전부터 서베에서 금칙어에 대한 에러 처리를 진행한다. 따라서 클라이언트에서도 이에
/// 대응해서 금칙어에 대한 에러를 수신하는 경우에는 토스트로 표시해주는 작업을 진행한다.
/// 그러나, 기존의 [Toast]가 요구 조건을 완벽하게 충족시키지 못하기 때문에 별도로 제작하여 사용한다.
///
/// 이후 기존 [Toast]생성 시에는 배경 영역에 대한 터치가 모두 무시되는 현상이 발생해서 이를 모두
/// 변경하기 위해 일반적인 줄바꿈이 없는 메세지도 표시하여 범용적으로 사용하게 변경
///
/// -
///
/// ## Usage
/// 토스트를 표시하는 경우, static method 인 [show]를 사용하여 표시한다. [Get]을 사용하기 때문에
/// 별도의 [Context]는 전달 받지 않으며, 표시하고자 하는 메세지만을 전달하면 사용가능 하다.
class AlertToast {
  /// Single tone 을 유한 객체
  static final AlertToast _instance = AlertToast._();

  /// Single tone 을 받어오는 factory 생성자
  factory AlertToast.instance() => _instance;

  AlertToast._();

  /// ### 실제로 표시할 오버레이 엔티티
  static OverlayEntry? _overlayEntry;

  /// ### 토스트가 현제 표시되고 있는지 확인하는 변수
  static bool _isVisible = false;

  /// ### 현재 표시되고 있는 토스트의 타이머
  static Timer? _timer;

  /// ## 토스트 메세지 표시
  /// 특정 문자열을 표시하기 위해 [msg]를 전달받아 오버레이를 표시한다. 이때, 서버로 부터 전달받는 에러
  /// 메세지의 형식은 2줄의 메세지이다. 첫번째 줄은 서버에서 탐지한 금칙어의 리스트이며, 두번째 줄은
  /// 금칙어가 포함되어 등록할 수 없다는 공통적인 문장이다. 따라서 [msg]는 '\n'으로 행 변경이 있는
  /// 문장이어야 한다.
  ///
  /// 또한 [duration]을 통해서 토스트가 표시되는 지속시간을 결정할 수 있다. 기본값은 1이며,
  /// 이는 변수명에서 표시하듯, 초단위의 값이다.
  ///
  /// [preserveCurrent]에 [true]를 전달하면 현재 표시되고 있는 것이 있을때 새로운 토스트 메세지
  /// 요청을 취소하고 띄우는 것이 아니라 기존의 것을 유지시킨다.
  static void show({
    required BuildContext context,
    String? msg,
    int duration = 1,
    Alignment align = Alignment.center,
    bool preserveCurrent = false,
    Widget? toastWidget,
  }) {
    if (preserveCurrent && _isVisible) {
      return;
    }
    dismiss();

    // 보여줄 내용이 없으면 리턴
    if (msg == null && toastWidget == null) return;

    // 위젯을 가지고 있다면 위젯을 띄워줌
    if (toastWidget == null) {
      _overlayEntry = _msgBuilder(msg ?? '', align, context);
    } else {
      _overlayEntry = _widgetBuilder(toastWidget, align, context);
    }

    final overlayState = Overlay.of(context);

    _isVisible = true;
    overlayState.insert(_overlayEntry!);

    _timer = Timer(Duration(seconds: duration), () {
      dismiss();
    });
  }

  /// ## 토스트 메세지 제거
  static void dismiss() {
    if (!_isVisible) return;

    _isVisible = false;
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
  }

  /// ## 한줄 짜리 메세지 위젯 빌더
  static OverlayEntry _msgBuilder(String msg, Alignment align, BuildContext context) {
    return OverlayEntry(
        builder: (context) => Align(
          alignment: align,
          child: Padding(
            padding: _padding(context),
            child: IgnorePointer(
              child: Material(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black45,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Text(
                    msg,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  /// 화면에 보여줄 위젯을 표시하는 부분
  static OverlayEntry _widgetBuilder(Widget widget, Alignment align, BuildContext context) {
    return OverlayEntry(
        builder: (context) => Align(
          alignment: align,
          child: Padding(
            padding: _padding(context),
            child: IgnorePointer(
              child: Material(
                borderRadius: BorderRadius.circular(27.5),
                color: Colors.black45,
                child: widget,
              ),
            ),
          ),
        ));
  }

  /// ## 토스트의 패딩값 계산
  /// 하단 정렬인 경우에, 소프트 키패드가 올라와있는지 확인하고 이를 계산해여 추가한다
  static EdgeInsets _padding(BuildContext context) {
    double defaultVerticalPadding = MediaQuery.of(context).size.height / 5;

    // 소프트 키패드 있는지 확인해서 바텀 패딩 계산
    double bottom;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // 소프트 키패드 올라온 상태
    if (bottomInset != 0) {
      bottom = bottomInset + 70;
    } else {
      bottom = defaultVerticalPadding;
    }

    return EdgeInsets.fromLTRB(
      20,
      defaultVerticalPadding,
      20,
      bottom,
    );
  }
}

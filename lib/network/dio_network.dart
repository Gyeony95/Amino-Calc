import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

part 'dio_interceptor.dart';

class DioNetwork {
  // 팩토리(싱글톤) 객체생성
  factory DioNetwork() => _instance;

  // dio 객체 생성
  late Future<Dio> _dio;

  Future<Dio> get dio => _dio;

  // 인스턴스 초기화
  static final _instance = DioNetwork.private();

  final baseUrl = 'http://3.133.48.125:8000/';

  //초기화
  DioNetwork.private() {
    _dio = _initDio();
  }

  // 가끔 옵션 수정할일 있을때 싱글톤 객제 말고 이거로 그떄그때 만들어 써야함
  Future<Dio> copyDio() async {
    return await _initDio();
  }

  // dio 초기 셋팅
  Future<Dio> _initDio() async {
    return Dio(
      // 헤더에 기본적으로 디바이스 정보를 담아서 보냄
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
        },
        contentType: ContentType.json.mimeType,
      ),
    )
      ..interceptors.add(logInterceptor)
      ..interceptors.add(_DioInterceptor());
  }

  LogInterceptor get logInterceptor => LogInterceptor(
        request: !kReleaseMode,
        requestHeader: !kReleaseMode,
        requestBody: !kReleaseMode,
        responseHeader: !kReleaseMode,
        responseBody: !kReleaseMode,
        error: !kReleaseMode,
        logPrint: (msg) => debugPrint(msg.toString()),
      );
}

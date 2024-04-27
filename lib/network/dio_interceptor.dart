part of 'dio_network.dart';

class _DioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return super.onResponse(response, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    return handler.resolve(
      Response(
        requestOptions: err.requestOptions,
        data: err.response?.data ?? '',
        statusCode: err.response?.statusCode ?? -1,
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:frontend/core/shared_preferences/local_storage.dart';

class TokenInterceptor extends Interceptor {
  TokenInterceptor({this.onUnauthorized});

  final void Function()? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = LocalStorage.token;

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await LocalStorage.clear();
      print('⚠️ JWT expired or invalid — user should reauthenticate.');
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}

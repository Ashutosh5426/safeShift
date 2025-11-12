import 'package:dio/dio.dart';
import 'package:frontend/core/shared_preferences/token_storage.dart';

class TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenStorage.token;

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await TokenStorage.clear();
      print('⚠️ JWT expired or invalid — user should reauthenticate.');
    }
    return handler.next(err);
  }
}

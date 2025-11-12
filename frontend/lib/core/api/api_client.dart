import 'package:dio/dio.dart';
import 'token_interceptor.dart';
import 'api_service.dart';

class ApiClient {
  static const String baseUrl = 'https://safeshift.onrender.com/api';
  static Dio? _dio;

  static Dio getDio() {
    if (_dio != null) return _dio!;
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(TokenInterceptor());
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

    _dio = dio;
    return dio;
  }

  static ApiService getService() {
    return ApiService(getDio());
  }
}

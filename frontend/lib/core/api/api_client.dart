import 'package:dio/dio.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'token_interceptor.dart';
import 'api_service.dart';

class ApiClient {
  static Dio? _dio;

  static Dio getDio() {
    if (_dio != null) return _dio!;
    final dio = Dio(
      BaseOptions(
        baseUrl: getIt<AppState>().baseUrl,
        connectTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      TokenInterceptor(
        onUnauthorized: () {
          final appState = getIt<AppState>();
          appState.logOut();
        },
      ),
    );
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.requestOptions.path.contains('/users/')) {
            if (response.data is Map<String, dynamic>) {
              response.data['status'] = response.statusCode;
            }
          }
          handler.next(response);
        },
      ),
    );
    _dio = dio;
    return dio;
  }

  static ApiService getService() {
    return ApiService(getDio());
  }
}

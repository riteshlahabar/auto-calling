// lib/data/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl:
            'https://auto-calling.turnkeyinfotech.live/api', // single source
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
    _setupInterceptors();
  }

  late final Dio _dio;
  String? _token;
  UnauthorizedHandler? _onUnauthorized;

  Dio get http => _dio;

  // Called by AuthService after login/loadSession/logout
  void setToken(String? token) {
    _token = token;
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  void setUnauthorizedHandler(UnauthorizedHandler? handler) {
    _onUnauthorized = handler;
  }

  void _setupInterceptors() {
    // Retry only timeouts/5xx
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 5,
        retryDelays: const [
          Duration(milliseconds: 500),
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
        ],
        retryEvaluator: (error, attempt) {
          final code = error.response?.statusCode ?? 0;
          return (code == 0 || code >= 500);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
    // shared retry policy [web:271][web:266]

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Always attach latest token
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          } else {
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            // Let AuthService decide: refresh or logout
            if (_onUnauthorized != null) {
              await _onUnauthorized!();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
}

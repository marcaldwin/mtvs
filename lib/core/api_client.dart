
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;
  String? _token;

  ApiClient({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          // Let 4xx pass through so we can read server error bodies in services
          validateStatus: (s) => s != null && s < 500,
        ),
      );

  /// Attach bearer token to all subsequent requests
  void setToken(String token) {
    _token = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove bearer token from headers
  void clearToken() {
    _token = null;
    dio.options.headers.remove('Authorization');
  }

  String? get token => _token;
}

import 'package:dio/dio.dart';
import '../constants/app_urls.dart';

/// ApiClient - HTTP client cho ứng dụng
///
/// Sử dụng Dio để thực hiện các API calls
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppUrls.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // TODO: Add interceptors for authentication, logging, etc.
  }

  Dio get dio => _dio;
}


import 'package:dio/dio.dart';

class ApiClient {
  // ==========================================
  // BACKEND CONFIGURATION
  // ==========================================

  // NestJS development server
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // ==========================================
  // DIO INSTANCE
  // ==========================================

  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),

        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
}

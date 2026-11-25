import 'package:dio/dio.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/token_storage.dart';

/// True only if a saved token exists AND the backend accepts it.
Future<bool> hasValidSession() async {
  final token = await TokenStorage.read();
  if (token == null) return false;

  try {
    await dio.get('/auth/me');
    return true;
  } on DioException {
    // 401: the interceptor already cleared the token.
    // Network error / 429: we couldn't verify, so keep the token
    // and just send them to login this time.
    return false;
  }
}
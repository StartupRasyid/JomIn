import 'package:dio/dio.dart';
import 'package:frontend/core/token_storage.dart';

const String apiBaseUrl = 'http://localhost:3000/api/v1'; // change per device, see below

final dio = Dio(BaseOptions(
  baseUrl: apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
))
  ..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await TokenStorage.read();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      // Token was sent but the server rejected it (expired/invalid): drop it.
      if (e.response?.statusCode == 401 &&
          e.requestOptions.headers.containsKey('Authorization')) {
        await TokenStorage.clear();
      }
      handler.next(e);
    },
  ));
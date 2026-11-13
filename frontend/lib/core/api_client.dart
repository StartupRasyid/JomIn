import 'package:dio/dio.dart';

const String apiBaseUrl = 'http://localhost:3000/api/v1'; // change per device, see below

final dio = Dio(BaseOptions(
  baseUrl: apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
));
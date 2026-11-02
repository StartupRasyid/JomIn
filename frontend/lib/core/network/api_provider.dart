
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

// Provides one shared API client.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Fetches the database health status from NestJS.
final databaseHealthProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);

  final response = await apiClient.dio.get('/database/health');

  return Map<String, dynamic>.from(response.data as Map);
});

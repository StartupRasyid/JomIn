
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/api_provider.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const DatabaseHealthScreen();
      },
    ),
  ],
);

class DatabaseHealthScreen extends ConsumerWidget {
  const DatabaseHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(databaseHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('JomIn'),
      ),
      body: Center(
        child: health.when(
          // While waiting for the backend
          loading: () => const CircularProgressIndicator(),

          // If the request fails
          error: (error, stackTrace) => Text(
            'Connection failed:\n$error',
            textAlign: TextAlign.center,
          ),

          // If the backend responds successfully
          data: (data) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Database: ${data['database']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Status: ${data['status']}',
              ),
              Text(
                data['message'] ?? '',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

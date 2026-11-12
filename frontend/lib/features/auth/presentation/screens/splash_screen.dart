
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  static const Color backgroundColor = Color(0xFF171316);
  static const Color primaryColor = Color(0xFF7C2140);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for successful database connection.
    ref.listen(databaseHealthProvider, (previous, next) {
      next.whenData((data) {
        final connected =
            data['status'] == 'success' &&
            data['database'] == 'connected';

        if (connected && mounted) {
          context.go('/login');
        }
      });
    });

    // Watch connection status to update the UI.
    final health = ref.watch(databaseHealthProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated JomIn logo
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/JomIn_ExpandedLogo.png',
                  width: 150,
                  height: 150,
                ),
              ),
            ),

            // const SizedBox(height: 28),

            // const Text(
            //   'JomIn',
            //   style: TextStyle(
            //     fontSize: 36,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //     letterSpacing: 1.5,
            //   ),
            // ),

            // const SizedBox(height: 10),

            const Text(
              'Discover. Connect. Join.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFBDB3B8),
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 55),

            // Backend and database status
            health.when(
              loading: () => const Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Connecting to JomIn...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),

              error: (error, stackTrace) => Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connection failed',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Unable to reach the backend server.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(databaseHealthProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),

              data: (data) {
                final connected =
                    data['status'] == 'success' &&
                    data['database'] == 'connected';

                return Column(
                  children: [
                    Icon(
                      connected
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: connected
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      connected
                          ? 'JomIn is ready!'
                          : 'Database connection failed',
                      style: TextStyle(
                        color: connected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Database: ${data['database'] ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${data['status'] ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    if (!connected) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(databaseHealthProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: JomInApp(),
    ),
  );
}

class JomInApp extends StatelessWidget {
  const JomInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'JomIn',
      debugShowCheckedModeBanner: false,

      // JomIn application theme
      theme: AppTheme.darkTheme,

      routerConfig: appRouter,
    );
  }
}

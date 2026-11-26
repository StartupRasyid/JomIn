import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_interests_screen.dart';
import '../../features/events/data/media_picker_service.dart';
import '../../features/events/presentation/screens/event_info_form_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        return const OnboardingInterestsScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/create-event',
      builder: (context, state) {
        final media = state.extra as PickedMediaResult?;
        return EventInfoFormScreen(selectedMedia: media);
      },
    ),
  ],
);
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/gallery/presentation/pages/gallery_page.dart';
import 'routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashPage(),
      ),
    ),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (context, state) => _fadeTransition(
        state,
        const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: Routes.gallery,
      pageBuilder: (context, state) => _fadeTransition(
        state,
        const GalleryPage(),
      ),
    ),
  ],
);

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    );

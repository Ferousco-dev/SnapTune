import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/gallery/presentation/pages/gallery_page.dart';
import '../../features/albums/presentation/pages/albums_page.dart';
import '../../features/optimize/presentation/pages/optimize_page.dart'
    show OptimizePage, OptimizeArgs, ProcessingArgs;
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/viewer/presentation/pages/viewer_page.dart';
import '../../features/optimize/presentation/pages/processing_page.dart';
import '../../features/optimize/presentation/pages/result_page.dart';
import '../../shared/widgets/app_shell.dart';
import 'routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (_, state) => const NoTransitionPage(child: SplashPage()),
    ),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (_, state) => _fade(state, const OnboardingPage()),
    ),
    GoRoute(
      path: Routes.viewer,
      pageBuilder: (_, state) {
        final args = state.extra as ViewerArgs;
        return _fade(state, ViewerPage(args: args));
      },
    ),
    GoRoute(
      path: Routes.processing,
      pageBuilder: (_, state) {
        final args = state.extra as ProcessingArgs?;
        return _fade(state, ProcessingPage(args: args));
      },
    ),
    GoRoute(
      path: Routes.result,
      pageBuilder: (_, state) {
        final args = state.extra as ResultArgs?;
        return _fade(state, ResultPage(args: args));
      },
    ),
    ShellRoute(
      builder: (_, _, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: Routes.gallery,
          pageBuilder: (_, state) => _noTransition(state, const GalleryPage()),
        ),
        GoRoute(
          path: Routes.albums,
          pageBuilder: (_, state) => _noTransition(state, const AlbumsPage()),
        ),
        GoRoute(
          path: Routes.optimize,
          pageBuilder: (_, state) {
            final args = state.extra as OptimizeArgs?;
            return _noTransition(state, OptimizePage(args: args));
          },
        ),
        GoRoute(
          path: Routes.favorites,
          pageBuilder: (_, state) => _noTransition(state, const FavoritesPage()),
        ),
        GoRoute(
          path: Routes.settings,
          pageBuilder: (_, state) => _noTransition(state, const SettingsPage()),
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

NoTransitionPage<void> _noTransition(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

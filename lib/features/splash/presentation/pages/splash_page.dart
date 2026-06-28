import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _exitCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _nameFade;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Starts at 1 (fully visible); reversed to 0 just before navigation
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );

    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic)),
    );

    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // Hold the splash long enough for the enter animation to finish
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    // Fade the whole splash to 0 before swapping routes — eliminates the split
    await _exitCtrl.reverse();
    if (!mounted) return;
    final done = sl<PrefsService>().isOnboardingDone;
    context.go(done ? Routes.gallery : Routes.onboarding);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _exitCtrl,
      child: Scaffold(
        // Solid fallback so no white shows through during any rendering gap
        backgroundColor: AppColors.primary,
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.splashGradient),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name — true vertical center
                    Expanded(
                      child: Center(
                        child: Opacity(
                          opacity: _nameFade.value,
                          child: Transform.scale(
                            scale: _scale.value,
                            child: Text(
                              'SnapTune',
                              style: AppTypography.outfit(
                                fontSize: 54,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tagline pinned to bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 36),
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: Opacity(
                          opacity: _taglineFade.value,
                          child: Text(
                            'Perfect before you share.',
                            style: AppTypography.dmSans(
                              fontSize: 14,
                              color: Colors.white.withAlpha(170),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

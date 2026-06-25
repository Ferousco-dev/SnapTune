import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _orbitController;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _taglineFadeAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
    _navigateAfter();
  }

  Future<void> _navigateAfter() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    context.go(Routes.onboarding);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Stack(
          children: [
            // Ambient glow circles
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ),

            // Orbiting sparkle dots
            Center(
              child: AnimatedBuilder(
                animation: _orbitController,
                builder: (_, _) => SizedBox(
                  width: 260,
                  height: 260,
                  child: _SparkleOrbit(progress: _orbitController.value),
                ),
              ),
            ),

            // Logo + wordmark
            Center(
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (_, child) => Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with white-tinted shadow
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SnapTune',
                      style: AppTypography.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _entryController,
                      builder: (_, child) => Opacity(
                        opacity: _taglineFadeAnim.value,
                        child: child,
                      ),
                      child: Text(
                        'Perfect before you share.',
                        style: AppTypography.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withAlpha(190),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkleOrbit extends StatelessWidget {
  final double progress;

  const _SparkleOrbit({required this.progress});

  @override
  Widget build(BuildContext context) {
    const sparkles = [
      _SparkleConfig(radius: 110, angleOffset: 0.0, size: 6, opacity: 0.6),
      _SparkleConfig(radius: 110, angleOffset: 0.33, size: 4, opacity: 0.4),
      _SparkleConfig(radius: 110, angleOffset: 0.67, size: 5, opacity: 0.5),
      _SparkleConfig(radius: 80, angleOffset: 0.17, size: 3.5, opacity: 0.35),
      _SparkleConfig(radius: 80, angleOffset: 0.50, size: 4.5, opacity: 0.45),
      _SparkleConfig(radius: 80, angleOffset: 0.83, size: 3, opacity: 0.3),
    ];

    return Stack(
      alignment: Alignment.center,
      children: sparkles.map((s) {
        final angle = (progress + s.angleOffset) * 2 * math.pi;
        final x = math.cos(angle) * s.radius;
        final y = math.sin(angle) * s.radius;
        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: s.opacity,
            child: Container(
              width: s.size,
              height: s.size,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SparkleConfig {
  final double radius;
  final double angleOffset;
  final double size;
  final double opacity;

  const _SparkleConfig({
    required this.radius,
    required this.angleOffset,
    required this.size,
    required this.opacity,
  });
}

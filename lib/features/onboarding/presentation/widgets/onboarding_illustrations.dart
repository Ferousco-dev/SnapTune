import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ── Gallery Illustration ─────────────────────────────────────────────────────

class IllustrationGallery extends StatelessWidget {
  const IllustrationGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final cardColors = [
      const Color(0xFF5B5BD6),
      const Color(0xFF7B61FF),
      const Color(0xFFFF8A65),
      const Color(0xFF22C55E),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
    ];

    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (row) {
              return Padding(
                padding: EdgeInsets.only(bottom: row < 2 ? 10 : 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (col) {
                    final index = row * 3 + col;
                    return Padding(
                      padding: EdgeInsets.only(right: col < 2 ? 10 : 0),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: cardColors[index],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: index == 4
                            ? const Icon(Icons.star_rounded,
                                color: Colors.white, size: 24)
                            : null,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Optimize Illustration ────────────────────────────────────────────────────

class IllustrationOptimize extends StatefulWidget {
  const IllustrationOptimize({super.key});

  @override
  State<IllustrationOptimize> createState() => _IllustrationOptimizeState();
}

class _IllustrationOptimizeState extends State<IllustrationOptimize>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _barAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    final barHeights = [0.4, 0.65, 0.5, 0.85, 0.6, 0.75, 0.45, 0.9];

    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Waveform bars
              AnimatedBuilder(
                animation: _barAnim,
                builder: (_, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(barHeights.length, (i) {
                    final wave = math.sin((i / barHeights.length) * math.pi +
                        _barAnim.value * math.pi);
                    final h = 24 + (barHeights[i] + wave * 0.25) * 64;
                    return Padding(
                      padding: EdgeInsets.only(right: i < barHeights.length - 1 ? 6 : 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 14,
                        height: h.clamp(20.0, 88.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.primary, AppColors.violet],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              // Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Optimizing',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Share Illustration ───────────────────────────────────────────────────────

class IllustrationShare extends StatelessWidget {
  const IllustrationShare({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    final platforms = [
      _PlatformDot(color: const Color(0xFF25D366), icon: Icons.chat_rounded),
      _PlatformDot(color: const Color(0xFFE1306C), icon: Icons.camera_alt_rounded),
      _PlatformDot(color: const Color(0xFF2AABEE), icon: Icons.send_rounded),
      _PlatformDot(color: const Color(0xFF1877F2), icon: Icons.thumb_up_rounded),
    ];

    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center share button
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.share_rounded,
                  color: Colors.white, size: 32),
            ),

            // Platform dots at corners
            ..._buildPlatformDots(platforms),

            // Connecting lines via CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: _LinePainter(
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlatformDots(List<_PlatformDot> platforms) {
    const offsets = [
      Offset(-84, -72),
      Offset(84, -72),
      Offset(-84, 72),
      Offset(84, 72),
    ];
    return List.generate(platforms.length, (i) {
      return Transform.translate(
        offset: offsets[i],
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: platforms[i].color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: platforms[i].color.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(platforms[i].icon, color: Colors.white, size: 22),
        ),
      );
    });
  }
}

class _PlatformDot {
  final Color color;
  final IconData icon;
  const _PlatformDot({required this.color, required this.icon});
}

class _LinePainter extends CustomPainter {
  final bool isDark;
  const _LinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primary).withAlpha(30)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final corners = [
      Offset(size.width / 2 - 84, size.height / 2 - 72),
      Offset(size.width / 2 + 84, size.height / 2 - 72),
      Offset(size.width / 2 - 84, size.height / 2 + 72),
      Offset(size.width / 2 + 84, size.height / 2 + 72),
    ];

    for (final corner in corners) {
      canvas.drawLine(center, corner, paint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.isDark != isDark;
}

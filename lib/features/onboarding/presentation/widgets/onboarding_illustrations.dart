import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';


class IllustrationGallery extends StatelessWidget {
  const IllustrationGallery({super.key});

  static const _cells = [
    (Color(0xFF5BA4CF), Color(0xFF85C1E9), Icons.wb_sunny_rounded),
    (Color(0xFFFF7043), Color(0xFFFFCC02), Icons.landscape_rounded),
    (Color(0xFF7E57C2), Color(0xFFEDE7F6), Icons.face_rounded),
    (Color(0xFF90CAF9), Color(0xFF546E7A), Icons.terrain_rounded),
    (AppColors.primary, AppColors.violet, Icons.auto_awesome_rounded),
    (Color(0xFFFFF9C4), Color(0xFFFFE082), Icons.local_dining_rounded),
    (Color(0xFF039BE5), Color(0xFF4FC3F7), Icons.beach_access_rounded),
    (Color(0xFF0D1B2A), Color(0xFF1B2A3B), Icons.nights_stay_rounded),
    (Color(0xFFF8BBD0), Color(0xFF81C784), Icons.local_florist_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEEEEF8);

    return Center(
      child: Container(
        width: 264,
        height: 264,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(3, (row) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: row < 2 ? 7 : 0),
                child: Row(
                  children: List.generate(3, (col) {
                    final cell = _cells[row * 3 + col];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: col < 2 ? 7 : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [cell.$1, cell.$2],
                              ),
                            ),
                            child: Icon(
                              cell.$3,
                              color: Colors.white.withAlpha(180),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}


class IllustrationOptimize extends StatefulWidget {
  const IllustrationOptimize({super.key});

  @override
  State<IllustrationOptimize> createState() => _IllustrationOptimizeState();
}

class _IllustrationOptimizeState extends State<IllustrationOptimize>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEEEEF8);

    return Center(
      child: Container(
        width: 264,
        height: 264,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(8, (i) {
                    final wave = math.sin(
                        (i / 8) * math.pi + _controller.value * math.pi);
                    final base = [0.4, 0.65, 0.5, 0.85, 0.6, 0.75, 0.45, 0.9];
                    final h = (24 + (base[i] + wave * 0.22) * 64)
                        .clamp(18.0, 90.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 7 ? 6 : 0),
                      child: Container(
                        width: 16,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.primary, AppColors.violet],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Optimizing…',
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


class IllustrationShare extends StatelessWidget {
  const IllustrationShare({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEEEEF8);

    return Center(
      child: Container(
        width: 264,
        height: 264,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Connecting lines
            Positioned.fill(
              child: CustomPaint(
                painter: _ShareLinePainter(isDark: isDark),
              ),
            ),
            // Platform dots
            ..._platformDots(),
            // Center share button
            Container(
              width: 68,
              height: 68,
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
                  color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  static const _platforms = [
    _PlatformDot(color: Color(0xFF25D366), icon: Icons.chat_rounded, dx: -88, dy: -76),
    _PlatformDot(color: Color(0xFFE1306C), icon: Icons.camera_alt_rounded, dx: 88, dy: -76),
    _PlatformDot(color: Color(0xFF2AABEE), icon: Icons.send_rounded, dx: -88, dy: 76),
    _PlatformDot(color: Color(0xFF1877F2), icon: Icons.thumb_up_rounded, dx: 88, dy: 76),
  ];

  List<Widget> _platformDots() => _platforms.map((p) {
        return Transform.translate(
          offset: Offset(p.dx, p.dy),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: p.color.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(p.icon, color: Colors.white, size: 22),
          ),
        );
      }).toList();
}

class _PlatformDot {
  final Color color;
  final IconData icon;
  final double dx;
  final double dy;
  const _PlatformDot(
      {required this.color,
      required this.icon,
      required this.dx,
      required this.dy});
}

class _ShareLinePainter extends CustomPainter {
  final bool isDark;
  const _ShareLinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primary).withAlpha(28)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final corners = [
      Offset(size.width / 2 - 88, size.height / 2 - 76),
      Offset(size.width / 2 + 88, size.height / 2 - 76),
      Offset(size.width / 2 - 88, size.height / 2 + 76),
      Offset(size.width / 2 + 88, size.height / 2 + 76),
    ];
    for (final c in corners) {
      canvas.drawLine(center, c, paint);
    }
  }

  @override
  bool shouldRepaint(_ShareLinePainter old) => old.isDark != isDark;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';


class IllustrationGallery extends StatelessWidget {
  const IllustrationGallery({super.key});

  static const _scenes = [
    _Scene.sky,
    _Scene.sunset,
    _Scene.portrait,
    _Scene.mountains,
    _Scene.featured,
    _Scene.food,
    _Scene.beach,
    _Scene.cityNight,
    _Scene.nature,
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
              child: Container(
                margin: EdgeInsets.only(bottom: row < 2 ? 7 : 0),
                child: Row(
                  children: List.generate(3, (col) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: col < 2 ? 7 : 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: CustomPaint(
                            painter:
                                _PhotoScenePainter(_scenes[row * 3 + col]),
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

enum _Scene {
  sky,
  sunset,
  portrait,
  mountains,
  featured,
  food,
  beach,
  cityNight,
  nature,
}

class _PhotoScenePainter extends CustomPainter {
  final _Scene scene;
  const _PhotoScenePainter(this.scene);

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene) {
      case _Scene.sky:
        _drawSky(canvas, size);
      case _Scene.sunset:
        _drawSunset(canvas, size);
      case _Scene.portrait:
        _drawPortrait(canvas, size);
      case _Scene.mountains:
        _drawMountains(canvas, size);
      case _Scene.featured:
        _drawFeatured(canvas, size);
      case _Scene.food:
        _drawFood(canvas, size);
      case _Scene.beach:
        _drawBeach(canvas, size);
      case _Scene.cityNight:
        _drawCityNight(canvas, size);
      case _Scene.nature:
        _drawNature(canvas, size);
    }
  }


  void _fill(Canvas canvas, Size size, Color color) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  void _gradientFill(Canvas canvas, Size size, List<Color> colors,
      {Alignment begin = Alignment.topCenter,
      Alignment end = Alignment.bottomCenter}) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(begin: begin, end: end, colors: colors)
            .createShader(Offset.zero & size),
    );
  }


  void _drawSky(Canvas canvas, Size size) {
    _gradientFill(canvas, size,
        [const Color(0xFF5BA4CF), const Color(0xFF85C1E9)]);
    // Ground strip
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()..color = const Color(0xFF7DBB7E),
    );
    // Cloud
    final cp = Paint()..color = Colors.white.withAlpha(235);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.38, size.height * 0.3),
            width: size.width * 0.52,
            height: size.height * 0.2),
        cp);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.52, size.height * 0.22),
            width: size.width * 0.3,
            height: size.height * 0.17),
        cp);
    // Sun
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.2),
        size.width * 0.1, Paint()..color = const Color(0xFFFFEE58));
  }

  void _drawSunset(Canvas canvas, Size size) {
    _gradientFill(canvas, size, [
      const Color(0xFFFF5722),
      const Color(0xFFFF7043),
      const Color(0xFFFFA726),
      const Color(0xFFFFCC02),
    ]);
    // Horizon hills
    final hill = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.44,
          size.width * 0.5, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.72,
          size.width, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF1A237E));
    // Sun disc
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5),
        size.width * 0.13, Paint()..color = const Color(0xFFFFF176));
  }

  void _drawPortrait(Canvas canvas, Size size) {
    _fill(canvas, size, const Color(0xFFEDE7F6));
    // Shoulders
    final shoulderPaint = Paint()..color = const Color(0xFF7E57C2);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 1.08),
          width: size.width * 0.88,
          height: size.height * 0.62),
      shoulderPaint,
    );
    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.7),
            width: size.width * 0.19,
            height: size.height * 0.2),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFCCBC),
    );
    // Face
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.42),
        size.width * 0.24, Paint()..color = const Color(0xFFFFCCBC));
    // Hair arc
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.4),
          width: size.width * 0.5,
          height: size.height * 0.5),
      math.pi + 0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.09
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawMountains(Canvas canvas, Size size) {
    _gradientFill(canvas, size,
        [const Color(0xFF90CAF9), const Color(0xFFBBDEFB)]);
    // Back mountain
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.65, size.height * 0.14)
        ..lineTo(size.width * 0.9, size.height * 0.55)
        ..lineTo(size.width * 0.4, size.height * 0.55)
        ..close(),
      Paint()..color = const Color(0xFFB0BEC5),
    );
    // Back snow
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.65, size.height * 0.14)
        ..lineTo(size.width * 0.74, size.height * 0.3)
        ..lineTo(size.width * 0.56, size.height * 0.3)
        ..close(),
      Paint()..color = Colors.white,
    );
    // Front mountain
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.35, size.height * 0.22)
        ..lineTo(size.width * 0.63, size.height * 0.72)
        ..lineTo(size.width * 0.07, size.height * 0.72)
        ..close(),
      Paint()..color = const Color(0xFF546E7A),
    );
    // Front snow
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.35, size.height * 0.22)
        ..lineTo(size.width * 0.44, size.height * 0.38)
        ..lineTo(size.width * 0.26, size.height * 0.38)
        ..close(),
      Paint()..color = Colors.white,
    );
    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()..color = const Color(0xFF66BB6A),
    );
  }

  void _drawFeatured(Canvas canvas, Size size) {
    _gradientFill(canvas, size, [AppColors.primary, AppColors.violet],
        begin: Alignment.topLeft, end: Alignment.bottomRight);
    _drawStar(canvas, Offset(size.width / 2, size.height / 2),
        size.width * 0.3, Colors.white);
  }

  void _drawStar(
      Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const points = 5;
    final inner = radius * 0.42;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : inner;
      final a = (i * math.pi / points) - math.pi / 2;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawFood(Canvas canvas, Size size) {
    _fill(canvas, size, const Color(0xFFFFFDE7));
    // Plate shadow
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.52),
        size.width * 0.38, Paint()..color = const Color(0xFFEEEEEE));
    // Plate
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.5),
        size.width * 0.37, Paint()..color = Colors.white);
    // Plate rim
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.5),
        size.width * 0.37,
        Paint()
          ..color = const Color(0xFFE0E0E0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Food items
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.42),
        size.width * 0.1, Paint()..color = const Color(0xFFEF5350));
    canvas.drawCircle(Offset(size.width * 0.59, size.height * 0.42),
        size.width * 0.09, Paint()..color = const Color(0xFFFFA726));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.59),
        size.width * 0.1, Paint()..color = const Color(0xFF66BB6A));
    // Garnish dots
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.42),
        size.width * 0.04, Paint()..color = const Color(0xFF8D6E63));
  }

  void _drawBeach(Canvas canvas, Size size) {
    _gradientFill(canvas, size,
        [const Color(0xFF039BE5), const Color(0xFF4FC3F7)]);
    // Sand
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE082), Color(0xFFFFCC28)],
        ).createShader(Rect.fromLTWH(0, 0, 100, 100)),
    );
    // Foam
    canvas.drawLine(
        Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.6),
        Paint()
          ..color = Colors.white.withAlpha(180)
          ..strokeWidth = 2.5);
    // Wave lines
    for (int i = 0; i < 2; i++) {
      final y = size.height * (0.36 + i * 0.13);
      final p = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += size.width / 3) {
        p.quadraticBezierTo(x + size.width / 6, y - 4, x + size.width / 3, y);
      }
      canvas.drawPath(
          p,
          Paint()
            ..color = Colors.white.withAlpha(100)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
    }
  }

  void _drawCityNight(Canvas canvas, Size size) {
    _fill(canvas, size, const Color(0xFF0D1B2A));
    // Moon
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.17),
        size.width * 0.1, Paint()..color = const Color(0xFFFFF59D));
    canvas.drawCircle(Offset(size.width * 0.81, size.height * 0.14),
        size.width * 0.08, Paint()..color = const Color(0xFF0D1B2A));
    // Stars
    for (final s in [
      [0.2, 0.12],
      [0.45, 0.08],
      [0.6, 0.2],
      [0.1, 0.25]
    ]) {
      canvas.drawCircle(Offset(size.width * s[0], size.height * s[1]),
          1.2, Paint()..color = Colors.white.withAlpha(200));
    }
    // Buildings
    final buildings = [
      [0.0, 0.5, 0.21],
      [0.21, 0.33, 0.19],
      [0.4, 0.42, 0.22],
      [0.62, 0.28, 0.2],
      [0.82, 0.46, 0.18],
    ];
    for (final b in buildings) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * b[0], size.height * b[1],
            size.width * b[2], size.height),
        Paint()..color = const Color(0xFF1B2A3B),
      );
      final bx = size.width * b[0];
      final by = size.height * b[1];
      final bw = size.width * b[2];
      final winPaint = Paint()..color = const Color(0xFFFDD835).withAlpha(210);
      for (double wy = by + 5; wy < size.height - 4; wy += 9) {
        for (double wx = bx + 4; wx < bx + bw - 3; wx += 7) {
          if ((wx.toInt() + wy.toInt()) % 3 != 0) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 3.5, 4.5), winPaint);
          }
        }
      }
    }
  }

  void _drawNature(Canvas canvas, Size size) {
    _gradientFill(canvas, size,
        [const Color(0xFFF8BBD0), const Color(0xFFCE93D8)]);
    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.76, size.width, size.height * 0.24),
      Paint()..color = const Color(0xFF81C784),
    );
    // Stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.467, size.height * 0.44,
            size.width * 0.066, size.height * 0.34),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF558B2F),
    );
    // Petals
    final petals = [
      const Color(0xFFFF80AB),
      const Color(0xFFEA80FC),
      const Color(0xFF82B1FF),
      const Color(0xFFFFFF8D),
      const Color(0xFFFF6E40),
    ];
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      canvas.drawCircle(
        Offset(
          size.width * 0.5 + math.cos(angle) * size.width * 0.18,
          size.height * 0.36 + math.sin(angle) * size.height * 0.18,
        ),
        size.width * 0.1,
        Paint()..color = petals[i],
      );
    }
    // Center
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.36),
        size.width * 0.1, Paint()..color = const Color(0xFFFFD54F));
  }

  @override
  bool shouldRepaint(_PhotoScenePainter old) => old.scene != scene;
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

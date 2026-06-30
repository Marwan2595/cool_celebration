import 'dart:math';
import 'package:flutter/material.dart';

class NovaBurst {
  /// Call this anywhere you have a [BuildContext]:
  ///   NovaBurst.celebrate(context);
  static void celebrate(
    BuildContext context, {
    int shellCount = 7,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _NovaBurstOverlay(
        shellCount: shellCount,
        duration: duration,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _NovaBurstOverlay extends StatefulWidget {
  final int shellCount;
  final Duration duration;
  final VoidCallback onDone;

  const _NovaBurstOverlay({
    required this.shellCount,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_NovaBurstOverlay> createState() => _NovaBurstOverlayState();
}

class _NovaBurstOverlayState extends State<_NovaBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  final _random = Random();
  late final List<_Shell> _shells;

  // Neon / electric palette.
  static const _palette = [
    Color(0xFFFF0066),
    Color(0xFF00E5FF),
    Color(0xFFFFD600),
    Color(0xFF7C4DFF),
    Color(0xFF00E676),
    Color(0xFFFF6D00),
    Color(0xFFE040FB),
  ];

  @override
  void initState() {
    super.initState();

    _shells = List.generate(widget.shellCount, (i) {
      final color = _palette[i % _palette.length];
      final startDelay = i * (0.65 / widget.shellCount);
      final launchDuration = 0.07 + _random.nextDouble() * 0.05;
      final particleCount = 28 + _random.nextInt(16);

      return _Shell(
        launchXFraction: 0.1 + _random.nextDouble() * 0.8,
        burstYFraction: 0.08 + _random.nextDouble() * 0.40,
        startDelay: startDelay,
        launchDuration: launchDuration,
        color: color,
        particles: List.generate(
          particleCount,
          (_) => _BurstParticle(
            angle: _random.nextDouble() * 2 * pi,
            radialSpeed: 0.12 + _random.nextDouble() * 0.14,
            size: 3 + _random.nextDouble() * 5,
            isStar: _random.nextBool(),
            spin: (_random.nextDouble() - 0.5) * 15,
            isWhite: _random.nextDouble() < 0.25,
          ),
        ),
      );
    });

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _NovaBurstPainter(_shells, _controller.value),
        ),
      ),
    );
  }
}

class _Shell {
  final double launchXFraction;
  final double burstYFraction;
  final double startDelay;
  final double launchDuration;
  final Color color;
  final List<_BurstParticle> particles;

  _Shell({
    required this.launchXFraction,
    required this.burstYFraction,
    required this.startDelay,
    required this.launchDuration,
    required this.color,
    required this.particles,
  });
}

class _BurstParticle {
  final double angle;
  final double radialSpeed;
  final double size;
  final bool isStar;
  final double spin;
  final bool isWhite;

  _BurstParticle({
    required this.angle,
    required this.radialSpeed,
    required this.size,
    required this.isStar,
    required this.spin,
    required this.isWhite,
  });
}

class _NovaBurstPainter extends CustomPainter {
  final List<_Shell> shells;
  final double progress;

  _NovaBurstPainter(this.shells, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (final shell in shells) {
      if (progress < shell.startDelay) continue;

      final burstTime = shell.startDelay + shell.launchDuration;
      final launchX = size.width * shell.launchXFraction;
      final burstY = size.height * shell.burstYFraction;

      if (progress < burstTime) {
        // Shell travel: ease-out from bottom to burst point.
        final t = (progress - shell.startDelay) / shell.launchDuration;
        final eased = 1 - pow(1 - t, 2).toDouble();
        final y = size.height * 1.02 + (burstY - size.height * 1.02) * eased;

        // Glowing trail behind the head.
        for (int i = 0; i < 10; i++) {
          final trailY = y + 25.0 * (i / 10.0);
          final trailOpacity = (1 - i / 10.0) * 0.7;
          paint
            ..color = shell.color.withValues(alpha: trailOpacity)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              (4 - i * 0.3).clamp(0.5, 4.0),
            );
          canvas.drawCircle(
            Offset(launchX, trailY),
            (3 - i * 0.25).clamp(0.5, 3.0),
            paint,
          );
        }

        // Bright white head.
        paint
          ..color = Colors.white.withValues(alpha: 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(launchX, y), 5, paint);
        paint.maskFilter = null;
      } else {
        // Burst phase.
        final divisor = (1.0 - burstTime).clamp(0.001, 1.0);
        final t = ((progress - burstTime) / divisor).clamp(0.0, 1.0);

        // Flash ring at the explosion point.
        if (t < 0.12) {
          final flashT = t / 0.12;
          paint
            ..color = shell.color.withValues(alpha: (1 - flashT) * 0.85)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              20 * (1 - flashT) + 4,
            );
          canvas.drawCircle(
            Offset(launchX, burstY),
            size.width * 0.06 * flashT,
            paint,
          );
          paint.maskFilter = null;
        }

        // Particles fade out over the last 50% of the burst window.
        final opacity = t < 0.5 ? 1.0 : 1.0 - (t - 0.5) / 0.5;

        for (final p in shell.particles) {
          // Radial spread with downward gravity.
          final dr = p.radialSpeed * size.width * t;
          final gravity = 0.25 * size.height * t * t;
          final px = launchX + cos(p.angle) * dr;
          final py = burstY + sin(p.angle) * dr + gravity;

          final currentSize = p.size * (1 - t * 0.4).clamp(0.0, 1.0);
          if (currentSize < 0.5) continue;

          paint
            ..color = (p.isWhite ? Colors.white : shell.color).withValues(
              alpha: opacity.clamp(0.0, 1.0),
            )
            ..maskFilter = null;

          if (p.isStar) {
            _drawStar(canvas, Offset(px, py), currentSize, p.spin * t, paint);
          } else {
            canvas.drawCircle(Offset(px, py), currentSize / 2, paint);
          }
        }
      }
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    const points = 5;
    final inner = radius * 0.38;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = rotation + (i * pi / points) - pi / 2;
      final r = i.isEven ? radius : inner;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NovaBurstPainter old) => old.progress != progress;
}

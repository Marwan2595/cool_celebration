import 'dart:math';
import 'package:flutter/material.dart';

class CoolCelebration {
  /// Call this anywhere you have a [BuildContext]:
  ///   CoolCelebration.celebrate(context);
  static void celebrate(
    BuildContext context, {
    int particleCount = 150,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _CelebrationOverlay(
        particleCount: particleCount,
        duration: duration,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final VoidCallback onDone;

  const _CelebrationOverlay({
    required this.particleCount,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  final _random = Random();
  late final List<_Particle> _particles;

  // A bright, festive palette.
  static const _palette = [Color(0xFFFF595E), Color(0xFFFFFFFF)];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        xFraction: _random.nextDouble(), // spawn anywhere across the width
        startYFraction:
            -_random.nextDouble() * 0.3, // start just above the screen
        fallSpeed:
            0.8 + _random.nextDouble() * 0.6, // how far it falls over the run
        color: _palette[_random.nextInt(_palette.length)],
        size: 8 + _random.nextDouble() * 10,
        isCircle: _random.nextBool(),
        spin: (_random.nextDouble() - 0.5) * 12,
        sway: 20 + _random.nextDouble() * 50, // horizontal drift amount
        swaySpeed: 2 + _random.nextDouble() * 4, // how fast it sways
        startDelay:
            _random.nextDouble() * 0.4, // staggered so rain keeps coming
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
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _CelebrationPainter(_particles, _controller.value),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double xFraction,
      startYFraction,
      fallSpeed,
      size,
      spin,
      sway,
      swaySpeed,
      startDelay;
  final Color color;
  final bool isCircle;

  _Particle({
    required this.xFraction,
    required this.startYFraction,
    required this.fallSpeed,
    required this.color,
    required this.size,
    required this.isCircle,
    required this.spin,
    required this.sway,
    required this.swaySpeed,
    required this.startDelay,
  });
}

class _CelebrationPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _CelebrationPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      // Re-map time so each particle starts falling after its delay.
      final t = ((progress - p.startDelay) / (1 - p.startDelay)).clamp(
        0.0,
        1.0,
      );
      if (t == 0) continue;

      // Fall from top to (past) bottom.
      final startY = size.height * p.startYFraction;
      final y = startY + (size.height + size.height * 0.2) * t * p.fallSpeed;

      // Drift side to side as it falls.
      final x = size.width * p.xFraction + sin(t * p.swaySpeed * pi) * p.sway;
      final pos = Offset(x, y);

      // Fade only in the last third.
      final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      paint.color = p.color.withOpacity(opacity.clamp(0.0, 1.0));

      if (p.isCircle) {
        canvas.drawCircle(pos, p.size / 2, paint);
      } else {
        // Spinning streamer rectangle.
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.spin * t);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.45,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => old.progress != progress;
}

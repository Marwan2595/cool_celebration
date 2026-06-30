import 'dart:math';
import 'package:flutter/material.dart';

/// Wrap any screen with this widget, hold a [GlobalKey<ConfettiBurstState>],
/// and call `key.currentState?.celebrate()` to fire the confetti.
class ConfettiBurst extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Duration duration;

  const ConfettiBurst({
    super.key,
    required this.child,
    this.particleCount = 40,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ConfettiBurst> createState() => ConfettiBurstState();
}

class ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  final _random = Random();
  List<_Particle> _particles = [];

  void celebrate() {
    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        angle: _random.nextDouble() * 2 * pi,
        speed: 100 + _random.nextDouble() * 250,
        color: Color.fromARGB(
          255,
          _random.nextInt(256),
          _random.nextInt(256),
          _random.nextInt(256),
        ),
        size: 6 + _random.nextDouble() * 8,
      );
    });
    _controller.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_particles, _controller.value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double angle, speed, size;
  final Color color;
  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final origin = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    for (final p in particles) {
      final dist = p.speed * progress;
      final dx = cos(p.angle) * dist;
      final dy = sin(p.angle) * dist + (200 * progress * progress); // gravity
      paint.color = p.color.withOpacity(1 - progress);
      canvas.drawCircle(
        origin + Offset(dx, dy),
        p.size * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

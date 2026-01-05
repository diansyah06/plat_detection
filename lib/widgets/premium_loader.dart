import 'dart:math' as math;
import 'package:flutter/material.dart';

class PremiumLoader extends StatefulWidget {
  final String label;

  const PremiumLoader({super.key, required this.label});

  @override
  State<PremiumLoader> createState() => _PremiumLoaderState();
}

class _PremiumLoaderState extends State<PremiumLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return CustomPaint(
                painter: _LoaderPainter(
                  angle: t * 2 * math.pi,
                  colorA: colorScheme.primary,
                  colorB: colorScheme.secondary,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(widget.label, style: textTheme.bodyMedium),
      ],
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double angle;
  final Color colorA;
  final Color colorB;

  _LoaderPainter({required this.angle, required this.colorA, required this.colorB});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    paint.shader = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
      colors: [
        colorA.withOpacity(0.1),
        colorA,
        colorB,
        colorB.withOpacity(0.1),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
      transform: GradientRotation(angle),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3),
      angle,
      1.4 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.colorA != colorA ||
        oldDelegate.colorB != colorB;
  }
}


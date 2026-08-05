import 'package:flutter/material.dart';

class LegendaryCardShimmer extends StatefulWidget {
  const LegendaryCardShimmer({super.key});

  @override
  State<LegendaryCardShimmer> createState() => _LegendaryCardShimmerState();
}

class _LegendaryCardShimmerState extends State<LegendaryCardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travelDistance = constraints.maxWidth + constraints.maxHeight;

          return AnimatedBuilder(
            key: const ValueKey('legendary-card-shimmer'),
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -travelDistance / 2 + travelDistance * _controller.value,
                  0,
                ),
                child: child,
              );
            },
            child: Transform.rotate(
              angle: -0.35,
              child: Center(
                child: Container(
                  width: constraints.maxWidth * 0.24,
                  height: constraints.maxHeight * 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EpicCardSparkles extends StatefulWidget {
  const EpicCardSparkles({super.key});

  @override
  State<EpicCardSparkles> createState() => _EpicCardSparklesState();
}

class _EpicCardSparklesState extends State<EpicCardSparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
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
        key: const ValueKey('epic-card-sparkles'),
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _EpicSparklesPainter(progress: _controller.value),
        ),
      ),
    );
  }
}

class _EpicSparklesPainter extends CustomPainter {
  const _EpicSparklesPainter({required this.progress});

  final double progress;

  static const _sparkles = <(Offset, double, double)>[
    (Offset(0.12, 0.16), 5.0, 0.00),
    (Offset(0.79, 0.12), 3.5, 0.18),
    (Offset(0.91, 0.31), 5.5, 0.42),
    (Offset(0.18, 0.43), 3.0, 0.66),
    (Offset(0.72, 0.52), 4.5, 0.84),
    (Offset(0.08, 0.67), 4.0, 0.30),
    (Offset(0.88, 0.76), 3.0, 0.57),
    (Offset(0.26, 0.86), 5.0, 0.75),
    (Offset(0.62, 0.91), 3.5, 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (position, baseRadius, phaseOffset) in _sparkles) {
      final phase = (progress + phaseOffset) % 1;
      final intensity = 1 - (phase * 2 - 1).abs();
      final radius = baseRadius * (0.45 + intensity * 0.75);
      final center = Offset(
        position.dx * size.width,
        position.dy * size.height,
      );
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16 + intensity * 0.68)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..quadraticBezierTo(
          center.dx + radius * 0.18,
          center.dy - radius * 0.18,
          center.dx + radius,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx + radius * 0.18,
          center.dy + radius * 0.18,
          center.dx,
          center.dy + radius,
        )
        ..quadraticBezierTo(
          center.dx - radius * 0.18,
          center.dy + radius * 0.18,
          center.dx - radius,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx - radius * 0.18,
          center.dy - radius * 0.18,
          center.dx,
          center.dy - radius,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EpicSparklesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

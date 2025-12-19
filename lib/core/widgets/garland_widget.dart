import 'dart:math';
import 'package:flutter/material.dart';

/// Виджет, создающий эффект мерцающей гирлянды.
class GarlandWidget extends StatefulWidget {
  final int totalLights;

  const GarlandWidget({
    super.key,
    this.totalLights = 12,
  });

  @override
  State<GarlandWidget> createState() => _GarlandWidgetState();
}

class _GarlandWidgetState extends State<GarlandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 30),
          painter: _GarlandPainter(
            totalLights: widget.totalLights,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class _GarlandPainter extends CustomPainter {
  final int totalLights;
  final double animationValue;

  _GarlandPainter({
    required this.totalLights,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);

    // Рисуем слегка провисшую нить
    final controlPoint1 = Offset(size.width * 0.25, 10);
    final controlPoint2 = Offset(size.width * 0.75, 10);
    final endPoint = Offset(size.width, 0);
    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, endPoint.dx, endPoint.dy);

    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawPath(path, linePaint);

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.amberAccent,
    ];

    // Расставляем огоньки вдоль пути
    for (int i = 0; i < totalLights; i++) {
      final t = (i + 1) / (totalLights + 1);
      
      // Примерный расчет точки на кубической кривой Безье
      final x = _calculateBezier(t, 0, controlPoint1.dx, controlPoint2.dx, size.width);
      final y = _calculateBezier(t, 0, controlPoint1.dy, controlPoint2.dy, 0);

      final colorIndex = i % colors.length;
      final baseColor = colors[colorIndex];
      
      // Мерцание зависит от индекса и времени
      final opacity = 0.3 + (0.7 * sin(animationValue * pi + (i * 0.5)).abs());
      
      // Свечение (Glow)
      final glowPaint = Paint()
        ..color = baseColor.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawCircle(Offset(x, y), 6, glowPaint);

      // Сам огонек
      final lightPaint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), 2.5, lightPaint);
    }
  }

  double _calculateBezier(double t, double p0, double p1, double p2, double p3) {
    return pow(1 - t, 3) * p0 +
        3 * pow(1 - t, 2) * t * p1 +
        3 * (1 - t) * pow(t, 2) * p2 +
        pow(t, 3) * p3;
  }

  @override
  bool shouldRepaint(covariant _GarlandPainter oldDelegate) => true;
}


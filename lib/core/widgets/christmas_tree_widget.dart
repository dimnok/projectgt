import 'dart:math';
import 'package:flutter/material.dart';

/// Виджет красивой наряженной ёлки с мерцающей гирляндой.
class ChristmasTreeWidget extends StatefulWidget {
  /// Высота ёлки.
  final double height;

  /// Прозрачность всей композиции.
  final double opacity;

  /// Создает экземпляр [ChristmasTreeWidget].
  const ChristmasTreeWidget({
    super.key,
    this.height = 400,
    this.opacity = 0.2,
  });

  @override
  State<ChristmasTreeWidget> createState() => _ChristmasTreeWidgetState();
}

class _ChristmasTreeWidgetState extends State<ChristmasTreeWidget>
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
        return Opacity(
          opacity: widget.opacity,
          child: CustomPaint(
            size: Size(widget.height * 0.7, widget.height),
            painter: _TreePainter(animationValue: _controller.value),
          ),
        );
      },
    );
  }
}

class _TreePainter extends CustomPainter {
  final double animationValue;

  _TreePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottom = size.height * 0.9;
    
    // 1. Ствол
    final trunkWidth = size.width * 0.15;
    final trunkHeight = size.height * 0.15;
    final trunkRect = Rect.fromLTWH(
      centerX - trunkWidth / 2,
      bottom,
      trunkWidth,
      trunkHeight,
    );
    final trunkPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.brown.shade800, Colors.brown.shade600],
      ).createShader(trunkRect);
    canvas.drawRRect(RRect.fromRectAndRadius(trunkRect, const Radius.circular(4)), trunkPaint);

    // 2. Ветви (3 яруса)
    final treePaint = Paint()..style = PaintingStyle.fill;
    
    void drawLayer(double topY, double layerHeight, double layerWidth) {
      final path = Path();
      path.moveTo(centerX, topY);
      path.lineTo(centerX - layerWidth / 2, topY + layerHeight);
      // Немного вогнутое основание для красоты
      path.quadraticBezierTo(centerX, topY + layerHeight * 0.85, centerX + layerWidth / 2, topY + layerHeight);
      path.close();

      final rect = Rect.fromLTWH(centerX - layerWidth / 2, topY, layerWidth, layerHeight);
      treePaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.green.shade800, Colors.green.shade900],
      ).createShader(rect);
      
      canvas.drawPath(path, treePaint);
    }

    // Нижний ярус
    drawLayer(size.height * 0.4, size.height * 0.5, size.width);
    // Средний ярус
    drawLayer(size.height * 0.2, size.height * 0.45, size.width * 0.8);
    // Верхний ярус
    drawLayer(size.height * 0.05, size.height * 0.35, size.width * 0.55);

    // 3. Звезда
    final starPaint = Paint()
      ..color = Colors.amber
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 3 * animationValue);
    
    final starPath = Path();
    const starSize = 15.0;
    const starTop = 5.0;
    for (int i = 0; i < 5; i++) {
      double angle = i * 4 * pi / 5 - pi / 2;
      double x = centerX + cos(angle) * starSize;
      double y = starTop + starSize + sin(angle) * starSize;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);

    // 4. Шарики (украшения)
    final ballColors = [Colors.redAccent, Colors.blueAccent, Colors.amberAccent];
    final random = Random(42); // Фиксированный сид, чтобы шарики не прыгали
    for (int i = 0; i < 15; i++) {
      final y = size.height * (0.2 + random.nextDouble() * 0.65);
      // Ширина дерева на этой высоте (примерно)
      final currentWidth = size.width * (1.0 - (y / size.height) * 0.5);
      final x = centerX + (random.nextDouble() - 0.5) * currentWidth * 0.8;
      
      final ballPaint = Paint()..color = ballColors[random.nextInt(ballColors.length)];
      canvas.drawCircle(Offset(x, y), 5, ballPaint);
      // Блик на шарике
      canvas.drawCircle(
        Offset(x - 1.5, y - 1.5),
        1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }

    // 5. Гирлянда (мерцающие огни)
    for (int i = 0; i < 20; i++) {
      final t = i / 20;
      final y = size.height * (0.15 + t * 0.7);
      final x = centerX + sin(t * 10) * (size.width * 0.4 * t);

      final opacity = 0.3 + (0.7 * sin(animationValue * pi + i).abs());
      final lightPaint = Paint()
        ..color = Colors.yellowAccent.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * animationValue);

      canvas.drawCircle(Offset(x, y), 3, lightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => true;
}


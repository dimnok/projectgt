import 'dart:math';
import 'package:flutter/material.dart';

/// Виджет, создающий эффект падающих снежинок (Unicode символы).
class SnowfallWidget extends StatefulWidget {
  final Widget? child;
  final int totalSnowflakes;
  final double speed;

  const SnowfallWidget({
    super.key,
    this.child,
    this.totalSnowflakes = 35,
    this.speed = 1.0,
  });

  @override
  State<SnowfallWidget> createState() => _SnowfallWidgetState();
}

class _SnowfallWidgetState extends State<SnowfallWidget>
    with SingleTickerProviderStateMixin {
  late List<_Snowflake> _snowflakes;
  late AnimationController _controller;
  final Random _random = Random();

  // Набор красивых Unicode снежинок
  final List<String> _snowflakeChars = ['❄', '❅', '❆', '✻', '✼'];

  @override
  void initState() {
    super.initState();
    _snowflakes = List.generate(
      widget.totalSnowflakes,
      (index) => _Snowflake(
        _random.nextDouble(),
        _random.nextDouble(),
        _random.nextDouble() * 10 + 10, // Размер от 10 до 20
        _random.nextDouble() * 0.5 + 0.2, // Плотность/скорость
        _random.nextDouble() * pi * 2,
        _snowflakeChars[_random.nextInt(_snowflakeChars.length)],
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(() {
        _updateSnowflakes();
      })
      ..repeat();
  }

  Duration _lastElapsed = Duration.zero;

  void _updateSnowflakes() {
    final elapsed = _controller.lastElapsedDuration ?? Duration.zero;

    double delta;
    if (elapsed < _lastElapsed) {
      delta = 0.016;
    } else {
      delta = (elapsed - _lastElapsed).inMicroseconds / 1000000;
    }
    _lastElapsed = elapsed;

    if (delta <= 0 || delta > 0.1) delta = 0.016;

    setState(() {
      for (var snowflake in _snowflakes) {
        // Коэффициент 0.07 для более медленного и медитативного падения
        snowflake.update(widget.speed * delta * 0.07);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SnowPainter(_snowflakes),
            ),
          ),
        ),
      ],
    );
  }
}

class _Snowflake {
  double x;
  double y;
  double size;
  double density;
  double angle;
  String char;

  _Snowflake(this.x, this.y, this.size, this.density, this.angle, this.char);

  void update(double speedMultiplier) {
    angle += 0.01;
    y += (cos(angle) + 1 + density) * speedMultiplier;
    x += sin(angle) * 0.0005;

    if (y > 1.1) {
      y = -0.1;
      x = Random().nextDouble();
    }
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;

  _SnowPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var snowflake in snowflakes) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: snowflake.char,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: snowflake.size,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      // Центрируем снежинку по координатам и добавляем легкое вращение
      canvas.translate(snowflake.x * size.width, snowflake.y * size.height);
      canvas.rotate(snowflake.angle * 0.2);

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';

/// Кастомный виджет переключения сегментов с анимацией скольжения.
///
/// Позволяет выбирать одно значение из набора опций.
/// Аналог [CupertinoSlidingSegmentedControl], но с возможностью
/// полной кастомизации стилей, цветов и анимаций.
class CustomSlidingSegmentedControl<T> extends StatelessWidget {
  /// Map, где ключ - значение сегмента, а значение - виджет для отображения внутри сегмента.
  final Map<T, Widget> children;

  /// Текущее выбранное значение.
  final T groupValue;

  /// Callback, вызываемый при выборе сегмента.
  final ValueChanged<T> onValueChanged;

  /// Цвет фона всего контрола.
  final Color? backgroundColor;

  /// Цвет "ползунка" (активного выбранного элемента).
  final Color thumbColor;

  /// Радиус скругления углов (как для фона, так и для ползунка).
  final double borderRadius;

  /// Граница (border) для контейнера.
  final BoxBorder? border;

  /// Внутренние отступы контейнера.
  final EdgeInsets padding;

  /// Длительность анимации перемещения ползунка.
  final Duration duration;

  /// Кривая анимации перемещения ползунка.
  final Curve curve;

  /// Создает экземпляр [CustomSlidingSegmentedControl].
  const CustomSlidingSegmentedControl({
    super.key,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
    this.backgroundColor,
    required this.thumbColor,
    this.borderRadius = 20.0,
    this.border,
    this.padding = const EdgeInsets.all(4),
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    final keys = children.keys.toList();
    final selectedIndex = keys.indexOf(groupValue);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
      ),
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final itemWidth = availableWidth / children.length;

          return Stack(
            children: [
              // Thumb (движущийся переключатель)
              AnimatedPositioned(
                duration: duration,
                curve: curve,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(
                        borderRadius - padding.top > 0
                            ? borderRadius - padding.top
                            : borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Items (элементы табов)
              Row(
                children: keys.map((key) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => onValueChanged(key),
                      child: Container(
                        alignment: Alignment.center,
                        child: children[key],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

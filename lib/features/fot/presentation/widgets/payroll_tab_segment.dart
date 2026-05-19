import 'package:flutter/material.dart';

/// Сегментированный переключатель вкладок модуля ФОТ.
///
/// Визуально согласован с [TimesheetEmployeeListScopeSegment] в модуле табеля.
class PayrollTabSegment extends StatelessWidget {
  /// Создаёт сегмент вкладок ФОТ.
  const PayrollTabSegment({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  /// Индекс активной вкладки: 0 ФОТ, 1 Премии, 2 Штрафы, 3 Выплаты.
  final int selectedIndex;

  /// Вызывается при выборе вкладки.
  final ValueChanged<int> onChanged;

  static const double _height = 30;
  static const double _radius = 16;
  static const double _segmentHorizontalPadding = 10;

  static const List<String> _labels = ['ФОТ', 'Премии', 'Штрафы', 'Выплаты'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final borderColor = scheme.outline.withValues(alpha: 0.38);
    final trackFill = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final selectedFill = scheme.surface;
    final outlineSelected = scheme.outline.withValues(alpha: 0.22);
    final shadowSoft = scheme.shadow.withValues(alpha: 0.1);

    TextStyle segmentText(bool selected) {
      final base = theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!;
      return base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
        height: 1.1,
        color: selected
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.52),
      );
    }

    Widget segment({required int index}) {
      final selected = selectedIndex == index;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius - 3),
          onTap: () {
            if (!selected) onChanged(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: _segmentHorizontalPadding,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius - 3),
              color: selected ? selectedFill : Colors.transparent,
              border: Border.all(
                color: selected ? outlineSelected : Colors.transparent,
                width: 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: shadowSoft,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              _labels[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: segmentText(selected),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: 'Вкладка: ${_labels[selectedIndex]}',
        child: SizedBox(
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: borderColor),
              color: trackFill,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _labels.length,
                  (index) => segment(index: index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

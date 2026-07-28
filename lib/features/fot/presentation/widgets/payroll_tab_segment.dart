import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

import 'payroll_toolbar_metrics.dart';

/// Сегментированный переключатель вкладок модуля ФОТ.
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

  static const List<String> _labels = ['ФОТ', 'Премии', 'Штрафы', 'Выплаты'];

  @override
  Widget build(BuildContext context) {
    final collapsible = ResponsiveUtils.isDesktop(context);

    if (!collapsible) {
      return PayrollToolbarSegmentTrack(
        semanticsLabel: 'Вкладка: ${_labels[selectedIndex]}',
        children: List.generate(_labels.length, (index) {
          final selected = selectedIndex == index;
          return PayrollToolbarSegmentChip(
            label: _labels[index],
            selected: selected,
            onTap: () {
              if (!selected) onChanged(index);
            },
          );
        }),
      );
    }

    return PayrollToolbarCollapsibleSegmentTrack(
      semanticsLabel: 'Вкладка: ${_labels[selectedIndex]}',
      selectedLabel: _labels[selectedIndex],
      children: [
        PayrollToolbarSegmentChip(
          label: _labels[selectedIndex],
          selected: true,
          onTap: () {},
        ),
        for (var index = 0; index < _labels.length; index++)
          if (index != selectedIndex)
            PayrollToolbarSegmentChip(
              label: _labels[index],
              selected: false,
              onTap: () => onChanged(index),
            ),
      ],
    );
  }
}

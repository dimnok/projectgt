import 'package:flutter/material.dart';

import '../../../../domain/entities/estimate.dart';

/// Подпись подсистемы для фильтра и отображения (пустое значение в БД).
String estimateSubsystemFilterLabel(Estimate item) {
  final trimmed = item.subsystem.trim();
  return trimmed.isEmpty ? 'Без подсистемы' : trimmed;
}

/// Уникальные подсистемы позиций сметы, отсортированные по алфавиту.
List<String> collectEstimateSubsystemLabels(Iterable<Estimate> items) {
  final labels = <String>{};
  for (final item in items) {
    labels.add(estimateSubsystemFilterLabel(item));
  }
  return labels.toList()..sort((a, b) => a.compareTo(b));
}

/// Горизонтальная полоса текстовых переключателей фильтра по подсистеме над таблицей.
class EstimateSubsystemFilterBar extends StatelessWidget {
  /// Создаёт [EstimateSubsystemFilterBar].
  const EstimateSubsystemFilterBar({
    super.key,
    required this.subsystems,
    required this.selectedSubsystem,
    required this.onSelected,
  });

  /// Доступные подсистемы (без пункта «Все»).
  final List<String> subsystems;

  /// Выбранная подсистема; `null` — показать все.
  final String? selectedSubsystem;

  /// Выбор подсистемы (`null` — сброс на «Все»).
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _EstimateSubsystemTextChip(
              scheme: scheme,
              label: 'Все',
              selected: selectedSubsystem == null,
              onTap: () => onSelected(null),
            ),
            for (final subsystem in subsystems) ...[
              const SizedBox(width: 16),
              _EstimateSubsystemTextChip(
                scheme: scheme,
                label: subsystem,
                selected: selectedSubsystem == subsystem,
                onTap: () {
                  onSelected(
                    selectedSubsystem == subsystem ? null : subsystem,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateSubsystemTextChip extends StatelessWidget {
  const _EstimateSubsystemTextChip({
    required this.scheme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ColorScheme scheme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.35,
            decoration: selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: scheme.primary,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}

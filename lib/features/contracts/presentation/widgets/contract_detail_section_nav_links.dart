import 'package:flutter/material.dart';

import 'package:projectgt/features/contracts/presentation/widgets/contract_detail_navigation_section.dart';
import 'package:projectgt/core/widgets/gt_text_action_link.dart';

/// Текстовые ссылки разделов экрана детализации договора (встроенный список).
///
/// Выбор передаётся в [ContractDetailsPanel] через фильтр [detailSectionFilter].
class ContractDetailSectionNavLinks extends StatelessWidget {
  /// Текущий выбранный раздел подсветкой [GtTextActionLink.selected].
  const ContractDetailSectionNavLinks({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Активный раздел карточки.
  final ContractDetailNavigationSection selected;

  /// Смена раздела (например, из [StatefulWidget.setState] родителя).
  final ValueChanged<ContractDetailNavigationSection> onSelected;

  static final List<ContractDetailNavigationSection> _order =
      List<ContractDetailNavigationSection>.unmodifiable(
    ContractDetailNavigationSection.values,
  );

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 20,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final section in _order)
          GtTextActionLink(
            label: section.label,
            selected: selected == section,
            onTap: () => onSelected(section),
          ),
      ],
    );
  }
}

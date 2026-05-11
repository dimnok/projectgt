import 'package:flutter/material.dart';

import 'package:projectgt/features/works/presentation/widgets/work_detail_data_spacing.dart';

/// Единая оболочка для верхней зоны панели смены на десктопе: переключатель вкладок
/// и опциональная полоса под ним (фильтры).
///
/// Даёт один уровень глубины ([surfaceContainerLow]), предсказуемые поля и разделитель
/// между основным навигационным действием и вторичными фильтрами — без «ящика в ящике».
class WorkDetailsDesktopHeaderChrome extends StatelessWidget {
  /// Сегментированный переключатель «Данные / Работы / Сотрудники».
  final Widget segmentBar;

  /// Содержимое под разделителем (например фильтры) или пустой виджет.
  final Widget belowSegment;

  /// Создаёт хром шапки десктопной панели деталей смены.
  const WorkDetailsDesktopHeaderChrome({
    super.key,
    required this.segmentBar,
    this.belowSegment = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: WorkDetailDataSpacing.desktopHeaderOuter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(
            WorkDetailDataSpacing.desktopHeaderRadius,
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: WorkDetailDataSpacing.desktopHeaderSegmentInner,
              child: segmentBar,
            ),
            belowSegment,
          ],
        ),
      ),
    );
  }
}

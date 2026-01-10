import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../widgets/payroll_penalty_table_widget.dart';

/// Таб "Штрафы" в модуле ФОТ.
///
/// Отображает таблицу всех штрафов за текущий месяц с возможностью добавления и редактирования штрафов.
/// Использует строгий минималистичный стиль, поддерживает адаптивность и работу на всех платформах.
class PayrollTabPenalties extends StatelessWidget {
  /// Конструктор таба "Штрафы".
  ///
  /// [key] — ключ виджета.
  const PayrollTabPenalties({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    const content = PayrollPenaltyTableWidget();

    if (isMobile) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: content,
        ),
      ),
    );
  }
}

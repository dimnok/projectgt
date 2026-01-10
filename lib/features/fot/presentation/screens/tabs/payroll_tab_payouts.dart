import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../widgets/payroll_payout_table_widget.dart';

/// Таб "Выплаты" в модуле ФОТ.
/// Отображает таблицу всех выплат с возможностью добавления выплат.
class PayrollTabPayouts extends StatelessWidget {
  /// Конструктор [PayrollTabPayouts].
  ///
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollTabPayouts({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    const content = PayrollPayoutTableWidget();

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

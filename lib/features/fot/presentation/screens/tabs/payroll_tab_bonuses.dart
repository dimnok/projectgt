import 'package:flutter/material.dart';
import '../../widgets/payroll_bonus_table_widget.dart';
import '../../widgets/payroll_transaction_form_modal.dart';
import '../../../domain/entities/payroll_transaction.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Таб "Премии" в модуле ФОТ.
///
/// Отображает таблицу всех премий за текущий месяц с возможностью добавления и редактирования премий.
/// Использует строгий минималистичный стиль, поддерживает адаптивность и работу на всех платформах.
class PayrollTabBonuses extends StatelessWidget {
  /// Конструктор таба "Премии".
  ///
  /// [key] — ключ виджета.
  const PayrollTabBonuses({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 51),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              const PayrollBonusTableWidget(),
              Positioned(
                right: 8,
                bottom: 8,
                child: PermissionGuard(
                  module: 'payroll',
                  permission: 'create',
                child: FloatingActionButton(
                  heroTag: 'addPayrollBonus',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            kToolbarHeight,
                      ),
                      builder: (ctx) => const PayrollTransactionFormModal(
                        transactionType: PayrollTransactionType.bonus,
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

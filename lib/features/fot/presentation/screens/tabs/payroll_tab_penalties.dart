import 'package:flutter/material.dart';
import '../../widgets/payroll_penalty_table_widget.dart';
import '../../widgets/payroll_transaction_form_modal.dart';
import '../../../domain/entities/payroll_transaction.dart';

/// Таб "Штрафы" в модуле ФОТ.
///
/// Отображает таблицу всех штрафов за выбранный период с возможностью добавления и редактирования штрафов.
/// Использует строгий минималистичный стиль, поддерживает адаптивность и работу на всех платформах.
class PayrollTabPenalties extends StatelessWidget {
  /// Конструктор таба "Штрафы".
  ///
  /// [key] — ключ виджета.
  const PayrollTabPenalties({super.key});

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
              const PayrollPenaltyTableWidget(),
              Positioned(
                right: 8,
                bottom: 8,
                child: FloatingActionButton(
                  heroTag: 'addPayrollPenalty',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                      ),
                      builder: (ctx) => const PayrollTransactionFormModal(
                        transactionType: PayrollTransactionType.penalty,
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
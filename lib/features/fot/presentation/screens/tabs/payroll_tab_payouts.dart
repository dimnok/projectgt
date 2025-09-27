import 'package:flutter/material.dart';
import '../../widgets/payroll_payout_table_widget.dart';
import '../../widgets/payroll_payout_form_modal.dart';

/// Таб "Выплаты" в модуле ФОТ.
/// Отображает таблицу всех выплат за выбранный период с возможностью добавления выплат.
class PayrollTabPayouts extends StatelessWidget {
  /// Конструктор [PayrollTabPayouts].
  ///
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollTabPayouts({super.key});

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
          child: Column(
            children: [
              // Таблица выплат с правильной структурой для вертикальной прокрутки
              Expanded(
                child: Stack(
                  children: [
                    const PayrollPayoutTableWidget(),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: FloatingActionButton(
                        heroTag: 'addPayrollPayout',
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
                            builder: (ctx) => const PayrollPayoutFormModal(),
                          );
                        },
                        tooltip: 'Добавить выплату',
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

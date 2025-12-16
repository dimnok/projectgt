import 'package:flutter/material.dart';
import '../../widgets/payroll_payout_table_widget.dart';
import '../../widgets/payroll_payout_form_modal.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Таб "Выплаты" в модуле ФОТ.
/// Отображает таблицу всех выплат с возможностью добавления выплат.
class PayrollTabPayouts extends StatelessWidget {
  /// Конструктор [PayrollTabPayouts].
  ///
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollTabPayouts({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color:
                Color(0xFF66BB6A), // Цвет таба "Выплаты" (Material Green 400)
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    const PayrollPayoutTableWidget(),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: PermissionGuard(
                        module: 'payroll',
                        permission: 'create',
                        child: FloatingActionButton(
                          heroTag: 'addPayrollPayout',
                          shape: const CircleBorder(),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              useSafeArea: true,
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

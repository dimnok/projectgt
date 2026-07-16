import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

import '../../domain/entities/payroll_transaction.dart';
import 'payroll_employee_status_filter_segment.dart';
import 'payroll_payout_excel_import_dialog.dart';
import 'payroll_payout_form_modal.dart';
import 'payroll_toolbar_metrics.dart';
import 'payroll_transaction_form_modal.dart';

/// Действия справа в панели фильтров ФОТ — зависят от активной вкладки.
class PayrollTabToolbarActions extends StatelessWidget {
  /// Создаёт блок действий для панели фильтров.
  const PayrollTabToolbarActions({super.key, required this.selectedTabIndex});

  /// 0 — ФОТ, 1 — Премии, 2 — Штрафы, 3 — Выплаты.
  final int selectedTabIndex;

  static void _openTransactionForm(
    BuildContext context,
    PayrollTransactionType type,
  ) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => PayrollTransactionFormModal(transactionType: type),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PayrollTransactionFormModal(transactionType: type),
      );
    }
  }

  static void _openPayoutForm(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => const PayrollPayoutFormModal(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const PayrollPayoutFormModal(),
      );
    }
  }

  static void _openPayoutExcelImport(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => const PayrollPayoutExcelImportDialog(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const PayrollPayoutExcelImportDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PayrollToolbarMetrics.height,
      child: switch (selectedTabIndex) {
        0 => const PayrollEmployeeStatusFilterSegment(),
        1 => PermissionGuard(
          module: 'payroll',
          permission: 'create',
          child: PayrollToolbarTextButton(
            text: 'Добавить',
            icon: Icons.add_circle_outline,
            onPressed: () => _openTransactionForm(
              context,
              PayrollTransactionType.bonus,
            ),
          ),
        ),
        2 => PermissionGuard(
          module: 'payroll',
          permission: 'create',
          child: PayrollToolbarTextButton(
            text: 'Добавить',
            icon: Icons.add_circle_outline,
            onPressed: () => _openTransactionForm(
              context,
              PayrollTransactionType.penalty,
            ),
          ),
        ),
        3 => PermissionGuard(
          module: 'payroll',
          permission: 'create',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PayrollToolbarTextButton(
                text: ResponsiveUtils.isMobile(context)
                    ? 'Импорт'
                    : 'Импорт из Excel',
                icon: Icons.upload_file_outlined,
                onPressed: () => _openPayoutExcelImport(context),
              ),
              const SizedBox(width: 8),
              PayrollToolbarTextButton(
                text: 'Добавить',
                icon: Icons.add_circle_outline,
                onPressed: () => _openPayoutForm(context),
              ),
            ],
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

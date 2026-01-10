import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/gt_confirmation_dialog.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/gt_context_menu.dart';
import '../../domain/entities/payroll_transaction.dart';
import '../providers/penalty_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/payroll_providers.dart';
import 'payroll_transaction_form_modal.dart';
import 'fot_transaction_table_widget.dart';
import 'fot_transaction_mobile_view.dart';

/// Таблица штрафов, использующая [GTAdaptiveTable].
class PayrollPenaltyTableView extends ConsumerStatefulWidget {
  /// Список штрафов.
  final List<PayrollTransaction> penalties;

  /// Список сотрудников для маппинга имен.
  final List<dynamic> employees;

  /// Список объектов для маппинга имен.
  final List<dynamic> objects;

  /// Создаёт экземпляр [PayrollPenaltyTableView].
  const PayrollPenaltyTableView({
    super.key,
    required this.penalties,
    required this.employees,
    required this.objects,
  });

  @override
  ConsumerState<PayrollPenaltyTableView> createState() => _PayrollPenaltyTableViewState();
}

class _PayrollPenaltyTableViewState extends ConsumerState<PayrollPenaltyTableView> {
  /// Текущий выбранный штраф для подсветки строки.
  PayrollTransaction? _highlightedPenalty;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return FOTTransactionMobileView(
        transactions: widget.penalties,
        employees: widget.employees,
        objects: widget.objects,
        type: FOTTransactionTableType.penalty,
        onRowLongPress: (transaction, position) =>
            _showContextMenu(context, transaction, position),
      );
    }

    return FOTTransactionTable(
      transactions: widget.penalties,
      employees: widget.employees,
      objects: widget.objects,
      type: FOTTransactionTableType.penalty,
      highlightedItem: _highlightedPenalty,
      onRowTap: (penalty, position) => _showContextMenu(context, penalty, position),
    );
  }

  void _showContextMenu(BuildContext context, PayrollTransaction penalty, Offset position) {
    setState(() => _highlightedPenalty = penalty);

    GTContextMenu.show(
      context: context,
      tapPosition: position,
      onDismiss: () => setState(() => _highlightedPenalty = null),
      items: [
        GTContextMenuItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () => _showEditForm(context, penalty),
        ),
        const Divider(height: 4, indent: 8, endIndent: 8),
        GTContextMenuItem(
          icon: CupertinoIcons.trash,
          label: 'Удалить',
          isDestructive: true,
          onTap: () => _showDeleteConfirmation(context, penalty),
        ),
      ],
    );
  }


  void _showEditForm(BuildContext context, PayrollTransaction penalty) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.penalty,
          transaction: penalty,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.penalty,
          transaction: penalty,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PayrollTransaction penalty,
  ) async {
    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить штраф?',
      message: 'Вы действительно хотите удалить этот штраф?',
      confirmText: 'Удалить',
      type: GTConfirmationType.danger,
    );

    if (confirmed == true) {
      try {
        final deletePenalty = ref.read(deletePenaltyUseCaseProvider);
        await deletePenalty(penalty.id);
        ref.invalidate(penaltiesByFilterProvider);
        ref.invalidate(employeeAggregatedBalanceProvider);
        ref.invalidate(payrollPayoutsByFilterProvider);
        ref.invalidate(filteredPayrollsProvider);
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, 'Штраф удалён');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Ошибка удаления: $e');
        }
      }
    }
  }
}


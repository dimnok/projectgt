import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/gt_confirmation_dialog.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/gt_context_menu.dart';
import '../../domain/entities/payroll_transaction.dart';
import '../providers/bonus_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/payroll_providers.dart';
import 'payroll_transaction_form_modal.dart';
import 'fot_transaction_table_widget.dart';
import 'fot_transaction_mobile_view.dart';

/// Таблица премий, использующая [GTAdaptiveTable].
class PayrollBonusTableView extends ConsumerStatefulWidget {
  /// Список премий.
  final List<PayrollTransaction> bonuses;

  /// Список сотрудников для маппинга имен.
  final List<dynamic> employees;

  /// Список объектов для маппинга имен.
  final List<dynamic> objects;

  /// Создаёт экземпляр [PayrollBonusTableView].
  const PayrollBonusTableView({
    super.key,
    required this.bonuses,
    required this.employees,
    required this.objects,
  });

  @override
  ConsumerState<PayrollBonusTableView> createState() =>
      _PayrollBonusTableViewState();
}

class _PayrollBonusTableViewState extends ConsumerState<PayrollBonusTableView> {
  /// Текущая выбранная премия для подсветки строки.
  PayrollTransaction? _highlightedBonus;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return FOTTransactionMobileView(
        transactions: widget.bonuses,
        employees: widget.employees,
        objects: widget.objects,
        type: FOTTransactionTableType.bonus,
        onRowLongPress: (transaction, position) =>
            _showContextMenu(context, transaction, position),
      );
    }

    return FOTTransactionTable(
      transactions: widget.bonuses,
      employees: widget.employees,
      objects: widget.objects,
      type: FOTTransactionTableType.bonus,
      highlightedItem: _highlightedBonus,
      onRowTap: (bonus, position) => _showContextMenu(context, bonus, position),
    );
  }

  void _showContextMenu(
    BuildContext context,
    PayrollTransaction bonus,
    Offset position,
  ) {
    setState(() => _highlightedBonus = bonus);

    GTContextMenu.show(
      context: context,
      tapPosition: position,
      onDismiss: () => setState(() => _highlightedBonus = null),
      items: [
        GTContextMenuItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () => _showEditForm(context, bonus),
        ),
        const Divider(height: 4, indent: 8, endIndent: 8),
        GTContextMenuItem(
          icon: CupertinoIcons.trash,
          label: 'Удалить',
          isDestructive: true,
          onTap: () => _showDeleteConfirmation(context, bonus),
        ),
      ],
    );
  }

  void _showEditForm(BuildContext context, PayrollTransaction bonus) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.bonus,
          transaction: bonus,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.bonus,
          transaction: bonus,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PayrollTransaction bonus,
  ) async {
    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить премию?',
      message: 'Вы действительно хотите удалить эту премию?',
      confirmText: 'Удалить',
      type: GTConfirmationType.danger,
    );

    if (confirmed == true) {
      try {
        final deleteBonus = ref.read(deleteBonusUseCaseProvider);
        await deleteBonus(bonus.id);
        ref.invalidate(bonusesByFilterProvider);
        ref.invalidate(employeeAggregatedBalanceProvider);
        ref.invalidate(payrollPayoutsByFilterProvider);
        ref.invalidate(filteredPayrollsProvider);
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, 'Премия удалена');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Ошибка удаления: $e');
        }
      }
    }
  }
}

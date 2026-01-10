import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gt_confirmation_dialog.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/gt_context_menu.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/payroll_payout_model.dart';
import '../providers/payroll_providers.dart';
import '../providers/balance_providers.dart';
import 'payroll_payout_form_modal.dart';
import 'fot_payout_table_widget.dart';
import 'fot_payout_mobile_view.dart';

/// Таблица выплат, использующая [GTAdaptiveTable].
class PayrollPayoutTableView extends ConsumerStatefulWidget {
  /// Список выплат.
  final List<PayrollPayoutModel> payouts;

  /// Список сотрудников для маппинга имен.
  final List<dynamic> employees;

  /// Создаёт экземпляр [PayrollPayoutTableView].
  const PayrollPayoutTableView({
    super.key,
    required this.payouts,
    required this.employees,
  });

  @override
  ConsumerState<PayrollPayoutTableView> createState() => _PayrollPayoutTableViewState();
}

class _PayrollPayoutTableViewState extends ConsumerState<PayrollPayoutTableView> {
  /// Текущая выбранная выплата для подсветки строки.
  PayrollPayoutModel? _highlightedPayout;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return FOTPayoutMobileView(
        payouts: widget.payouts,
        employees: widget.employees,
        onRowLongPress: (payout, position) =>
            _showContextMenu(context, payout, position),
      );
    }

    return FOTPayoutTable(
      payouts: widget.payouts,
      employees: widget.employees,
      highlightedItem: _highlightedPayout,
      onRowTap: (payout, position) => _showContextMenu(context, payout, position),
    );
  }

  void _showContextMenu(BuildContext context, PayrollPayoutModel payout, Offset position) {
    setState(() => _highlightedPayout = payout);

    GTContextMenu.show(
      context: context,
      tapPosition: position,
      onDismiss: () => setState(() => _highlightedPayout = null),
      items: [
        GTContextMenuItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () => _showEditForm(context, payout),
        ),
        const Divider(height: 4, indent: 8, endIndent: 8),
        GTContextMenuItem(
          icon: CupertinoIcons.trash,
          label: 'Удалить',
          isDestructive: true,
          onTap: () => _showDeleteConfirmation(context, payout),
        ),
      ],
    );
  }


  void _showEditForm(BuildContext context, PayrollPayoutModel payout) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => PayrollPayoutFormModal(payout: payout),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PayrollPayoutFormModal(payout: payout),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PayrollPayoutModel payout,
  ) async {
    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить выплату?',
      message: 'Вы действительно хотите удалить эту выплату?',
      confirmText: 'Удалить',
      type: GTConfirmationType.danger,
    );

    if (confirmed == true) {
      try {
        final deletePayout = ref.read(deletePayoutUseCaseProvider);
        await deletePayout(payout.id);
        ref.invalidate(payrollPayoutsByFilterProvider);
        ref.invalidate(employeeAggregatedBalanceProvider);
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, 'Выплата удалена');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(context, 'Ошибка удаления: $e');
        }
      }
    }
  }
}


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_payment.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';

/// Диалог добавления / редактирования оплаты по счёту.
class SettlementPaymentFormDialog extends ConsumerStatefulWidget {
  /// Счёт, к которому относится оплата.
  final String settlementOperationId;

  /// Существующая оплата (null — создание).
  final SettlementPayment? payment;

  /// Создаёт диалог.
  const SettlementPaymentFormDialog({
    super.key,
    required this.settlementOperationId,
    this.payment,
  });

  /// Показать диалог / bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String settlementOperationId,
    SettlementPayment? payment,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final child = SettlementPaymentFormDialog(
      settlementOperationId: settlementOperationId,
      payment: payment,
    );
    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: child,
        ),
      );
    }
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  @override
  ConsumerState<SettlementPaymentFormDialog> createState() =>
      _SettlementPaymentFormDialogState();
}

class _SettlementPaymentFormDialogState
    extends ConsumerState<SettlementPaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _paymentDate;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _noteController;
  bool _saving = false;

  String _fmtAmount(num value) => GtFormatters.formatAmount(value)
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u202F', ' ');

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _paymentDate = payment?.paymentDate ?? DateTime.now();
    _amountController = TextEditingController(
      text: payment != null ? _fmtAmount(payment.amount) : '',
    );
    _dateController = TextEditingController(text: formatRuDate(_paymentDate));
    _noteController = TextEditingController(text: payment?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<TextInputFormatter> get _moneyFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        amountFormatter(),
      ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _paymentDate = picked;
      _dateController.text = formatRuDate(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!ref.read(permissionServiceProvider).can('settlements', 'update')) {
      AppSnackBar.show(
        context: context,
        message: 'Недостаточно прав для изменения оплат',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null) {
      AppSnackBar.show(
        context: context,
        message: 'Не выбрана активная компания',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final amount = parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите сумму оплаты',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _saving = true);

    final existing = widget.payment;
    final payment = SettlementPayment(
      id: existing?.id ?? '',
      companyId: companyId,
      settlementOperationId: widget.settlementOperationId,
      paymentDate: _paymentDate,
      amount: amount,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: existing?.createdAt,
      createdBy: existing?.createdBy,
    );

    final notifier = ref.read(
      settlementPaymentsProvider(widget.settlementOperationId).notifier,
    );
    final result = existing == null
        ? await notifier.create(payment)
        : await notifier.update(payment);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result == null) {
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить оплату',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    AppSnackBar.show(
      context: context,
      message: existing == null ? 'Оплата добавлена' : 'Оплата обновлена',
      kind: AppSnackBarKind.success,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final title = widget.payment == null ? 'Новая оплата' : 'Редактировать оплату';

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GTTextField(
            controller: _amountController,
            labelText: 'Сумма',
            prefixIcon: CupertinoIcons.money_rubl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _moneyFormatters,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Укажите сумму';
              final n = parseAmount(v);
              if (n == null || n <= 0) return 'Сумма должна быть > 0';
              return null;
            },
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _dateController,
            labelText: 'Дата оплаты',
            prefixIcon: CupertinoIcons.calendar,
            readOnly: true,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          GTTextField(
            controller: _noteController,
            labelText: 'Примечание',
            maxLines: 3,
          ),
        ],
      ),
    );

    final footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GTPrimaryButton(
            text: 'Сохранить',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ),
      ],
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        width: 480,
        footer: footer,
        child: content,
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: content,
    );
  }
}

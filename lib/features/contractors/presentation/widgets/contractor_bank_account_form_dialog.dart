import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor_bank_account.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_bank_account_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';

/// Диалоговое окно для добавления или редактирования банковского счета контрагента.
class ContractorBankAccountFormDialog extends ConsumerStatefulWidget {
  /// Идентификатор контрагента, которому принадлежит счет.
  final String contractorId;

  /// Существующий счет для редактирования (если null — создание нового).
  final ContractorBankAccount? account;

  /// Создает диалог для работы с банковским счетом.
  const ContractorBankAccountFormDialog({
    super.key,
    required this.contractorId,
    this.account,
  });

  @override
  ConsumerState<ContractorBankAccountFormDialog> createState() =>
      _ContractorBankAccountFormDialogState();
}

class _ContractorBankAccountFormDialogState
    extends ConsumerState<ContractorBankAccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankNameController;
  late final TextEditingController _bikController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _corrAccountController;
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bankNameController =
        TextEditingController(text: widget.account?.bankName ?? '');
    _bikController = TextEditingController(text: widget.account?.bik ?? '');
    _accountNumberController =
        TextEditingController(text: widget.account?.accountNumber ?? '');
    _corrAccountController =
        TextEditingController(text: widget.account?.corrAccount ?? '');
    _isPrimary = widget.account?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bikController.dispose();
    _accountNumberController.dispose();
    _corrAccountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final activeCompanyId = ref.read(activeCompanyIdProvider);
      if (activeCompanyId == null) {
        throw Exception('Компания не выбрана');
      }

      final account = ContractorBankAccount(
        id: widget.account?.id ?? '',
        companyId: widget.account?.companyId ?? activeCompanyId,
        contractorId: widget.contractorId,
        bankName: _bankNameController.text.trim(),
        bik: _bikController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        corrAccount: _corrAccountController.text.trim(),
        isPrimary: _isPrimary,
      );

      final notifier = ref.read(
        contractorBankAccountNotifierProvider(widget.contractorId).notifier,
      );

      if (widget.account == null) {
        await notifier.addAccount(account);
      } else {
        await notifier.updateAccount(account);
      }

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.showSuccess(
          context,
          widget.account == null ? 'Счет добавлен' : 'Счет обновлен',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final title = widget.account == null ? 'Новый счет' : 'Редактировать счет';

    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: widget.account == null ? 'Добавить' : 'Сохранить',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ),
      ],
    );

    final formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GTTextField(
            controller: _bankNameController,
            labelText: 'Название банка',
            prefixIcon: Icons.account_balance,
            validator: (v) =>
                v == null || v.isEmpty ? 'Введите название банка' : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _bikController,
            labelText: 'БИК',
            prefixIcon: Icons.numbers,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            validator: (v) =>
                v == null || v.length != 9 ? 'БИК должен быть 9 цифр' : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _accountNumberController,
            labelText: 'Номер счета',
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (v) => v == null || v.length != 20
                ? 'Номер счета должен быть 20 цифр'
                : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _corrAccountController,
            labelText: 'Корр. счет',
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (v) => v == null || v.length != 20
                ? 'Корр. счет должен быть 20 цифр'
                : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Счет по умолчанию'),
            value: _isPrimary,
            onChanged: (v) => setState(() => _isPrimary = v),
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        footer: footer,
        child: formContent,
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: formContent,
    );
  }
}

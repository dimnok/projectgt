import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/company/domain/entities/company_bank_account.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

/// Диалоговое окно для добавления или редактирования банковского счета.
class CompanyBankAccountEditDialog extends ConsumerStatefulWidget {
  /// Идентификатор компании.
  final String companyId;

  /// Редактируемый счет (null при создании нового).
  final CompanyBankAccount? account;

  /// Создаёт диалог.
  const CompanyBankAccountEditDialog({
    super.key,
    required this.companyId,
    this.account,
  });

  /// Показывает диалог адаптивно (Dialog на Desktop, BottomSheet на Mobile).
  static void show(
    BuildContext context,
    String companyId, {
    CompanyBankAccount? account,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: CompanyBankAccountEditDialog(
            companyId: companyId,
            account: account,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CompanyBankAccountEditDialog(
          companyId: companyId,
          account: account,
        ),
      );
    }
  }

  @override
  ConsumerState<CompanyBankAccountEditDialog> createState() =>
      _CompanyBankAccountEditDialogState();
}

class _CompanyBankAccountEditDialogState
    extends ConsumerState<CompanyBankAccountEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _bankNameController;
  late TextEditingController _bankCityController;
  late TextEditingController _accountNumberController;
  late TextEditingController _corrAccountController;
  late TextEditingController _bikController;
  late bool _isPrimary;
  bool _isOnlyAccount = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _bankNameController = TextEditingController(text: a?.bankName);
    _bankCityController = TextEditingController(text: a?.bankCity);
    _accountNumberController = TextEditingController(text: a?.accountNumber);
    _corrAccountController = TextEditingController(text: a?.corrAccount);
    _bikController = TextEditingController(text: a?.bik);

    final existingAccounts = ref.read(companyBankAccountsProvider).value ?? [];
    _isOnlyAccount =
        existingAccounts.isEmpty ||
        (existingAccounts.length == 1 && widget.account != null);

    // Если счет один, он автоматически основной
    _isPrimary = _isOnlyAccount ? true : (a?.isPrimary ?? false);
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankCityController.dispose();
    _accountNumberController.dispose();
    _corrAccountController.dispose();
    _bikController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(companyRepositoryProvider);

      if (widget.account != null) {
        final updated = widget.account!.copyWith(
          bankName: _bankNameController.text,
          bankCity: _bankCityController.text,
          accountNumber: _accountNumberController.text,
          corrAccount: _corrAccountController.text,
          bik: _bikController.text,
          isPrimary: _isPrimary,
        );
        await repo.updateBankAccount(updated);
      } else {
        final newAccount = CompanyBankAccount(
          id: '', // Supabase generated
          companyId: widget.companyId,
          bankName: _bankNameController.text,
          bankCity: _bankCityController.text,
          accountNumber: _accountNumberController.text,
          corrAccount: _corrAccountController.text,
          bik: _bikController.text,
          isPrimary: _isPrimary,
        );
        await repo.addBankAccount(newAccount);
      }

      ref.invalidate(companyBankAccountsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(
          context: context,
          message: 'Банковские реквизиты сохранены',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при сохранении: $e',
          kind: AppSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePrimary(bool? value) async {
    if (_isOnlyAccount) return;

    if (!_isPrimary) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: DesktopDialogContent(
            title: 'Смена основного счета',
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GTSecondaryButton(
                  text: 'Отмена',
                  onPressed: () => Navigator.pop(context, false),
                ),
                const SizedBox(width: 12),
                GTPrimaryButton(
                  text: 'Сменить',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
            child: const Text(
              'Основной счет может быть только один. При выборе этого счета текущий основной счет перестанет быть таковым. Продолжить?',
            ),
          ),
        ),
      );
      if (confirm == true) {
        setState(() => _isPrimary = true);
      }
    } else {
      // Если пытаемся выключить единственный основной
      final existingAccounts =
          ref.read(companyBankAccountsProvider).value ?? [];
      if (existingAccounts.length > 1) {
        setState(() => _isPrimary = false);
      } else {
        AppSnackBar.show(
          context: context,
          message: 'Должен быть хотя бы один основной счет',
          kind: AppSnackBarKind.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final title =
        widget.account == null ? 'Добавление счета' : 'Редактирование счета';

    final content = Form(
      key: _formKey,
      child: Column(
        children: [
          GTTextField(
            controller: _bankNameController,
            labelText: 'Наименование банка',
            prefixIcon: CupertinoIcons.house,
            enabled: !_isLoading,
            validator: (v) =>
                v == null || v.isEmpty ? 'Введите название банка' : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _bankCityController,
            labelText: 'Город банка',
            prefixIcon: CupertinoIcons.location,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _accountNumberController,
            labelText: 'Расчетный счет',
            prefixIcon: CupertinoIcons.number,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            validator: (v) =>
                v == null || v.isEmpty ? 'Введите расчетный счет' : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _corrAccountController,
            labelText: 'Корреспондентский счет',
            prefixIcon: CupertinoIcons.number,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _bikController,
            labelText: 'БИК',
            prefixIcon: CupertinoIcons.number,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isOnlyAccount ? null : () => _togglePrimary(null),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Opacity(
              opacity: _isOnlyAccount ? 0.6 : 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Основной счет',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Switch.adaptive(
                    value: _isPrimary,
                    onChanged: _isOnlyAccount ? null : _togglePrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: 'Отмена',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            GTPrimaryButton(
              text: 'Сохранить',
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
        child: content,
      );
    } else {
      return MobileBottomSheetContent(
        title: title,
        footer: GTPrimaryButton(
          text: 'Сохранить',
          isLoading: _isLoading,
          onPressed: _save,
        ),
        child: content,
      );
    }
  }
}

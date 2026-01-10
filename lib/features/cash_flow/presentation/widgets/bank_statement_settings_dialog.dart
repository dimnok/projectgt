import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_import_template.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';

/// Диалоговое окно настроек импорта банковских выписок.
///
/// Позволяет настроить сопоставление колонок Excel-файла банка
/// с полями системы для корректного парсинга.
class BankStatementSettingsDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог настроек.
  const BankStatementSettingsDialog({super.key});

  @override
  ConsumerState<BankStatementSettingsDialog> createState() =>
      _BankStatementSettingsDialogState();
}

class _BankStatementSettingsDialogState
    extends ConsumerState<BankStatementSettingsDialog> {
  String? _selectedTemplateId;
  final _bankNameController = TextEditingController();
  final _startRowController = TextEditingController(text: '1');
  final _dateFormatController = TextEditingController(text: 'dd.MM.yyyy');

  // Контроллеры для маппинга колонок
  final _dateColController = TextEditingController();
  final _amountColController = TextEditingController();
  final _debitColController = TextEditingController();
  final _creditColController = TextEditingController();
  final _typeColController = TextEditingController();
  final _innColController = TextEditingController();
  final _nameColController = TextEditingController();
  final _commentColController = TextEditingController();
  final _numColController = TextEditingController();

  @override
  void dispose() {
    _bankNameController.dispose();
    _startRowController.dispose();
    _dateFormatController.dispose();
    _dateColController.dispose();
    _amountColController.dispose();
    _debitColController.dispose();
    _creditColController.dispose();
    _typeColController.dispose();
    _innColController.dispose();
    _nameColController.dispose();
    _commentColController.dispose();
    _numColController.dispose();
    super.dispose();
  }

  void _loadTemplate(BankImportTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _bankNameController.text = template.bankName;
      _startRowController.text = template.startRow.toString();
      _dateFormatController.text = template.dateFormat;

      final mapping = template.columnMapping;
      _dateColController.text = mapping['date'] ?? '';
      _amountColController.text = mapping['amount'] ?? '';
      _debitColController.text = mapping['amount_debit'] ?? '';
      _creditColController.text = mapping['amount_credit'] ?? '';
      _typeColController.text = mapping['type'] ?? '';
      _innColController.text = mapping['contractor_inn'] ?? '';
      _nameColController.text = mapping['contractor_name'] ?? '';
      _commentColController.text = mapping['comment'] ?? '';
      _numColController.text = mapping['transaction_number'] ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _selectedTemplateId = null;
      _bankNameController.clear();
      _startRowController.text = '1';
      _dateFormatController.text = 'dd.MM.yyyy';
      _dateColController.clear();
      _amountColController.clear();
      _debitColController.clear();
      _creditColController.clear();
      _typeColController.clear();
      _innColController.clear();
      _nameColController.clear();
      _commentColController.clear();
      _numColController.clear();
    });
  }

  Future<void> _saveTemplate() async {
    if (_bankNameController.text.isEmpty) {
      AppSnackBar.show(
        context: context,
        message: 'Укажите название банка',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    if (_dateColController.text.isEmpty ||
        (_amountColController.text.isEmpty &&
            (_debitColController.text.isEmpty ||
                _creditColController.text.isEmpty))) {
      AppSnackBar.show(
        context: context,
        message: 'Заполните дату и колонку суммы (или Дебет/Кредит)',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final template = BankImportTemplate(
      id: _selectedTemplateId ?? '',
      companyId: '', // Будет установлено в репозитории
      bankName: _bankNameController.text,
      columnMapping: {
        'date': _dateColController.text,
        'amount': _amountColController.text,
        'amount_debit': _debitColController.text,
        'amount_credit': _creditColController.text,
        'type': _typeColController.text,
        'contractor_inn': _innColController.text,
        'contractor_name': _nameColController.text,
        'comment': _commentColController.text,
        'transaction_number': _numColController.text,
      },
      startRow: int.tryParse(_startRowController.text) ?? 1,
      dateFormat: _dateFormatController.text,
    );

    try {
      await ref
          .read(cashFlowProvider.notifier)
          .saveBankImportTemplate(template);
      if (mounted) {
        final isNew = _selectedTemplateId == null;
        AppSnackBar.show(
          context: context,
          message: isNew
              ? 'Настройки шаблона выписок для банка «${template.bankName}» сохранены'
              : 'Настройки шаблона изменены',
          kind: AppSnackBarKind.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при сохранении: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  Future<void> _deleteTemplate() async {
    if (_selectedTemplateId == null) return;

    final name = _bankNameController.text;

    try {
      await ref
          .read(cashFlowProvider.notifier)
          .deleteBankImportTemplate(_selectedTemplateId!);
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Шаблон «$name» удалён',
          kind: AppSnackBarKind.success,
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при удалении: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cashFlowProvider);
    final templates = state.bankImportTemplates;

    return DesktopDialogContent(
      title: 'Настройки импорта выписок',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_selectedTemplateId != null)
            GTSecondaryButton(
              text: 'Удалить шаблон',
              onPressed: _deleteTemplate,
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              GTSecondaryButton(
                text: 'Отмена',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              GTPrimaryButton(
                text: 'Сохранить шаблон',
                onPressed: _saveTemplate,
              ),
            ],
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (templates.isNotEmpty) ...[
              const Text(
                'Выберите существующий шаблон или создайте новый',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GTDropdown<BankImportTemplate>(
                      items: templates,
                      labelText: 'Шаблон банка',
                      hintText: 'Выберите шаблон для редактирования',
                      selectedItem: _selectedTemplateId != null
                          ? templates.firstWhere(
                              (t) => t.id == _selectedTemplateId,
                              orElse: () => templates.first,
                            )
                          : null,
                      itemDisplayBuilder: (t) => t.bankName,
                      onSelectionChanged: (t) {
                        if (t != null) _loadTemplate(t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GTSecondaryButton(text: 'Новый', onPressed: _clearForm),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
            ],
            const Text(
              'Общие настройки шаблона',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GTTextField(
                    controller: _bankNameController,
                    labelText: 'Название банка',
                    hintText: 'Например: Тинькофф',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GTTextField(
                    controller: _startRowController,
                    labelText: 'Строка начала данных',
                    hintText: '1',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GTTextField(
                    controller: _dateFormatController,
                    labelText: 'Формат даты',
                    hintText: 'dd.MM.yyyy',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Сопоставление колонок',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Укажите точные названия колонок из вашего Excel-файла напротив соответствующих полей системы',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildMappingRow(
              'Дата операции',
              _dateColController,
              isRequired: true,
            ),
            _buildMappingRow('Сумма (Общая)', _amountColController),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'ИЛИ',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            _buildMappingRow('Дебет (Расход)', _debitColController),
            _buildMappingRow('Кредит (Приход)', _creditColController),
            const SizedBox(height: 16),
            _buildMappingRow('Тип (приход/расход)', _typeColController),
            _buildMappingRow('ИНН контрагента', _innColController),
            _buildMappingRow('Название контрагента', _nameColController),
            _buildMappingRow('Примечание/Назначение', _commentColController),
            _buildMappingRow('Номер операции', _numColController),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingRow(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isRequired ? FontWeight.w600 : null,
                  ),
                ),
                if (isRequired)
                  const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const Icon(CupertinoIcons.arrow_right, size: 16, color: Colors.grey),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: GTTextField(
              controller: controller,
              hintText: 'Название колонки в Excel',
            ),
          ),
        ],
      ),
    );
  }
}

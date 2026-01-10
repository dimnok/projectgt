import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/contractors/presentation/screens/contractor_form_screen.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Диалоговое окно создания/редактирования финансовой операции.
class CashFlowFormDialog extends ConsumerStatefulWidget {
  /// Существующая транзакция для редактирования (null для новой).
  final CashFlowTransaction? transaction;

  /// Запись из банковской выписки для предзаполнения (для импорта).
  final BankStatementEntry? initialEntry;

  /// Создаёт диалог формы Cash Flow.
  const CashFlowFormDialog({super.key, this.transaction, this.initialEntry});

  @override
  ConsumerState<CashFlowFormDialog> createState() => _CashFlowFormDialogState();
}

class _CashFlowFormDialogState extends ConsumerState<CashFlowFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late CashFlowType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _commentController;

  String? _selectedCategoryId;
  String? _selectedObjectId;
  String? _selectedContractId;
  String? _selectedContractorId;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    final entry = widget.initialEntry;

    _selectedDate = t?.date ?? entry?.date ?? DateTime.now();
    _selectedType = t?.type ?? entry?.type ?? CashFlowType.expense;

    // Инициализируем сумму с правильным форматированием (пробелы и запятая)
    String initialAmount = '';
    if (t != null || entry != null) {
      final amount = t?.amount ?? entry?.amount ?? 0;
      // Используем formatAmount для принудительных двух знаков после запятой
      initialAmount = GtFormatters.formatAmount(amount)
          .replaceAll('\u00A0', ' ') // Заменяем неразрывные пробелы на обычные
          .replaceAll('\u202F', ' ');
    }

    _amountController = TextEditingController(text: initialAmount);
    _dateController = TextEditingController(text: formatRuDate(_selectedDate));
    _commentController = TextEditingController(
      text: t?.comment ?? entry?.comment ?? '',
    );

    _selectedCategoryId = t?.categoryId;
    _selectedObjectId = t?.objectId;
    _selectedContractId = t?.contractId;
    _selectedContractorId = t?.contractorId;

    // Автоматическое сопоставление контрагента по ИНН при импорте из выписки
    if (entry != null &&
        _selectedContractorId == null &&
        entry.contractorInn != null) {
      // Используем postFrameCallback, так как нам нужны данные из провайдеров,
      // которые могут быть еще не готовы в initState (хотя обычно они кешированы)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final contractors = ref.read(contractorNotifierProvider).contractors;
        final matched = contractors.firstWhereOrNull(
          (c) => c.inn == entry.contractorInn,
        );
        if (matched != null) {
          setState(() {
            _selectedContractorId = matched.id;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = formatRuDate(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text;

    final activeCompanyId = ref.read(activeCompanyIdProvider);
    if (activeCompanyId == null) return;

    final transaction = CashFlowTransaction(
      id: widget.transaction?.id ?? '',
      companyId: activeCompanyId,
      date: _selectedDate,
      type: _selectedType,
      amount: parseAmount(amountText) ?? 0,
      categoryId: _selectedCategoryId,
      objectId: _selectedObjectId,
      contractId: _selectedContractId,
      contractorId: _selectedContractorId,
      contractorName: _selectedContractorId == null
          ? widget.initialEntry?.contractorName
          : null,
      contractorInn: _selectedContractorId == null
          ? widget.initialEntry?.contractorInn
          : null,
      comment: _commentController.text.isEmpty ? null : _commentController.text,
      operationHash:
          widget.transaction?.operationHash ??
          widget.initialEntry?.operationHash,
    );

    if (widget.initialEntry != null) {
      await ref
          .read(cashFlowProvider.notifier)
          .processBankStatementEntry(
            entryId: widget.initialEntry!.id,
            transaction: transaction,
          );
    } else {
      await ref.read(cashFlowProvider.notifier).saveTransaction(transaction);
    }

    if (mounted) {
      final state = ref.read(cashFlowProvider);
      if (state.status == CashFlowStatus.error) {
        AppSnackBar.show(
          context: context,
          message: state.errorMessage ?? 'Ошибка при сохранении',
          kind: AppSnackBarKind.error,
        );
      } else {
        AppSnackBar.show(
          context: context,
          message: widget.transaction == null
              ? 'Операция добавлена'
              : 'Операция обновлена',
          kind: AppSnackBarKind.success,
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final cashFlowState = ref.watch(cashFlowProvider);
    final objects = ref.watch(objectProvider).objects;
    final contractors = ref.watch(contractorNotifierProvider).contractors;
    final contracts = ref.watch(contractProvider).contracts;

    // Фильтруем договоры по выбранному объекту
    final filteredContracts = _selectedObjectId == null
        ? contracts
        : contracts.where((c) => c.objectId == _selectedObjectId).toList();

    final title = widget.transaction == null
        ? 'Новая операция'
        : 'Редактировать операцию';

    // Фильтруем категории по типу операции
    final filteredCategories = cashFlowState.categories
        .where((c) => c.type.name == _selectedType.name)
        .toList();

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Тип операции (Income/Expense)
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<CashFlowType>(
              groupValue: _selectedType,
              children: const {
                CashFlowType.expense: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.minus_circle,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Расход',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CashFlowType.income: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.plus_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Приход',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              },
              onValueChanged: (type) {
                if (type != null) {
                  setState(() {
                    _selectedType = type;
                    // Сбрасываем категорию при смене типа, если она не подходит
                    _selectedCategoryId = null;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              // Дата
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: GTTextField(
                      controller: _dateController,
                      labelText: 'Дата платежа',
                      prefixIcon: CupertinoIcons.calendar,
                      readOnly: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Сумма
              Expanded(
                child: GTTextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    amountFormatter(),
                  ],
                  labelText: 'Сумма',
                  prefixIcon: CupertinoIcons.money_rubl_circle,
                  validator: (v) => v?.isEmpty == true ? 'Введите сумму' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Категория
          GTDropdown<CashFlowCategory>(
            items: filteredCategories,
            itemDisplayBuilder: (c) => c.name,
            selectedItem: filteredCategories.firstWhereOrNull(
              (c) => c.id == _selectedCategoryId,
            ),
            onSelectionChanged: (v) =>
                setState(() => _selectedCategoryId = v?.id),
            labelText: 'Статья ДДС',
            hintText: 'Выберите статью',
          ),
          const SizedBox(height: 16),

          // Объект
          GTDropdown<ObjectEntity>(
            items: objects,
            itemDisplayBuilder: (o) => o.name,
            selectedItem: objects.firstWhereOrNull(
              (o) => o.id == _selectedObjectId,
            ),
            onSelectionChanged: (v) => setState(() {
              _selectedObjectId = v?.id;
              // Сбрасываем договор если он не принадлежит новому объекту
              if (_selectedContractId != null) {
                final contract = contracts.firstWhereOrNull(
                  (c) => c.id == _selectedContractId,
                );
                if (contract?.objectId != v?.id) _selectedContractId = null;
              }
            }),
            labelText: 'Объект',
            hintText: 'Не выбрано',
            allowClear: true,
          ),
          const SizedBox(height: 16),

          // Контрагент
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: GTDropdown<Contractor>(
                  items: contractors,
                  itemDisplayBuilder: (c) => c.shortName,
                  selectedItem: contractors.firstWhereOrNull(
                    (c) => c.id == _selectedContractorId,
                  ),
                  onSelectionChanged: (v) =>
                      setState(() => _selectedContractorId = v?.id),
                  labelText: 'Контрагент',
                  hintText: 'Не выбрано',
                  allowClear: true,
                ),
              ),
              if (widget.initialEntry != null &&
                  _selectedContractorId == null &&
                  widget.initialEntry?.contractorName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: PermissionGuard(
                    module: 'contractors',
                    permission: 'create',
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.person_add),
                      tooltip: 'Создать контрагента из выписки',
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: ContractorFormScreen(
                              initialName: widget.initialEntry!.contractorName,
                              initialInn: widget.initialEntry!.contractorInn,
                            ),
                          ),
                        );
                        // После закрытия формы создания контрагента,
                        // провайдер обновится и сработает автоподстановка (если ИНН совпал)
                      },
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Договор
          GTDropdown<Contract>(
            items: filteredContracts,
            itemDisplayBuilder: (c) =>
                '№${c.number} от ${formatRuDate(c.date)}',
            selectedItem: filteredContracts.firstWhereOrNull(
              (c) => c.id == _selectedContractId,
            ),
            onSelectionChanged: (v) =>
                setState(() => _selectedContractId = v?.id),
            labelText: 'Договор',
            hintText: 'Не выбрано',
            allowClear: true,
          ),
          const SizedBox(height: 16),

          // Комментарий
          GTTextField(
            controller: _commentController,
            labelText: 'Комментарий / Назначение платежа',
            prefixIcon: CupertinoIcons.chat_bubble_text,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GTSecondaryButton(
          text: 'Отмена',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        GTPrimaryButton(text: 'Сохранить', onPressed: _handleSave),
      ],
    );

    if (isDesktop) {
      return DesktopDialogContent(title: title, footer: footer, child: content);
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: content,
    );
  }
}

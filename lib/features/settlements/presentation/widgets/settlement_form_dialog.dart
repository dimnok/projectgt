import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/adaptive_dialog.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_actions.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_invoice_generate_flow.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';

/// Диалог создания / редактирования счёта на оплату.
///
/// Операция = счёт. Учёт оплат — в [SettlementDetailsDialog].
class SettlementFormDialog extends ConsumerStatefulWidget {
  /// Существующая операция (null — создание).
  final SettlementOperation? operation;

  /// Предзаполнить договор (вкладка «Финансы»).
  final Contract? presetContract;

  /// Создаёт диалог.
  const SettlementFormDialog({super.key, this.operation, this.presetContract});

  /// Показать диалог / bottom sheet.
  static Future<void> show(
    BuildContext context, {
    SettlementOperation? operation,
    Contract? presetContract,
  }) => showAdaptiveModal<void>(
    context,
    builder: (_) => SettlementFormDialog(
      operation: operation,
      presetContract: presetContract,
    ),
  );

  @override
  ConsumerState<SettlementFormDialog> createState() =>
      _SettlementFormDialogState();
}

class _SettlementFormDialogState extends ConsumerState<SettlementFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _objectId;
  String? _contractorId;
  String? _contractId;
  late SettlementOperationType _type;
  late DateTime _invoiceDate;
  double? _vatRate;
  bool _isVatIncluded = true;
  bool _isVatEnabled = true;

  late final TextEditingController _actNumberController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _amountController;
  late final TextEditingController _invoiceDateController;
  late final TextEditingController _noteController;
  late final TextEditingController _vatRateController;

  bool _saving = false;
  bool get _lockedContext => widget.presetContract != null;
  bool get _isAct => _type == SettlementOperationType.act;

  @override
  void initState() {
    super.initState();
    final op = widget.operation;
    final preset = widget.presetContract;

    _objectId = op?.objectId ?? preset?.objectId;
    _contractorId = op?.contractorId ?? preset?.contractorId;
    _contractId = op?.contractId ?? preset?.id;
    _type = op?.operationType ?? SettlementOperationType.act;
    _invoiceDate = op?.invoiceDate ?? DateTime.now();
    _vatRate =
        op?.vatRate ??
        (preset != null && preset.vatRate > 0 ? preset.vatRate : 22);
    _isVatIncluded = op?.isVatIncluded ?? preset?.isVatIncluded ?? true;
    _isVatEnabled = op != null
        ? (op.vatRate != null && op.vatRate! > 0)
        : (preset != null ? preset.vatRate > 0 : true);

    _actNumberController = TextEditingController(text: op?.actNumber ?? '');
    _invoiceNumberController = TextEditingController(
      text: op?.invoiceNumber ?? '',
    );

    final initialAmount = op == null
        ? null
        : (op.isVatIncluded ? (op.amount + op.vatAmount) : op.amount);
    _amountController = TextEditingController(
      text: initialAmount == null ? '' : formatAmount(initialAmount),
    );

    _invoiceDateController = TextEditingController(
      text: formatRuDate(_invoiceDate),
    );
    _noteController = TextEditingController(text: op?.note ?? '');

    final initialVatText = _vatRate != null && _vatRate! > 0
        ? (_vatRate! % 1 == 0
              ? _vatRate!.toInt().toString()
              : _vatRate!.toString())
        : '22';
    _vatRateController = TextEditingController(text: initialVatText);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(objectProvider.notifier).loadObjects();
      ref.read(contractorNotifierProvider.notifier).loadContractors();
      ref.read(contractProvider.notifier).loadContracts();
      if (op == null && _contractId != null) {
        _suggestNextInvoiceNumber(_contractId!);
      }
    });
  }

  Future<void> _suggestNextInvoiceNumber(
    String contractId, {
    bool force = false,
  }) async {
    final next = await ref
        .read(settlementRepositoryProvider)
        .getNextInvoiceNumber(contractId);
    if (!mounted) return;
    if (force || _invoiceNumberController.text.isEmpty) {
      _invoiceNumberController.text = next;
    }
  }

  @override
  void dispose() {
    _actNumberController.dispose();
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _invoiceDateController.dispose();
    _noteController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await pickRuDate(context, initialDate: _invoiceDate);
    if (picked == null || !mounted) return;
    setState(() {
      _invoiceDate = picked;
      _invoiceDateController.text = formatRuDate(picked);
    });
  }

  double get _enteredAmount => parseAmount(_amountController.text) ?? 0;
  double get _vatRateEffective => _isVatEnabled ? (_vatRate ?? 0) : 0;
  bool get _hasVat => _isVatEnabled && _vatRateEffective > 0;

  /// База (без НДС) в зависимости от режима ввода.
  double get _baseAmount {
    if (!_hasVat) return _enteredAmount;
    if (_isVatIncluded) {
      return _enteredAmount / (1 + _vatRateEffective / 100);
    }
    return _enteredAmount;
  }

  /// Сумма НДС.
  double get _vatAmount => _baseAmount * _vatRateEffective / 100;

  /// Итого с НДС.
  double get _totalWithVat => _baseAmount + _vatAmount;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null) {
      AppSnackBar.show(
        context: context,
        message: 'Не выбрана активная компания',
        kind: AppSnackBarKind.error,
      );
      return;
    }
    if (_objectId == null || _contractorId == null || _contractId == null) {
      AppSnackBar.show(
        context: context,
        message: 'Заполните объект, контрагента и договор',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _saving = true);

    final vatRateToSave = _isVatEnabled ? _vatRateEffective : null;
    final vatAmountToSave = _isVatEnabled ? _vatAmount : 0.0;
    final existing = widget.operation;

    final operation = SettlementOperation(
      id: existing?.id ?? '',
      companyId: companyId,
      operationType: _type,
      objectId: _objectId!,
      contractorId: _contractorId!,
      contractId: _contractId!,
      periodFrom: _isAct ? existing?.periodFrom : null,
      periodTo: _isAct ? existing?.periodTo : null,
      actNumber: _isAct ? _actNumberController.text.trim() : null,
      actDate: _isAct ? existing?.actDate : null,
      invoiceNumber: _invoiceNumberController.text.trim(),
      invoiceDate: _invoiceDate,
      amount: _baseAmount,
      isVatIncluded: _isVatIncluded,
      vatRate: vatRateToSave,
      vatAmount: vatAmountToSave,
      advanceRetention: existing?.advanceRetention ?? 0,
      warrantyRetention: existing?.warrantyRetention ?? 0,
      paidAmount: existing?.paidAmount ?? 0,
      purpose: existing?.purpose,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: existing?.createdAt,
      createdBy: existing?.createdBy,
    );

    final notifier = widget.presetContract != null
        ? ref.read(
            contractSettlementsProvider(widget.presetContract!.id).notifier,
          )
        : ref.read(settlementListProvider.notifier);

    final isCreate = widget.operation == null;
    final result = isCreate
        ? await notifier.create(operation)
        : await notifier.update(operation);

    if (!mounted) return;

    if (result == null) {
      setState(() => _saving = false);
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить счёт',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    await syncSettlementProviders(ref, contractId: result.contractId);

    var message = isCreate ? 'Счёт создан' : 'Счёт обновлён';
    var kind = AppSnackBarKind.success;

    final pdfMessage = await generateAndPersistSettlementInvoicePdfOnSave(
      ref: ref,
      operation: result,
      isCreate: isCreate,
    );
    if (pdfMessage != null) {
      message = pdfMessage;
      if (pdfMessage.contains('не хватает') ||
          pdfMessage.contains('Не удалось')) {
        kind = AppSnackBarKind.warning;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    AppSnackBar.show(context: context, message: message, kind: kind);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final theme = Theme.of(context);
    final objects = ref.watch(objectProvider).objects;
    final contractors = ref.watch(contractorNotifierProvider).contractors;
    final contracts = ref.watch(contractProvider).contracts;

    final filteredByObject = _objectId == null
        ? contracts
        : contracts.where((c) => c.objectId == _objectId).toList();
    final filteredContracts = _contractorId == null
        ? filteredByObject
        : filteredByObject
              .where((c) => c.contractorId == _contractorId)
              .toList();

    final selectedObject = objects.firstWhereOrNull((o) => o.id == _objectId);
    final selectedContractor = contractors.firstWhereOrNull(
      (c) => c.id == _contractorId,
    );
    final selectedContract =
        filteredContracts.firstWhereOrNull((c) => c.id == _contractId) ??
        contracts.firstWhereOrNull((c) => c.id == _contractId);

    final title = widget.operation == null
        ? 'Новый счёт'
        : 'Редактировать счёт';

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Объект + 2. Контрагент + 3. Договор (в один ряд)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GTDropdown<ObjectEntity>(
                  items: objects,
                  selectedItem: selectedObject,
                  labelText: 'Объект',
                  hintText: 'Выберите объект',
                  itemDisplayBuilder: (o) => o.name,
                  readOnly: _lockedContext,
                  allowClear: !_lockedContext,
                  onSelectionChanged: (item) {
                    setState(() {
                      _objectId = item?.id;
                      if (item != null &&
                          _contractId != null &&
                          selectedContract?.objectId != item.id) {
                        _contractId = null;
                      }
                    });
                  },
                  validator: (_) =>
                      _objectId == null ? 'Выберите объект' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GTDropdown<Contractor>(
                  items: contractors,
                  selectedItem: selectedContractor,
                  labelText: 'Контрагент',
                  hintText: 'Выберите контрагента',
                  itemDisplayBuilder: (c) => c.shortName,
                  readOnly: _lockedContext,
                  allowClear: !_lockedContext,
                  onSelectionChanged: (item) {
                    setState(() {
                      _contractorId = item?.id;
                      if (item != null &&
                          _contractId != null &&
                          selectedContract?.contractorId != item.id) {
                        _contractId = null;
                      }
                    });
                  },
                  validator: (_) =>
                      _contractorId == null ? 'Выберите контрагента' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GTDropdown<Contract>(
                  items: filteredContracts,
                  selectedItem: selectedContract,
                  labelText: 'Договор',
                  hintText: 'Выберите договор',
                  itemDisplayBuilder: (c) => c.number,
                  readOnly: _lockedContext,
                  allowClear: !_lockedContext,
                  onSelectionChanged: (item) {
                    setState(() {
                      _contractId = item?.id;
                      if (item != null) {
                        _objectId = item.objectId;
                        _contractorId = item.contractorId;
                        if (widget.operation == null) {
                          if (item.vatRate > 0) {
                            _isVatEnabled = true;
                            _vatRate = item.vatRate;
                            _isVatIncluded = item.isVatIncluded;
                            _vatRateController.text = item.vatRate % 1 == 0
                                ? item.vatRate.toInt().toString()
                                : item.vatRate.toString();
                          } else {
                            _isVatEnabled = false;
                            _vatRate = null;
                          }
                        }
                      }
                    });
                    if (widget.operation == null && item != null) {
                      _suggestNextInvoiceNumber(item.id, force: true);
                    }
                  },
                  validator: (_) =>
                      _contractId == null ? 'Выберите договор' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Разделитель перед параметрами счёта
          _SectionDivider(theme: theme),

          // 4. Тип операции
          _TypeSegment(
            value: _type,
            onChanged: (value) {
              setState(() {
                _type = value;
                if (value != SettlementOperationType.act) {
                  _actNumberController.clear();
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // 5. Номер акта (только для «По акту»)
          if (_isAct) ...[
            GTTextField(
              controller: _actNumberController,
              labelText: 'Номер акта',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Укажите номер акта' : null,
            ),
            const SizedBox(height: 12),
          ],

          // 6. Номер счёта + 7. Дата счёта (в ряд)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GTTextField(
                  controller: _invoiceNumberController,
                  labelText: 'Номер счёта',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Укажите номер счёта'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GTTextField(
                  controller: _invoiceDateController,
                  labelText: 'Дата счёта',
                  prefixIcon: CupertinoIcons.calendar,
                  readOnly: true,
                  onTap: _pickInvoiceDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 8. Сумма + Ставка НДС (в ряд)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: GTTextField(
                  controller: _amountController,
                  labelText: _hasVat
                      ? (_isVatIncluded ? 'Сумма с НДС' : 'Сумма без НДС')
                      : 'Сумма',
                  prefixIcon: CupertinoIcons.money_rubl_circle,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: moneyInputFormatters(),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = parseAmount(v);
                    if (n == null || n <= 0) return 'Укажите сумму';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _VatEnableRoundButton(
                        isEnabled: _isVatEnabled,
                        onToggle: () {
                          setState(() {
                            _isVatEnabled = !_isVatEnabled;
                            if (_isVatEnabled) {
                              final rate = parseAmount(_vatRateController.text);
                              if (rate == null || rate <= 0) {
                                _vatRateController.text = '22';
                                _vatRate = 22;
                              } else {
                                _vatRate = rate;
                              }
                            } else {
                              _vatRate = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GTTextField(
                        controller: _vatRateController,
                        labelText: 'Ставка НДС',
                        suffixText: '%',
                        hintText: '22',
                        enabled: _isVatEnabled,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (val) {
                          final rate = parseAmount(val);
                          setState(() {
                            _vatRate = rate;
                          });
                        },
                        validator: (val) {
                          if (!_isVatEnabled) return null;
                          final rate = parseAmount(val);
                          if (rate == null || rate < 0 || rate > 100) {
                            return 'Укажите %';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 9. Переключатель режима НДС + сводка (только при ненулевой ставке)
          if (_hasVat) ...[
            const SizedBox(height: 12),
            _VatModeToggle(
              isVatIncluded: _isVatIncluded,
              onChanged: (v) => setState(() => _isVatIncluded = v),
            ),
            const SizedBox(height: 12),
            _VatSummary(
              baseAmount: _baseAmount,
              vatAmount: _vatAmount,
              totalWithVat: _totalWithVat,
            ),
          ],
          const SizedBox(height: 12),

          // Примечание
          GTTextField(
            controller: _noteController,
            labelText: 'Примечание',
            maxLines: 4,
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
        width: 920,
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

class _TypeSegment extends StatelessWidget {
  final SettlementOperationType value;
  final ValueChanged<SettlementOperationType> onChanged;

  const _TypeSegment({required this.value, required this.onChanged});

  Color _color(ThemeData theme, SettlementOperationType type) {
    final scheme = theme.colorScheme;
    switch (type) {
      case SettlementOperationType.act:
        return scheme.primary;
      case SettlementOperationType.advance:
        return scheme.tertiary;
      case SettlementOperationType.other:
        return scheme.onSurface.withValues(alpha: 0.62);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final type in SettlementOperationType.values) ...[
          if (type != SettlementOperationType.values.first)
            const SizedBox(width: 8),
          Expanded(
            child: _TypeSticker(
              label: settlementOperationTypeLabel(type),
              color: _color(theme, type),
              selected: value == type,
              onTap: () => onChanged(type),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeSticker extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeSticker({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? color.withValues(alpha: 0.16)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.7)
                  : scheme.outline.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final ThemeData theme;

  const _SectionDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: scheme.outline.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактный переключатель режима НДС: «в сумме» / «сверху».
class _VatModeToggle extends StatelessWidget {
  final bool isVatIncluded;
  final ValueChanged<bool> onChanged;

  const _VatModeToggle({required this.isVatIncluded, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<bool>(
        groupValue: isVatIncluded,
        children: {
          true: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text('НДС в сумме', style: textStyle),
          ),
          false: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text('НДС сверху', style: textStyle),
          ),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

/// Сводка по НДС: база, НДС и итог с НДС. Показывается только при ненулевой ставке.
class _VatSummary extends StatelessWidget {
  final double baseAmount;
  final double vatAmount;
  final double totalWithVat;

  const _VatSummary({
    required this.baseAmount,
    required this.vatAmount,
    required this.totalWithVat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Item(
              label: 'Без НДС',
              value: formatCurrency(baseAmount),
              tone: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          _Divider(),
          Expanded(
            child: _Item(
              label: 'НДС',
              value: formatCurrency(vatAmount),
              tone: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          _Divider(),
          Expanded(
            child: _Item(
              label: 'Итого с НДС',
              value: formatCurrency(totalWithVat),
              tone: scheme.primary,
              emphasize: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 1,
        height: 32,
        color: scheme.outline.withValues(alpha: 0.18),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;
  final bool emphasize;

  const _Item({
    required this.label,
    required this.value,
    required this.tone,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            color: tone,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Круглая кнопка переключения активности НДС.
class _VatEnableRoundButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;

  const _VatEnableRoundButton({
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Tooltip(
      message: isEnabled ? 'НДС включён' : 'Без НДС (нажмите, чтобы включить)',
      child: Material(
        color: isEnabled
            ? scheme.primary
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isEnabled
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'НДС',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isEnabled
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

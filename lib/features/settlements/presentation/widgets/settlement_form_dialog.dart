import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
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
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';

/// Диалог создания / редактирования операции взаиморасчётов.
class SettlementFormDialog extends ConsumerStatefulWidget {
  /// Существующая операция (null — создание).
  final SettlementOperation? operation;

  /// Предзаполнить договор (вкладка «Финансы»).
  final Contract? presetContract;

  /// Создаёт диалог.
  const SettlementFormDialog({
    super.key,
    this.operation,
    this.presetContract,
  });

  /// Показать диалог / bottom sheet.
  static Future<void> show(
    BuildContext context, {
    SettlementOperation? operation,
    Contract? presetContract,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: SettlementFormDialog(
            operation: operation,
            presetContract: presetContract,
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettlementFormDialog(
        operation: operation,
        presetContract: presetContract,
      ),
    );
  }

  @override
  ConsumerState<SettlementFormDialog> createState() =>
      _SettlementFormDialogState();
}

class _SettlementFormDialogState extends ConsumerState<SettlementFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late SettlementOperationType _type;
  String? _objectId;
  String? _contractorId;
  String? _contractId;

  DateTime? _periodFrom;
  DateTime? _periodTo;
  DateTime? _actDate;
  late DateTime _invoiceDate;

  late final TextEditingController _actNumberController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _amountController;
  late final TextEditingController _vatController;
  late final TextEditingController _advanceRetentionController;
  late final TextEditingController _warrantyRetentionController;
  late final TextEditingController _paidController;
  late final TextEditingController _purposeController;
  late final TextEditingController _noteController;
  late final TextEditingController _periodFromController;
  late final TextEditingController _periodToController;
  late final TextEditingController _actDateController;
  late final TextEditingController _invoiceDateController;

  bool _saving = false;
  bool get _lockedContext => widget.presetContract != null;
  bool get _isAct => _type == SettlementOperationType.act;
  bool get _isAdvance => _type == SettlementOperationType.advance;
  bool get _isOther => _type == SettlementOperationType.other;

  @override
  void initState() {
    super.initState();
    final op = widget.operation;
    final preset = widget.presetContract;

    _type = op?.operationType ?? SettlementOperationType.act;
    _objectId = op?.objectId ?? preset?.objectId;
    _contractorId = op?.contractorId ?? preset?.contractorId;
    _contractId = op?.contractId ?? preset?.id;

    _periodFrom = op?.periodFrom;
    _periodTo = op?.periodTo;
    _actDate = op?.actDate;
    _invoiceDate = op?.invoiceDate ?? DateTime.now();

    _actNumberController = TextEditingController(text: op?.actNumber ?? '');
    _invoiceNumberController =
        TextEditingController(text: op?.invoiceNumber ?? '');
    _amountController = TextEditingController(
      text: op == null ? '' : _fmtAmount(op.amount),
    );
    _vatController = TextEditingController(
      text: op == null ? '' : _fmtAmount(op.vatAmount),
    );
    _advanceRetentionController = TextEditingController(
      text: op == null || op.advanceRetention == 0
          ? ''
          : _fmtAmount(op.advanceRetention),
    );
    _warrantyRetentionController = TextEditingController(
      text: op == null || op.warrantyRetention == 0
          ? ''
          : _fmtAmount(op.warrantyRetention),
    );
    _paidController = TextEditingController(
      text: op == null ? '0,00' : _fmtAmount(op.paidAmount),
    );
    _purposeController = TextEditingController(text: op?.purpose ?? '');
    _noteController = TextEditingController(text: op?.note ?? '');
    _periodFromController = TextEditingController(
      text: _periodFrom == null ? '' : formatRuDate(_periodFrom!),
    );
    _periodToController = TextEditingController(
      text: _periodTo == null ? '' : formatRuDate(_periodTo!),
    );
    _actDateController = TextEditingController(
      text: _actDate == null ? '' : formatRuDate(_actDate!),
    );
    _invoiceDateController =
        TextEditingController(text: formatRuDate(_invoiceDate));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(objectProvider.notifier).loadObjects();
      ref.read(contractorNotifierProvider.notifier).loadContractors();
      ref.read(contractProvider.notifier).loadContracts();
      if (op == null && preset != null) {
        _suggestVatFromContract(preset);
      }
    });
  }

  String _fmtAmount(num value) => GtFormatters.formatAmount(value)
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u202F', ' ');

  void _suggestVatFromContract(Contract contract) {
    final amount = parseAmount(_amountController.text) ?? 0;
    if (amount <= 0 || contract.vatRate <= 0) return;
    final vat = amount * contract.vatRate / 100;
    setState(() => _vatController.text = _fmtAmount(vat));
  }

  @override
  void dispose() {
    _actNumberController.dispose();
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _vatController.dispose();
    _advanceRetentionController.dispose();
    _warrantyRetentionController.dispose();
    _paidController.dispose();
    _purposeController.dispose();
    _noteController.dispose();
    _periodFromController.dispose();
    _periodToController.dispose();
    _actDateController.dispose();
    _invoiceDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
    required TextEditingController controller,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      onPicked(picked);
      controller.text = formatRuDate(picked);
    });
  }

  double get _amount => parseAmount(_amountController.text) ?? 0;
  double get _vat => parseAmount(_vatController.text) ?? 0;
  double get _advance =>
      _isAct ? (parseAmount(_advanceRetentionController.text) ?? 0) : 0;
  double get _warranty =>
      _isAct ? (parseAmount(_warrantyRetentionController.text) ?? 0) : 0;
  double get _totalToPay => computeSettlementTotalToPay(
        amount: _amount,
        vatAmount: _vat,
        advanceRetention: _advance,
        warrantyRetention: _warranty,
      );
  double get _paid => parseAmount(_paidController.text) ?? 0;
  double get _remaining => _totalToPay - _paid;
  SettlementPaymentStatus get _status => computeSettlementPaymentStatus(
        totalToPay: _totalToPay,
        paidAmount: _paid,
      );

  List<TextInputFormatter> get _moneyFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        amountFormatter(),
      ];

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

    final operation = SettlementOperation(
      id: widget.operation?.id ?? '',
      companyId: companyId,
      operationType: _type,
      objectId: _objectId!,
      contractorId: _contractorId!,
      contractId: _contractId!,
      periodFrom: _isAct ? _periodFrom : null,
      periodTo: _isAct ? _periodTo : null,
      actNumber: _isAct ? _actNumberController.text.trim() : null,
      actDate: _isAct ? _actDate : null,
      invoiceNumber: _invoiceNumberController.text.trim(),
      invoiceDate: _invoiceDate,
      amount: _amount,
      vatAmount: _vat,
      advanceRetention: _advance,
      warrantyRetention: _warranty,
      totalToPay: _totalToPay,
      paidAmount: _paid,
      paymentStatus: _status,
      purpose: _isOther
          ? _purposeController.text.trim()
          : (_purposeController.text.trim().isEmpty
              ? null
              : _purposeController.text.trim()),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final notifier = widget.presetContract != null
        ? ref.read(
            contractSettlementsProvider(widget.presetContract!.id).notifier,
          )
        : ref.read(settlementListProvider.notifier);

    final result = widget.operation == null
        ? await notifier.create(operation)
        : await notifier.update(operation);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result == null) {
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить операцию',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    if (widget.presetContract != null) {
      ref.read(settlementListProvider.notifier).load(quiet: true);
    }

    AppSnackBar.show(
      context: context,
      message: widget.operation == null
          ? 'Операция создана'
          : 'Операция обновлена',
      kind: AppSnackBarKind.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
    final selectedContractor =
        contractors.firstWhereOrNull((c) => c.id == _contractorId);
    final selectedContract =
        filteredContracts.firstWhereOrNull((c) => c.id == _contractId) ??
            contracts.firstWhereOrNull((c) => c.id == _contractId);

    final title =
        widget.operation == null ? 'Новая операция' : 'Редактировать операцию';

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TypeSegment(
            value: _type,
            onChanged: (value) {
              setState(() => _type = value);
            },
          ),
          const SizedBox(height: 20),

          const _SectionTitle(title: 'Контекст'),
          const SizedBox(height: 10),
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
                  itemDisplayBuilder: (c) => c.fullName,
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
            ],
          ),
          const SizedBox(height: 12),
          GTDropdown<Contract>(
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
                  _suggestVatFromContract(item);
                }
              });
            },
            validator: (_) => _contractId == null ? 'Выберите договор' : null,
          ),

          if (_isAct) ...[
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Акт'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GTTextField(
                    controller: _periodFromController,
                    labelText: 'Период с',
                    prefixIcon: CupertinoIcons.calendar,
                    readOnly: true,
                    onTap: () => _pickDate(
                      initial: _periodFrom,
                      onPicked: (d) => _periodFrom = d,
                      controller: _periodFromController,
                    ),
                    validator: (_) =>
                        _periodFrom == null ? 'Укажите начало периода' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GTTextField(
                    controller: _periodToController,
                    labelText: 'Период по',
                    prefixIcon: CupertinoIcons.calendar,
                    readOnly: true,
                    onTap: () => _pickDate(
                      initial: _periodTo,
                      onPicked: (d) => _periodTo = d,
                      controller: _periodToController,
                    ),
                    validator: (_) =>
                        _periodTo == null ? 'Укажите конец периода' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GTTextField(
                    controller: _actNumberController,
                    labelText: 'Номер акта',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Укажите номер акта'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GTTextField(
                    controller: _actDateController,
                    labelText: 'Дата акта',
                    prefixIcon: CupertinoIcons.calendar,
                    readOnly: true,
                    onTap: () => _pickDate(
                      initial: _actDate,
                      onPicked: (d) => _actDate = d,
                      controller: _actDateController,
                    ),
                    validator: (_) =>
                        _actDate == null ? 'Укажите дату акта' : null,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          const _SectionTitle(title: 'Счёт'),
          const SizedBox(height: 10),
          Row(
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
                  onTap: () => _pickDate(
                    initial: _invoiceDate,
                    onPicked: (d) => _invoiceDate = d,
                    controller: _invoiceDateController,
                  ),
                ),
              ),
            ],
          ),
          if (_isOther || _isAdvance) ...[
            const SizedBox(height: 12),
            GTTextField(
              controller: _purposeController,
              labelText: _isOther
                  ? 'Назначение'
                  : 'Назначение (необязательно)',
              validator: _isOther
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? 'Укажите назначение'
                      : null
                  : null,
            ),
          ],

          const SizedBox(height: 20),
          const _SectionTitle(title: 'Суммы'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GTTextField(
                  controller: _amountController,
                  labelText: _isAdvance ? 'Сумма аванса' : 'Сумма',
                  prefixIcon: CupertinoIcons.money_rubl_circle,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: _moneyFormatters,
                  onChanged: (_) {
                    setState(() {});
                    final contract = selectedContract;
                    if (contract != null &&
                        (parseAmount(_vatController.text) ?? 0) == 0) {
                      _suggestVatFromContract(contract);
                    }
                  },
                  validator: (v) {
                    final n = parseAmount(v);
                    if (n == null || n < 0) return 'Укажите сумму';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GTTextField(
                  controller: _vatController,
                  labelText: 'НДС',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: _moneyFormatters,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (_isAct) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GTTextField(
                    controller: _advanceRetentionController,
                    labelText: 'Авансовые удержания',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _moneyFormatters,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GTTextField(
                    controller: _warrantyRetentionController,
                    labelText: 'Гарантийные удержания',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _moneyFormatters,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          GTTextField(
            controller: _paidController,
            labelText: 'Оплачено',
            prefixIcon: CupertinoIcons.checkmark_circle,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _moneyFormatters,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),
          _SummaryCard(
            totalToPay: _totalToPay,
            paid: _paid,
            remaining: _remaining,
            status: _status,
            scheme: scheme,
            theme: theme,
          ),

          const SizedBox(height: 16),
          GTTextField(
            controller: _noteController,
            labelText: 'Комментарий',
            maxLines: 2,
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
        width: 720,
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  final SettlementOperationType value;
  final ValueChanged<SettlementOperationType> onChanged;

  const _TypeSegment({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<SettlementOperationType>(
        groupValue: value,
        children: {
          for (final type in SettlementOperationType.values)
            type: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                settlementOperationTypeLabel(type),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        },
        onValueChanged: (type) {
          if (type != null) onChanged(type);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalToPay;
  final double paid;
  final double remaining;
  final SettlementPaymentStatus status;
  final ColorScheme scheme;
  final ThemeData theme;

  const _SummaryCard({
    required this.totalToPay,
    required this.paid,
    required this.remaining,
    required this.status,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      SettlementPaymentStatus.unpaid => scheme.error,
      SettlementPaymentStatus.partial => scheme.tertiary,
      SettlementPaymentStatus.paid => scheme.primary,
      SettlementPaymentStatus.overpaid =>
        scheme.onSurface.withValues(alpha: 0.7),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'К оплате',
                  value: formatCurrency(totalToPay),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Оплачено',
                  value: formatCurrency(paid),
                  valueColor: scheme.primary,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Остаток',
                  value: formatCurrency(remaining),
                  valueColor: remaining > 0.005 ? scheme.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Статус',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  settlementPaymentStatusLabel(status),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

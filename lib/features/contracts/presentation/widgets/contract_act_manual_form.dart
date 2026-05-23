import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_ui_labels.dart';

/// Форма ручного ввода акта по договору (`act_kind = manual`).
class ContractActManualForm extends ConsumerStatefulWidget {
  /// Договор, к которому относится акт.
  final Contract contract;

  /// Если задан — режим редактирования существующего акта.
  final ContractAct? existingAct;

  /// Создаёт виджет диалога.
  const ContractActManualForm({
    super.key,
    required this.contract,
    this.existingAct,
  });

  @override
  ConsumerState<ContractActManualForm> createState() =>
      _ContractActManualFormState();
}

class _ContractActManualFormState extends ConsumerState<ContractActManualForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _numberController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  final _vatController = TextEditingController(text: '0');
  final _advanceController = TextEditingController(text: '0');
  final _warrantyController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _actDateDisplay = TextEditingController();
  final _periodFromDisplay = TextEditingController();
  final _periodToDisplay = TextEditingController();
  final _totalDisplay = TextEditingController();

  late DateTime _actDate;
  late DateTime _periodFrom;
  late DateTime _periodTo;
  ContractActWorkflowStatus _workflow =
      ContractActWorkflowStatus.pendingApproval;
  ContractActPaymentStatus _payment = ContractActPaymentStatus.unpaid;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAct;
    if (existing != null) {
      _applyExistingAct(existing);
    } else {
      final now = DateTime.now();
      _actDate = DateTime(now.year, now.month, now.day);
      _periodTo = _actDate;
      _periodFrom = DateTime(now.year, now.month, 1);
      _syncDateDisplays();
      _refreshTotalDisplay();
    }
  }

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  void _applyExistingAct(ContractAct act) {
    _titleController.text = act.title;
    _numberController.text = act.number;
    _actDate = _dateOnly(act.actDate);
    _periodFrom = _dateOnly(act.periodFrom);
    _periodTo = _dateOnly(act.periodTo);
    _amountController.text = act.amount.toStringAsFixed(2);
    _vatController.text = act.vatAmount.toStringAsFixed(2);
    _advanceController.text = act.advanceRetention.toStringAsFixed(2);
    _warrantyController.text = act.warrantyRetention.toStringAsFixed(2);
    _otherController.text = act.otherRetentions.toStringAsFixed(2);
    final n = act.note?.trim();
    _noteController.text = n == null || n.isEmpty ? '' : n;
    _workflow = act.workflowStatus;
    _payment = act.paymentStatus;
    _syncDateDisplays();
    _refreshTotalDisplay();
  }

  void _syncDateDisplays() {
    _actDateDisplay.text = formatRuDate(_actDate);
    _periodFromDisplay.text = formatRuDate(_periodFrom);
    _periodToDisplay.text = formatRuDate(_periodTo);
  }

  void _refreshTotalDisplay() {
    final total = computeContractActTotalToPay(
      amount: _readAmount(_amountController),
      vatAmount: _readAmount(_vatController),
      advanceRetention: _readAmount(_advanceController),
      warrantyRetention: _readAmount(_warrantyController),
      otherRetentions: _readAmount(_otherController),
    );
    _totalDisplay.text = formatCurrency(total);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _amountController.dispose();
    _vatController.dispose();
    _advanceController.dispose();
    _warrantyController.dispose();
    _otherController.dispose();
    _noteController.dispose();
    _actDateDisplay.dispose();
    _periodFromDisplay.dispose();
    _periodToDisplay.dispose();
    _totalDisplay.dispose();
    super.dispose();
  }

  double _readAmount(TextEditingController c) => parseAmount(c.text) ?? 0;

  void _onMoneyChanged() {
    setState(_refreshTotalDisplay);
  }

  Future<void> _pickDate({
    required String title,
    required DateTime initial,
    required ValueChanged<DateTime> onPick,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: title,
    );
    if (picked != null) {
      onPick(DateTime(picked.year, picked.month, picked.day));
      setState(_syncDateDisplays);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_periodTo.isBefore(_periodFrom)) {
      AppSnackBar.show(
        context: context,
        message: 'Дата окончания периода не может быть раньше даты начала',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.existingAct;
      if (existing != null) {
        final update = ref.read(updateContractActUseCaseProvider);
        await update(
          id: existing.id,
          companyId: widget.contract.companyId,
          contractId: widget.contract.id,
          title: _titleController.text.trim(),
          number: _numberController.text.trim(),
          actDate: _actDate,
          periodFrom: _periodFrom,
          periodTo: _periodTo,
          amount: _readAmount(_amountController),
          vatAmount: _readAmount(_vatController),
          advanceRetention: _readAmount(_advanceController),
          warrantyRetention: _readAmount(_warrantyController),
          otherRetentions: _readAmount(_otherController),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          workflowStatus: _workflow,
          paymentStatus: _payment,
        );
        if (!mounted) return;
        ref.invalidate(contractActsProvider(widget.contract.id));
        AppSnackBar.show(
          context: context,
          message: 'Изменения сохранены',
          kind: AppSnackBarKind.success,
        );
        Navigator.of(context).pop();
      } else {
        final create = ref.read(createContractActUseCaseProvider);
        await create(
          companyId: widget.contract.companyId,
          contractId: widget.contract.id,
          title: _titleController.text.trim(),
          number: _numberController.text.trim(),
          actDate: _actDate,
          periodFrom: _periodFrom,
          periodTo: _periodTo,
          amount: _readAmount(_amountController),
          vatAmount: _readAmount(_vatController),
          advanceRetention: _readAmount(_advanceController),
          warrantyRetention: _readAmount(_warrantyController),
          otherRetentions: _readAmount(_otherController),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          workflowStatus: _workflow,
          paymentStatus: _payment,
        );
        if (!mounted) return;
        ref.invalidate(contractActsProvider(widget.contract.id));
        AppSnackBar.show(
          context: context,
          message: 'Акт сохранён',
          kind: AppSnackBarKind.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не удалось сохранить акт: $e',
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GTTextField(
            controller: _titleController,
            labelText: 'Название акта *',
            hintText: 'Например, акт выполненных работ',
            prefixIcon: CupertinoIcons.text_alignleft,
            enabled: !_saving,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Введите название' : null,
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _numberController,
            labelText: 'Номер акта *',
            hintText: 'Номер',
            prefixIcon: CupertinoIcons.number,
            enabled: !_saving,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Введите номер' : null,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GTTextField(
                  labelText: 'Дата акта *',
                  readOnly: true,
                  enabled: !_saving,
                  prefixIcon: CupertinoIcons.calendar,
                  controller: _actDateDisplay,
                  onTap: _saving
                      ? null
                      : () => _pickDate(
                            title: 'Дата акта',
                            initial: _actDate,
                            onPick: (d) => _actDate = d,
                          ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  labelText: 'Период с *',
                  readOnly: true,
                  enabled: !_saving,
                  prefixIcon: CupertinoIcons.calendar_badge_plus,
                  controller: _periodFromDisplay,
                  onTap: _saving
                      ? null
                      : () => _pickDate(
                            title: 'Начало периода',
                            initial: _periodFrom,
                            onPick: (d) => _periodFrom = d,
                          ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  labelText: 'Период по *',
                  readOnly: true,
                  enabled: !_saving,
                  prefixIcon: CupertinoIcons.calendar_today,
                  controller: _periodToDisplay,
                  onTap: _saving
                      ? null
                      : () => _pickDate(
                            title: 'Окончание периода',
                            initial: _periodTo,
                            onPick: (d) => _periodTo = d,
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GTTextField(
                  controller: _amountController,
                  labelText: 'Сумма акта *',
                  hintText: '0,00',
                  suffixText: '₽',
                  prefixIcon: CupertinoIcons.money_rubl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [amountFormatter()],
                  enabled: !_saving,
                  onChanged: (_) => _onMoneyChanged(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Введите сумму';
                    }
                    final n = parseAmount(v);
                    if (n == null || n < 0) {
                      return 'Некорректная сумма';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  controller: _vatController,
                  labelText: 'НДС',
                  hintText: '0,00',
                  suffixText: '₽',
                  prefixIcon: CupertinoIcons.percent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [amountFormatter()],
                  enabled: !_saving,
                  onChanged: (_) => _onMoneyChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GTTextField(
                  controller: _advanceController,
                  labelText: 'Авансовое удержание',
                  hintText: '0,00',
                  suffixText: '₽',
                  prefixIcon: CupertinoIcons.arrow_down_circle,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [amountFormatter()],
                  enabled: !_saving,
                  onChanged: (_) => _onMoneyChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  controller: _warrantyController,
                  labelText: 'Гарантийное удержание',
                  hintText: '0,00',
                  suffixText: '₽',
                  prefixIcon: CupertinoIcons.shield,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [amountFormatter()],
                  enabled: !_saving,
                  onChanged: (_) => _onMoneyChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  controller: _otherController,
                  labelText: 'Прочие удержания',
                  hintText: '0,00',
                  suffixText: '₽',
                  prefixIcon: CupertinoIcons.list_bullet,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [amountFormatter()],
                  enabled: !_saving,
                  onChanged: (_) => _onMoneyChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GTTextField(
            labelText: 'Итого к оплате',
            readOnly: true,
            prefixIcon: CupertinoIcons.equal_circle_fill,
            controller: _totalDisplay,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Сумма акта + НДС − удержания',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GTEnumDropdown<ContractActWorkflowStatus>(
            values: ContractActWorkflowStatus.values,
            selectedValue: _workflow,
            allowClear: false,
            readOnly: _saving,
            labelText: 'Статус *',
            hintText: 'Выберите статус',
            enumToString: contractActWorkflowStatusLabel,
            onChanged: (v) {
              if (v != null) setState(() => _workflow = v);
            },
          ),
          const SizedBox(height: 16),
          GTEnumDropdown<ContractActPaymentStatus>(
            values: ContractActPaymentStatus.values,
            selectedValue: _payment,
            allowClear: false,
            readOnly: _saving,
            labelText: 'Статус оплаты *',
            hintText: 'Выберите статус',
            enumToString: contractActPaymentStatusLabel,
            onChanged: (v) {
              if (v != null) setState(() => _payment = v);
            },
          ),
          const SizedBox(height: 16),
          GTTextField(
            controller: _noteController,
            labelText: 'Примечание',
            hintText: 'Необязательно',
            prefixIcon: CupertinoIcons.text_bubble,
            maxLines: 4,
            enabled: !_saving,
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GTSecondaryButton(
                  text: 'Отмена',
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTPrimaryButton(
                  text: 'Сохранить',
                  isLoading: _saving,
                  onPressed: _saving ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

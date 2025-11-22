import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'contract_form_content.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/data/models/contract_model.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';

/// Экран для создания или редактирования договора.
///
/// Используется для отображения формы договора. Если передан [contract],
/// форма работает в режиме редактирования, иначе — создания.
class ContractFormScreen extends ConsumerStatefulWidget {
  /// Договор для редактирования. Если null — создаётся новый договор.
  final Contract? contract;

  /// Создаёт экран формы договора.
  const ContractFormScreen({super.key, this.contract});

  @override
  ConsumerState<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends ConsumerState<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  final _vatRateController = TextEditingController();
  final _vatAmountController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _warrantyRetentionAmountController = TextEditingController();
  final _warrantyRetentionRateController = TextEditingController();
  final _warrantyPeriodMonthsController = TextEditingController();
  final _generalContractorFeeAmountController = TextEditingController();
  final _generalContractorFeeRateController = TextEditingController();
  DateTime? _date;
  DateTime? _endDate;
  String? _selectedContractorId;
  String? _selectedObjectId;
  ContractStatus _status = ContractStatus.active;
  bool _isVatIncluded = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    if (c != null) {
      _numberController.text = c.number;
      _amountController.text = c.amount.toStringAsFixed(2);
      _vatRateController.text = c.vatRate.toStringAsFixed(2);
      _vatAmountController.text = c.vatAmount.toStringAsFixed(2);
      _advanceAmountController.text = c.advanceAmount.toStringAsFixed(2);
      _warrantyRetentionAmountController.text =
          c.warrantyRetentionAmount.toStringAsFixed(2);
      _warrantyRetentionRateController.text =
          c.warrantyRetentionRate.toStringAsFixed(2);
      _warrantyPeriodMonthsController.text = c.warrantyPeriodMonths.toString();
      _generalContractorFeeAmountController.text =
          c.generalContractorFeeAmount.toStringAsFixed(2);
      _generalContractorFeeRateController.text =
          c.generalContractorFeeRate.toStringAsFixed(2);
      _date = c.date;
      _endDate = c.endDate;
      _selectedContractorId = c.contractorId;
      _selectedObjectId = c.objectId;
      _status = c.status;
      _isVatIncluded = c.isVatIncluded;
    }

    _amountController.addListener(_calculateVat);
    _vatRateController.addListener(_calculateVat);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateVat);
    _vatRateController.removeListener(_calculateVat);
    _numberController.dispose();
    _amountController.dispose();
    _vatRateController.dispose();
    _vatAmountController.dispose();
    _advanceAmountController.dispose();
    _warrantyRetentionAmountController.dispose();
    _warrantyRetentionRateController.dispose();
    _warrantyPeriodMonthsController.dispose();
    _generalContractorFeeAmountController.dispose();
    _generalContractorFeeRateController.dispose();
    super.dispose();
  }

  void _calculateVat() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final rate =
        double.tryParse(_vatRateController.text.replaceAll(',', '.')) ?? 0.0;

    if (rate == 0) {
      _vatAmountController.text = '0.00';
      return;
    }

    double vat;
    if (_isVatIncluded) {
      // Amount is Total. VAT = Amount * Rate / (100 + Rate)
      vat = amount * rate / (100 + rate);
    } else {
      // Amount is Base. VAT = Amount * Rate / 100
      // Wait, if user enters Base Amount here, then Total Amount will be higher.
      // But Contract.amount is usually Total.
      // If "On Top": User enters Base. We calculate VAT.
      // Should we update Amount field? No, usually Amount field is the user input.
      // Let's assume Amount field = Contract Amount (Total).
      // If User says "On Top", it means the Base was X and VAT was Y.
      // But if they enter the Total, then the calculation is always "Included".

      // User requirement: "Cost 36... including VAT 5%".
      // If user switches to "On Top", they probably want to enter Base Amount.
      // Let's stick to:
      // Included: VAT = Amount * Rate / (100 + Rate)
      // On Top: VAT = Amount * Rate / 100.

      vat = amount * rate / 100;
    }

    // Update VAT text without triggering loop if formatted same
    final newVatText = vat.toStringAsFixed(2);
    if (_vatAmountController.text != newVatText) {
      _vatAmountController.text = newVatText;
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null ||
        _selectedContractorId == null ||
        _selectedObjectId == null) {
      SnackBarUtils.showError(context, 'Заполните все обязательные поля');
      return;
    }
    setState(() => _isLoading = true);
    final notifier = ref.read(contractProvider.notifier);
    final isNew = widget.contract == null;
    final contract = Contract(
      id: widget.contract?.id ?? const Uuid().v4(),
      number: _numberController.text.trim(),
      date: _date!,
      endDate: _endDate,
      contractorId: _selectedContractorId!,
      contractorName: null, // будет подтянуто при отображении
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      vatRate:
          double.tryParse(_vatRateController.text.replaceAll(',', '.')) ?? 0.0,
      isVatIncluded: _isVatIncluded,
      vatAmount:
          double.tryParse(_vatAmountController.text.replaceAll(',', '.')) ??
              0.0,
      advanceAmount:
          double.tryParse(_advanceAmountController.text.replaceAll(',', '.')) ??
              0.0,
      warrantyRetentionAmount: double.tryParse(
              _warrantyRetentionAmountController.text.replaceAll(',', '.')) ??
          0.0,
      warrantyRetentionRate: double.tryParse(
              _warrantyRetentionRateController.text.replaceAll(',', '.')) ??
          0.0,
      warrantyPeriodMonths:
          int.tryParse(_warrantyPeriodMonthsController.text) ?? 0,
      generalContractorFeeAmount: double.tryParse(
              _generalContractorFeeAmountController.text
                  .replaceAll(',', '.')) ??
          0.0,
      generalContractorFeeRate: double.tryParse(
              _generalContractorFeeRateController.text.replaceAll(',', '.')) ??
          0.0,
      objectId: _selectedObjectId!,
      objectName: null, // будет подтянуто при отображении
      status: _status,
      createdAt: widget.contract?.createdAt,
      updatedAt: DateTime.now(),
    );
    debugPrint(
        '[CONTRACTS][FORM] contract: \\${ContractModel.fromDomain(contract).toJson()}');
    try {
      if (isNew) {
        await notifier.addContract(contract);
        if (!mounted) return;
        SnackBarUtils.showSuccess(context, 'Договор успешно добавлен');
      } else {
        await notifier.updateContract(contract);
        if (!mounted) return;
        SnackBarUtils.showInfo(context, 'Договор обновлён');
      }
      setState(() => _isLoading = false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[CONTRACTS][ERROR] $e');
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка: $e');
    }
  }

  void _handleCancel() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      context.goNamed('contracts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractorState = ref.watch(contractorProvider);
    final objectState = ref.watch(objectProvider);
    final isNew = widget.contract == null;

    final contractorItems = {
      for (final c in contractorState.contractors) c.id: c.fullName
    };
    final objectItems = {for (final o in objectState.objects) o.id: o.name};

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBarWidget(
        title: isNew ? 'Новый договор' : 'Редактировать договор',
        leading: BackButton(onPressed: _handleCancel),
        showThemeSwitch: true,
      ),
      body: ContractFormContent(
        isNew: isNew,
        isLoading: _isLoading,
        numberController: _numberController,
        amountController: _amountController,
        vatRateController: _vatRateController,
        isVatIncluded: _isVatIncluded,
        vatAmountController: _vatAmountController,
        advanceAmountController: _advanceAmountController,
        warrantyRetentionAmountController: _warrantyRetentionAmountController,
        warrantyRetentionRateController: _warrantyRetentionRateController,
        warrantyPeriodMonthsController: _warrantyPeriodMonthsController,
        generalContractorFeeAmountController:
            _generalContractorFeeAmountController,
        generalContractorFeeRateController: _generalContractorFeeRateController,
        date: _date,
        endDate: _endDate,
        selectedContractorId: _selectedContractorId,
        selectedObjectId: _selectedObjectId,
        status: _status,
        formKey: _formKey,
        onSave: _handleSave,
        onCancel: _handleCancel,
        onDateChanged: (d) => setState(() => _date = d),
        onEndDateChanged: (d) => setState(() => _endDate = d),
        onContractorChanged: (id) => setState(() => _selectedContractorId = id),
        onObjectChanged: (id) => setState(() => _selectedObjectId = id),
        onStatusChanged: (s) =>
            setState(() => _status = s ?? ContractStatus.active),
        onVatIncludedChanged: (v) {
          setState(() {
            _isVatIncluded = v;
            _calculateVat();
          });
        },
        contractorItems: contractorItems,
        objectItems: objectItems,
      ),
    );
  }
}

/// Модальное окно для создания или редактирования договора.
///
/// Используется для отображения формы договора в модальном режиме (например, bottom sheet).
/// Если передан [contract], форма работает в режиме редактирования, иначе — создания.
class ContractFormModal extends ConsumerStatefulWidget {
  /// Договор для редактирования. Если null — создаётся новый договор.
  final Contract? contract;

  /// Создаёт модальное окно формы договора.
  const ContractFormModal({super.key, this.contract});

  @override
  ConsumerState<ContractFormModal> createState() => _ContractFormModalState();
}

class _ContractFormModalState extends ConsumerState<ContractFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  final _vatRateController = TextEditingController();
  final _vatAmountController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _warrantyRetentionAmountController = TextEditingController();
  final _warrantyRetentionRateController = TextEditingController();
  final _warrantyPeriodMonthsController = TextEditingController();
  final _generalContractorFeeAmountController = TextEditingController();
  final _generalContractorFeeRateController = TextEditingController();
  DateTime? _date;
  DateTime? _endDate;
  String? _selectedContractorId;
  String? _selectedObjectId;
  ContractStatus _status = ContractStatus.active;
  bool _isVatIncluded = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    if (c != null) {
      _numberController.text = c.number;
      _amountController.text = c.amount.toStringAsFixed(2);
      _vatRateController.text = c.vatRate.toStringAsFixed(2);
      _vatAmountController.text = c.vatAmount.toStringAsFixed(2);
      _advanceAmountController.text = c.advanceAmount.toStringAsFixed(2);
      _warrantyRetentionAmountController.text =
          c.warrantyRetentionAmount.toStringAsFixed(2);
      _warrantyRetentionRateController.text =
          c.warrantyRetentionRate.toStringAsFixed(2);
      _warrantyPeriodMonthsController.text = c.warrantyPeriodMonths.toString();
      _generalContractorFeeAmountController.text =
          c.generalContractorFeeAmount.toStringAsFixed(2);
      _generalContractorFeeRateController.text =
          c.generalContractorFeeRate.toStringAsFixed(2);
      _date = c.date;
      _endDate = c.endDate;
      _selectedContractorId = c.contractorId;
      _selectedObjectId = c.objectId;
      _status = c.status;
      _isVatIncluded = c.isVatIncluded;
    }

    _amountController.addListener(_calculateVat);
    _vatRateController.addListener(_calculateVat);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateVat);
    _vatRateController.removeListener(_calculateVat);
    _numberController.dispose();
    _amountController.dispose();
    _vatRateController.dispose();
    _vatAmountController.dispose();
    _advanceAmountController.dispose();
    _warrantyRetentionAmountController.dispose();
    _warrantyRetentionRateController.dispose();
    _warrantyPeriodMonthsController.dispose();
    _generalContractorFeeAmountController.dispose();
    _generalContractorFeeRateController.dispose();
    super.dispose();
  }

  void _calculateVat() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final rate =
        double.tryParse(_vatRateController.text.replaceAll(',', '.')) ?? 0.0;

    if (rate == 0) {
      _vatAmountController.text = '0.00';
      return;
    }

    double vat;
    if (_isVatIncluded) {
      // Amount is Total. VAT = Amount * Rate / (100 + Rate)
      vat = amount * rate / (100 + rate);
    } else {
      // Amount is Base. VAT = Amount * Rate / 100
      // Wait, if user enters Base Amount here, then Total Amount will be higher.
      // But Contract.amount is usually Total.
      // If "On Top": User enters Base. We calculate VAT.
      // Should we update Amount field? No, usually Amount field is the user input.
      // Let's assume Amount field = Contract Amount (Total).
      // If User says "On Top", it means the Base was X and VAT was Y.
      // But if they enter the Total, then the calculation is always "Included".

      // User requirement: "Cost 36... including VAT 5%".
      // If user switches to "On Top", they probably want to enter Base Amount.
      // Let's stick to:
      // Included: VAT = Amount * Rate / (100 + Rate)
      // On Top: VAT = Amount * Rate / 100.

      vat = amount * rate / 100;
    }

    // Update VAT text without triggering loop if formatted same
    final newVatText = vat.toStringAsFixed(2);
    if (_vatAmountController.text != newVatText) {
      _vatAmountController.text = newVatText;
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null ||
        _selectedContractorId == null ||
        _selectedObjectId == null) {
      SnackBarUtils.showError(context, 'Заполните все обязательные поля');
      return;
    }
    setState(() => _isLoading = true);
    final notifier = ref.read(contractProvider.notifier);
    final isNew = widget.contract == null;
    final contract = Contract(
      id: widget.contract?.id ?? const Uuid().v4(),
      number: _numberController.text.trim(),
      date: _date!,
      endDate: _endDate,
      contractorId: _selectedContractorId!,
      contractorName: null,
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      vatRate:
          double.tryParse(_vatRateController.text.replaceAll(',', '.')) ?? 0.0,
      isVatIncluded: _isVatIncluded,
      vatAmount:
          double.tryParse(_vatAmountController.text.replaceAll(',', '.')) ??
              0.0,
      advanceAmount:
          double.tryParse(_advanceAmountController.text.replaceAll(',', '.')) ??
              0.0,
      warrantyRetentionAmount: double.tryParse(
              _warrantyRetentionAmountController.text.replaceAll(',', '.')) ??
          0.0,
      warrantyRetentionRate: double.tryParse(
              _warrantyRetentionRateController.text.replaceAll(',', '.')) ??
          0.0,
      warrantyPeriodMonths:
          int.tryParse(_warrantyPeriodMonthsController.text) ?? 0,
      generalContractorFeeAmount: double.tryParse(
              _generalContractorFeeAmountController.text
                  .replaceAll(',', '.')) ??
          0.0,
      generalContractorFeeRate: double.tryParse(
              _generalContractorFeeRateController.text.replaceAll(',', '.')) ??
          0.0,
      objectId: _selectedObjectId!,
      objectName: null,
      status: _status,
      createdAt: widget.contract?.createdAt,
      updatedAt: DateTime.now(),
    );
    debugPrint(
        '[CONTRACTS][FORM] contract: \\${ContractModel.fromDomain(contract).toJson()}');
    try {
      if (isNew) {
        await notifier.addContract(contract);
        if (!mounted) return;
        SnackBarUtils.showSuccess(context, 'Договор успешно добавлен');
      } else {
        await notifier.updateContract(contract);
        if (!mounted) return;
        SnackBarUtils.showInfo(context, 'Договор обновлён');
      }
      setState(() => _isLoading = false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[CONTRACTS][ERROR] $e');
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Ошибка: $e');
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final contractorState = ref.watch(contractorProvider);
    final objectState = ref.watch(objectProvider);
    final isNew = widget.contract == null;

    final contractorItems = {
      for (final c in contractorState.contractors) c.id: c.fullName
    };
    final objectItems = {for (final o in objectState.objects) o.id: o.name};

    return ContractFormContent(
      isNew: isNew,
      isLoading: _isLoading,
      numberController: _numberController,
      amountController: _amountController,
      vatRateController: _vatRateController,
      isVatIncluded: _isVatIncluded,
      vatAmountController: _vatAmountController,
      advanceAmountController: _advanceAmountController,
      warrantyRetentionAmountController: _warrantyRetentionAmountController,
      warrantyRetentionRateController: _warrantyRetentionRateController,
      warrantyPeriodMonthsController: _warrantyPeriodMonthsController,
      generalContractorFeeAmountController:
          _generalContractorFeeAmountController,
      generalContractorFeeRateController: _generalContractorFeeRateController,
      date: _date,
      endDate: _endDate,
      selectedContractorId: _selectedContractorId,
      selectedObjectId: _selectedObjectId,
      status: _status,
      formKey: _formKey,
      onSave: _handleSave,
      onCancel: _handleCancel,
      onDateChanged: (d) => setState(() => _date = d),
      onEndDateChanged: (d) => setState(() => _endDate = d),
      onContractorChanged: (id) => setState(() => _selectedContractorId = id),
      onObjectChanged: (id) => setState(() => _selectedObjectId = id),
      onStatusChanged: (s) =>
          setState(() => _status = s ?? ContractStatus.active),
      onVatIncludedChanged: (v) {
        setState(() {
          _isVatIncluded = v;
          _calculateVat();
        });
      },
      contractorItems: contractorItems,
      objectItems: objectItems,
    );
  }
}

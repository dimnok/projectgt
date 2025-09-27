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
  DateTime? _date;
  DateTime? _endDate;
  String? _selectedContractorId;
  String? _selectedObjectId;
  ContractStatus _status = ContractStatus.active;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    if (c != null) {
      _numberController.text = c.number;
      _amountController.text = c.amount.toStringAsFixed(2);
      _date = c.date;
      _endDate = c.endDate;
      _selectedContractorId = c.contractorId;
      _selectedObjectId = c.objectId;
      _status = c.status;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _amountController.dispose();
    super.dispose();
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

    final contractorItems = contractorState.contractors
        .map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.fullName),
            ))
        .toList();
    final objectItems = objectState.objects
        .map((o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(o.name),
            ))
        .toList();

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
  DateTime? _date;
  DateTime? _endDate;
  String? _selectedContractorId;
  String? _selectedObjectId;
  ContractStatus _status = ContractStatus.active;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    if (c != null) {
      _numberController.text = c.number;
      _amountController.text = c.amount.toStringAsFixed(2);
      _date = c.date;
      _endDate = c.endDate;
      _selectedContractorId = c.contractorId;
      _selectedObjectId = c.objectId;
      _status = c.status;
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _amountController.dispose();
    super.dispose();
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

    final contractorItems = contractorState.contractors
        .map((c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.fullName),
            ))
        .toList();
    final objectItems = objectState.objects
        .map((o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(o.name),
            ))
        .toList();

    return ContractFormContent(
      isNew: isNew,
      isLoading: _isLoading,
      numberController: _numberController,
      amountController: _amountController,
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
      contractorItems: contractorItems,
      objectItems: objectItems,
    );
  }
}

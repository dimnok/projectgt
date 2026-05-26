import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'contract_form_content.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/utils/vat_calc.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';

/// Модальное окно с формой договора.
/// Используется для создания или редактирования договора в диалоговом окне.
class ContractFormModal extends ConsumerStatefulWidget {
  /// Договор для редактирования. Если null — создаётся новый договор.
  final Contract? contract;

  /// Нужно ли оборачивать в DesktopDialogContent/MobileBottomSheetContent.
  /// По умолчанию true.
  final bool useWrapper;

  /// Создаёт модальное окно с формой договора.
  const ContractFormModal({
    super.key,
    this.contract,
    this.useWrapper = true,
  });

  /// Отображает модальное окно с формой договора с анимацией.
  static Future<void> show(
    BuildContext context, {
    Contract? contract,
  }) async {
    // Используем addPostFrameCallback для предотвращения MouseTracker error на десктопе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isNew = contract == null;
      DesktopDialogContent.show(
        context,
        title: isNew ? 'Новый договор' : 'Редактировать договор',
        width: 800,
        scrollable: true,
        // Мы передаем форму без обертки, так как DesktopDialogContent.show сам создаст обертку.
        child: ContractFormModal(
          contract: contract,
          useWrapper: false,
        ),
      );
    });
  }

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

  final _contractorLegalNameController = TextEditingController();
  final _contractorPositionController = TextEditingController();
  final _contractorSignerController = TextEditingController();
  final _customerLegalNameController = TextEditingController();
  final _customerPositionController = TextEditingController();
  final _customerSignerController = TextEditingController();

  DateTime? _date;
  DateTime? _endDate;
  String? _selectedContractorId;
  String? _selectedObjectId;
  ContractStatus _status = ContractStatus.active;
  ContractKind _kind = ContractKind.customer;
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
      _warrantyRetentionAmountController.text = c.warrantyRetentionAmount
          .toStringAsFixed(2);
      _warrantyRetentionRateController.text = c.warrantyRetentionRate
          .toStringAsFixed(2);
      _warrantyPeriodMonthsController.text = c.warrantyPeriodMonths.toString();
      _generalContractorFeeAmountController.text = c.generalContractorFeeAmount
          .toStringAsFixed(2);
      _generalContractorFeeRateController.text = c.generalContractorFeeRate
          .toStringAsFixed(2);

      _contractorLegalNameController.text = c.contractorOrgName ?? '';
      _contractorPositionController.text = c.contractorPosition ?? '';
      _contractorSignerController.text = c.contractorSigner ?? '';
      _customerLegalNameController.text = c.customerOrgName ?? '';
      _customerPositionController.text = c.customerPosition ?? '';
      _customerSignerController.text = c.customerSigner ?? '';

      _date = c.date;
      _endDate = c.endDate;
      _selectedContractorId = c.contractorId;
      _selectedObjectId = c.objectId;
      _status = c.status;
      _kind = c.kind;
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
    _contractorLegalNameController.dispose();
    _contractorPositionController.dispose();
    _contractorSignerController.dispose();
    _customerLegalNameController.dispose();
    _customerPositionController.dispose();
    _customerSignerController.dispose();
    super.dispose();
  }

  void _calculateVat() {
    final amount = parseAmount(_amountController.text) ?? 0.0;
    final rate = parseAmount(_vatRateController.text) ?? 0.0;
    final vat = computeVatAmount(
      baseAmount: amount,
      vatRate: rate,
      isVatIncluded: _isVatIncluded,
    );
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
      AppSnackBar.show(
        context: context,
        message: 'Заполните все обязательные поля',
        kind: AppSnackBarKind.error,
      );
      return;
    }
    setState(() => _isLoading = true);
    final notifier = ref.read(contractProvider.notifier);
    final activeCompanyId = ref.read(activeCompanyIdProvider);

    if (activeCompanyId == null) {
      setState(() => _isLoading = false);
      AppSnackBar.show(
        context: context,
        message: 'Ошибка: ID компании не найден',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final isNew = widget.contract == null;
    final contract = Contract(
      id: widget.contract?.id ?? const Uuid().v4(),
      companyId: activeCompanyId,
      number: _numberController.text.trim(),
      date: _date!,
      endDate: _endDate,
      contractorId: _selectedContractorId!,
      contractorName: null,
      amount: parseAmount(_amountController.text) ?? 0.0,
      vatRate: parseAmount(_vatRateController.text) ?? 0.0,
      isVatIncluded: _isVatIncluded,
      vatAmount: parseAmount(_vatAmountController.text) ?? 0.0,
      advanceAmount: parseAmount(_advanceAmountController.text) ?? 0.0,
      warrantyRetentionAmount:
          parseAmount(_warrantyRetentionAmountController.text) ?? 0.0,
      warrantyRetentionRate:
          parseAmount(_warrantyRetentionRateController.text) ?? 0.0,
      warrantyPeriodMonths:
          int.tryParse(_warrantyPeriodMonthsController.text) ?? 0,
      generalContractorFeeAmount:
          parseAmount(_generalContractorFeeAmountController.text) ?? 0.0,
      generalContractorFeeRate:
          parseAmount(_generalContractorFeeRateController.text) ?? 0.0,
      objectId: _selectedObjectId!,
      objectName: null,
      status: _status,
      kind: _kind,
      contractorOrgName: _contractorLegalNameController.text.trim().isEmpty
          ? null
          : _contractorLegalNameController.text.trim(),
      contractorPosition: _contractorPositionController.text.trim().isEmpty
          ? null
          : _contractorPositionController.text.trim(),
      contractorSigner: _contractorSignerController.text.trim().isEmpty
          ? null
          : _contractorSignerController.text.trim(),
      customerOrgName: _customerLegalNameController.text.trim().isEmpty
          ? null
          : _customerLegalNameController.text.trim(),
      customerPosition: _customerPositionController.text.trim().isEmpty
          ? null
          : _customerPositionController.text.trim(),
      customerSigner: _customerSignerController.text.trim().isEmpty
          ? null
          : _customerSignerController.text.trim(),
      createdAt: widget.contract?.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      if (isNew) {
        await notifier.addContract(contract);
        if (!mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Договор успешно добавлен',
          kind: AppSnackBarKind.success,
        );
      } else {
        await notifier.updateContract(contract);
        if (!mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Договор обновлён',
          kind: AppSnackBarKind.info,
        );
      }
      setState(() => _isLoading = false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Ошибка: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final contractorState = ref.watch(contractorNotifierProvider);
    final objectState = ref.watch(objectProvider);
    final isNew = widget.contract == null;
    final Map<String, String> contractorItems = {
      for (final c in contractorState.contractors) c.id: c.fullName,
    };
    final Map<String, String> objectItems = {
      for (final o in objectState.objects) o.id: o.name,
    };

    final isDesktop = MediaQuery.of(context).size.width > 800;
    final title = isNew ? 'Новый договор' : 'Редактировать договор';

    Widget footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(text: 'Отмена', onPressed: _handleCancel),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: isNew ? 'Создать' : 'Сохранить',
            onPressed: _isLoading ? null : _handleSave,
            isLoading: _isLoading,
          ),
        ),
      ],
    );

    Widget content = ContractFormContent(
      isNew: isNew,
      isLoading: _isLoading,
      showFooter: !widget.useWrapper,
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
      contractorLegalNameController: _contractorLegalNameController,
      contractorPositionController: _contractorPositionController,
      contractorSignerController: _contractorSignerController,
      customerLegalNameController: _customerLegalNameController,
      customerPositionController: _customerPositionController,
      customerSignerController: _customerSignerController,
      date: _date,
      endDate: _endDate,
      selectedContractorId: _selectedContractorId,
      selectedObjectId: _selectedObjectId,
      status: _status,
      kind: _kind,
      formKey: _formKey,
      onSave: _handleSave,
      onCancel: _handleCancel,
      onDateChanged: (d) => setState(() => _date = d),
      onEndDateChanged: (d) => setState(() => _endDate = d),
      onContractorChanged: (id) => setState(() => _selectedContractorId = id),
      onObjectChanged: (id) => setState(() => _selectedObjectId = id),
      onStatusChanged: (s) =>
          setState(() => _status = s ?? ContractStatus.active),
      onKindChanged: (k) =>
          setState(() => _kind = k ?? ContractKind.customer),
      onVatIncludedChanged: (v) {
        setState(() {
          _isVatIncluded = v;
          _calculateVat();
        });
      },
      contractorItems: contractorItems,
      objectItems: objectItems,
    );

    if (!widget.useWrapper) return content;

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        footer: footer,
        scrollable: true,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: content,
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      scrollable: true,
      child: content,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/payroll_transaction.dart';
import '../../data/models/payroll_bonus_model.dart';
import '../../data/models/payroll_penalty_model.dart';
import '../../../../presentation/state/employee_state.dart';
import '../../../../domain/entities/employee.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/bonus_providers.dart';
import '../providers/penalty_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/payroll_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/gt_text_field.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/gt_dropdown.dart';

/// Переиспользуемое модальное окно для добавления/редактирования транзакций ФОТ.
///
/// Поддерживает как премии, так и штрафы с унифицированной логикой и валидацией.
class PayrollTransactionFormModal extends ConsumerStatefulWidget {
  /// Тип транзакции (премия или штраф)
  final PayrollTransactionType transactionType;

  /// Существующая транзакция для редактирования (null для создания новой)
  final PayrollTransaction? transaction;

  /// Предзаполненный ID сотрудника
  final String? initialEmployeeId;

  /// Создаёт модальное окно для транзакции ФОТ.
  ///
  /// [transactionType] — тип транзакции (премия или штраф)
  /// [transaction] — существующая транзакция для редактирования
  /// [initialEmployeeId] — ID сотрудника для предзаполнения
  const PayrollTransactionFormModal({
    super.key,
    required this.transactionType,
    this.transaction,
    this.initialEmployeeId,
  });

  @override
  ConsumerState<PayrollTransactionFormModal> createState() =>
      _PayrollTransactionFormModalState();
}

class _PayrollTransactionFormModalState
    extends ConsumerState<PayrollTransactionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  Employee? _selectedEmployee;
  ObjectEntity? _selectedObject;
  bool _isSaving = false;

  bool get _isEditing => widget.transaction != null;
  PayrollTransactionType get _type => widget.transactionType;

  @override
  void initState() {
    super.initState();
    _initializeFromTransaction();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing) {
      _populateSelectedItems();
    } else if (widget.initialEmployeeId != null && _selectedEmployee == null) {
      _prefillEmployee();
    }
  }

  /// Предзаполняет сотрудника по ID
  void _prefillEmployee() {
    final employeeState = ref.read(employeeProvider);
    if (employeeState.employees.isNotEmpty) {
      _selectedEmployee = employeeState.employees
          .where((e) => e.id == widget.initialEmployeeId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Инициализирует поля из существующей транзакции при редактировании
  void _initializeFromTransaction() {
    final transaction = widget.transaction;
    if (transaction != null) {
      _selectedDate = transaction.date ?? transaction.createdAt;
      _amountController.text = transaction.amount.toString();
      if (transaction.reason != null) {
        _noteController.text = transaction.reason!;
      }
    }
  }

  /// Устанавливает выбранного сотрудника и объект при редактировании
  void _populateSelectedItems() {
    final transaction = widget.transaction;
    if (transaction == null) return;

    final employeeState = ref.read(employeeProvider);
    final objectState = ref.read(objectProvider);

    if (_selectedEmployee == null && employeeState.employees.isNotEmpty) {
      _selectedEmployee = employeeState.employees
          .where((e) => e.id == transaction.employeeId)
          .firstOrNull;
    }

    if (_selectedObject == null && objectState.objects.isNotEmpty) {
      _selectedObject = objectState.objects
          .where((o) => o.id == transaction.objectId)
          .firstOrNull;
    }
  }

  /// Выбор даты
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Сохранение транзакции
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      const uuid = Uuid();
      final amount = num.parse(_amountController.text.replaceAll(',', '.'));
      final reason =
          _noteController.text.isNotEmpty ? _noteController.text : null;
      final date = _selectedDate ?? DateTime.now();

      if (_type == PayrollTransactionType.bonus) {
        await _saveBonus(uuid, amount, reason, date);
      } else {
        await _savePenalty(uuid, amount, reason, date);
      }

      if (mounted) {
        Navigator.pop(context);
        _invalidateProviders();
        SnackBarUtils.showSuccess(
          context,
          _isEditing ? _type.updatedMessage : _type.addedMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Сохранение премии
  Future<void> _saveBonus(
      Uuid uuid, num amount, String? reason, DateTime date) async {
    final activeCompanyId = ref.read(activeCompanyIdProvider);
    if (activeCompanyId == null) {
      throw Exception('Компания не выбрана');
    }

    final bonus = PayrollBonusModel(
      id: _isEditing ? widget.transaction!.id : uuid.v4(),
      employeeId: _selectedEmployee?.id ?? '',
      companyId: activeCompanyId,
      type: 'manual',
      amount: amount,
      reason: reason,
      date: date,
      createdAt: _isEditing ? widget.transaction!.createdAt : DateTime.now(),
      objectId: _selectedObject?.id,
    );

    if (_isEditing) {
      final updateUseCase = ref.read(updateBonusUseCaseProvider);
      await updateUseCase(bonus);
    } else {
      final createUseCase = ref.read(createBonusUseCaseProvider);
      await createUseCase(bonus);
    }
  }

  /// Сохранение штрафа
  Future<void> _savePenalty(
      Uuid uuid, num amount, String? reason, DateTime date) async {
    final activeCompanyId = ref.read(activeCompanyIdProvider);
    if (activeCompanyId == null) {
      throw Exception('Компания не выбрана');
    }

    final penalty = PayrollPenaltyModel(
      id: _isEditing ? widget.transaction!.id : uuid.v4(),
      employeeId: _selectedEmployee?.id ?? '',
      companyId: activeCompanyId,
      type: 'manual',
      amount: amount,
      reason: reason,
      date: date,
      createdAt: DateTime.now(),
      objectId: _selectedObject?.id,
    );

    if (_isEditing) {
      final updateUseCase = ref.read(updatePenaltyUseCaseProvider);
      await updateUseCase(penalty);
    } else {
      final createUseCase = ref.read(createPenaltyUseCaseProvider);
      await createUseCase(penalty);
    }
  }

  /// Инвалидация провайдеров после сохранения
  void _invalidateProviders() {
    if (_type == PayrollTransactionType.bonus) {
      ref.invalidate(bonusesByFilterProvider);
    } else {
      ref.invalidate(penaltiesByFilterProvider);
    }
    ref.invalidate(employeeAggregatedBalanceProvider);
    ref.invalidate(payrollPayoutsByFilterProvider);
    ref.invalidate(filteredPayrollsProvider); // Обновляем основную таблицу ФОТ
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeProvider);
    final objectState = ref.watch(objectProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Сортировка сотрудников по алфавиту (Фамилия Имя Отчество)
    final employees = List<Employee>.from(employeeState.employees)
      ..sort((a, b) {
        final fioA = [
          a.lastName,
          a.firstName,
          if (a.middleName != null && a.middleName!.isNotEmpty) a.middleName
        ].join(' ');
        final fioB = [
          b.lastName,
          b.firstName,
          if (b.middleName != null && b.middleName!.isNotEmpty) b.middleName
        ].join(' ');
        return fioA.compareTo(fioB);
      });

    final objects = objectState.objects;

    final title = _isEditing ? _type.editTitle : _type.addTitle;
    final content = Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildForm(theme, employees, objects),
        ],
      ),
    );

    final footer = _buildButtons();

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesktopDialogContent(
          title: title,
          footer: footer,
          child: content,
      ),
    );
  }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: content,
    );
  }

  /// Строит форму
  Widget _buildForm(
      ThemeData theme, List<Employee> employees, List<ObjectEntity> objects) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateField(),
            const SizedBox(height: 16),
            _buildEmployeeField(employees),
            const SizedBox(height: 16),
            _buildObjectField(objects),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildNoteField(),
          ],
    );
  }

  /// Поле выбора даты
  Widget _buildDateField() {
    return GTTextField(
      labelText: 'Дата',
      prefixIcon: Icons.event,
      readOnly: true,
      onTap: _pickDate,
          controller: TextEditingController(
            text: _selectedDate != null
                ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                : '',
          ),
          validator: (_) => _selectedDate == null ? 'Выберите дату' : null,
    );
  }

  /// Поле выбора сотрудника (GTDropdown)
  Widget _buildEmployeeField(List<Employee> employees) {
    return GTDropdown<Employee>(
      items: employees,
      itemDisplayBuilder: (e) => [
        e.lastName,
        e.firstName,
        if (e.middleName != null && e.middleName!.isNotEmpty) e.middleName
      ].join(' '),
      selectedItem: _selectedEmployee,
      onSelectionChanged: (employee) {
        setState(() {
          _selectedEmployee = employee;
        });
      },
      labelText: 'Сотрудник',
      hintText: employees.isEmpty
          ? 'Нет доступных сотрудников'
          : 'Выберите сотрудника',
      validator: (_) =>
          _selectedEmployee == null ? 'Выберите сотрудника' : null,
    );
  }

  /// Поле выбора объекта (GTDropdown)
  Widget _buildObjectField(List<ObjectEntity> objects) {
    return GTDropdown<ObjectEntity>(
      items: objects,
      itemDisplayBuilder: (o) => o.name,
      selectedItem: _selectedObject,
      onSelectionChanged: (object) {
        setState(() {
          _selectedObject = object;
        });
      },
      labelText: 'Объект',
      hintText: objects.isEmpty ? 'Нет доступных объектов' : 'Выберите объект',
      validator: (_) => _selectedObject == null ? 'Выберите объект' : null,
    );
  }

  /// Поле ввода суммы
  Widget _buildAmountField() {
    return GTTextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
        labelText: _type.amountLabel,
      prefixIcon: Icons.currency_ruble,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Введите сумму';
        final num? n = num.tryParse(value.replaceAll(',', '.'));
        if (n == null || n <= 0) return 'Некорректная сумма';
        return null;
      },
    );
  }

  /// Поле комментария
  Widget _buildNoteField() {
    return GTTextField(
      controller: _noteController,
        labelText: _type == PayrollTransactionType.bonus
            ? 'Примечание'
            : 'Комментарий',
      prefixIcon: Icons.comment_outlined,
        hintText: _type == PayrollTransactionType.bonus
            ? 'Причина или комментарий'
            : null,
      maxLines: 3,
    );
  }

  /// Кнопки действий
  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: _isEditing ? 'Обновить' : 'Сохранить',
            onPressed: _isSaving ? null : _saveTransaction,
            isLoading: _isSaving,
          ),
        ),
      ],
    );
  }
}

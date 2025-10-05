import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/payroll_transaction.dart';
import '../../data/models/payroll_bonus_model.dart';
import '../../data/models/payroll_penalty_model.dart';
import '../../../../presentation/state/employee_state.dart';
import '../../../../domain/entities/employee.dart';
import '../../../../domain/entities/object.dart';
import 'package:projectgt/core/di/providers.dart';
import '../providers/bonus_providers.dart';
import '../providers/penalty_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/payroll_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/modal_container_wrapper.dart';
import '../../../../core/widgets/gt_dropdown.dart';

/// Переиспользуемое модальное окно для добавления/редактирования транзакций ФОТ.
///
/// Поддерживает как премии, так и штрафы с унифицированной логикой и валидацией.
class PayrollTransactionFormModal extends ConsumerStatefulWidget {
  /// Тип транзакции (премия или штраф)
  final PayrollTransactionType transactionType;

  /// Существующая транзакция для редактирования (null для создания новой)
  final PayrollTransaction? transaction;

  /// Создаёт модальное окно для транзакции ФОТ.
  ///
  /// [transactionType] — тип транзакции (премия или штраф)
  /// [transaction] — существующая транзакция для редактирования
  const PayrollTransactionFormModal({
    super.key,
    required this.transactionType,
    this.transaction,
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
    final bonus = PayrollBonusModel(
      id: _isEditing ? widget.transaction!.id : uuid.v4(),
      employeeId: _selectedEmployee?.id ?? '',
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
    final penalty = PayrollPenaltyModel(
      id: _isEditing ? widget.transaction!.id : uuid.v4(),
      employeeId: _selectedEmployee?.id ?? '',
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
      ref.invalidate(allBonusesProvider);
    } else {
      ref.invalidate(allPenaltiesProvider);
    }
    ref.invalidate(employeeAggregatedBalanceProvider);
    ref.invalidate(payrollPayoutsByMonthProvider);
    ref.invalidate(filteredPayrollsProvider); // Обновляем основную таблицу ФОТ
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeProvider);
    final objectState = ref.watch(objectProvider);

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

    return ModalContainerWrapper(
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const Divider(),
                    _buildForm(theme, employees, objects),
                    const SizedBox(height: 24),
                    _buildButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Строит заголовок модального окна
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEditing ? _type.editTitle : _type.addTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Строит форму
  Widget _buildForm(
      ThemeData theme, List<Employee> employees, List<ObjectEntity> objects) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
        ),
      ),
    );
  }

  /// Поле выбора даты
  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Дата',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.event),
          ),
          controller: TextEditingController(
            text: _selectedDate != null
                ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
                : '',
          ),
          validator: (_) => _selectedDate == null ? 'Выберите дату' : null,
        ),
      ),
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
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: _type.amountLabel,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.currency_ruble),
      ),
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
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: _type == PayrollTransactionType.bonus
            ? 'Примечание'
            : 'Комментарий',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.comment_outlined),
        hintText: _type == PayrollTransactionType.bonus
            ? 'Причина или комментарий'
            : null,
      ),
      minLines: 1,
      maxLines: 3,
    );
  }

  /// Кнопки действий
  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Отмена'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CupertinoActivityIndicator(),
                  )
                : Text(_isEditing ? 'Обновить' : 'Сохранить'),
          ),
        ),
      ],
    );
  }
}

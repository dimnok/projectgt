import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/state/employee_state.dart';
import '../../../../domain/entities/employee.dart';
import 'package:intl/intl.dart';
import '../providers/payroll_providers.dart';
import '../providers/balance_providers.dart';
import '../../data/models/payroll_payout_model.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/modal_container_wrapper.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import 'payroll_payout_amount_modal.dart';

/// Класс, представляющий способ выплаты сотруднику в рамках модуля ФОТ.
///
/// Используется для выбора метода перевода средств при создании или редактировании выплаты.
/// Поддерживает фиксированный набор значений: карта, наличные, банковский перевод.
class PaymentMethod {
  /// Значение способа выплаты для хранения в базе данных (например, 'card', 'cash', 'bank_transfer').
  final String value;

  /// Отображаемое название способа выплаты для UI (например, 'Карта', 'Наличные', 'Банковский перевод').
  final String displayName;

  /// Конструктор [PaymentMethod].
  ///
  /// [value] — строковое значение для хранения в БД.
  /// [displayName] — человекочитаемое название для отображения в интерфейсе.
  const PaymentMethod(this.value, this.displayName);

  /// Список всех допустимых способов выплаты.
  ///
  /// Используется для построения выпадающих списков и валидации значений.
  static const List<PaymentMethod> values = [
    PaymentMethod('card', 'Карта'),
    PaymentMethod('cash', 'Наличные'),
    PaymentMethod('bank_transfer', 'Банковский перевод'),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Класс, представляющий тип выплаты сотруднику (например, зарплата или аванс).
///
/// Используется для классификации выплат в модуле ФОТ и фильтрации по типу операции.
class PaymentType {
  /// Значение типа выплаты для хранения в базе данных (например, 'salary', 'advance').
  final String value;

  /// Отображаемое название типа выплаты для UI (например, 'Зарплата', 'Аванс').
  final String displayName;

  /// Конструктор [PaymentType].
  ///
  /// [value] — строковое значение для хранения в БД.
  /// [displayName] — человекочитаемое название для отображения в интерфейсе.
  const PaymentType(this.value, this.displayName);

  /// Список всех допустимых типов выплат.
  ///
  /// Используется для построения выпадающих списков и валидации значений.
  static const List<PaymentType> values = [
    PaymentType('salary', 'Зарплата'),
    PaymentType('advance', 'Аванс'),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentType &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Модальное окно для создания/редактирования выплаты
class PayrollPayoutFormModal extends ConsumerStatefulWidget {
  /// Выплата для редактирования (null для создания новой)
  final PayrollPayoutModel? payout;

  /// Конструктор [PayrollPayoutFormModal].
  ///
  /// Используется для создания новой выплаты или редактирования существующей в модуле ФОТ.
  ///
  /// [payout] — модель выплаты для редактирования (если null, открывается режим создания массовых выплат).
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollPayoutFormModal({
    super.key,
    this.payout,
  });

  /// Создаёт состояние для модального окна [PayrollPayoutFormModal].
  ///
  /// Возвращает экземпляр [_PayrollPayoutFormModalState], реализующий логику создания и редактирования выплат.
  @override
  ConsumerState<PayrollPayoutFormModal> createState() =>
      _PayrollPayoutFormModalState();
}

class _PayrollPayoutFormModalState
    extends ConsumerState<PayrollPayoutFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  final _isSaving = ValueNotifier<bool>(false);

  Employee? _selectedEmployee; // Для редактирования
  List<Employee> _selectedEmployees = []; // Для создания
  DateTime? _selectedDate;
  PaymentMethod _selectedMethod = PaymentMethod.values.first;
  PaymentType _selectedType = PaymentType.values.first;

  bool get isEditing => widget.payout != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _initializeForEditing();
    }
  }

  void _initializeForEditing() {
    final payout = widget.payout!;
    _amountController.text = payout.amount.toString();
    _selectedDate = payout.payoutDate;

    // Находим соответствующий PaymentMethod
    _selectedMethod = PaymentMethod.values.firstWhere(
      (m) => m.value == payout.method,
      orElse: () => PaymentMethod.values.first,
    );

    // Находим соответствующий PaymentType
    _selectedType = PaymentType.values.firstWhere(
      (t) => t.value == payout.type,
      orElse: () => PaymentType.values.first,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isEditing && _selectedEmployee == null) {
      _populateSelectedEmployee();
    }
  }

  /// Устанавливает выбранного сотрудника при редактировании
  void _populateSelectedEmployee() {
    final payout = widget.payout;
    if (payout == null) return;

    final employeeState = ref.read(employeeProvider);
    if (employeeState.employees.isNotEmpty) {
      _selectedEmployee = employeeState.employees
          .where((e) => e.id == payout.employeeId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _amountController.dispose();
    _isSaving.dispose();
    super.dispose();
  }

  /// Выбор даты
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Сохранение выплаты
  Future<void> _savePayout() async {
    if (!_formKey.currentState!.validate()) return;

    if (isEditing) {
      await _updatePayout();
    } else {
      await _createMultiplePayouts();
    }
  }

  /// Обновление существующей выплаты
  Future<void> _updatePayout() async {
    _isSaving.value = true;

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      final updatedPayout = PayrollPayoutModel(
        id: widget.payout!.id,
        employeeId: _selectedEmployee!.id,
        amount: amount,
        payoutDate: _selectedDate ?? DateTime.now(),
        method: _selectedMethod.value,
        type: _selectedType.value,
        createdAt: widget.payout!.createdAt,
      );

      final updateUseCase = ref.read(updatePayoutUseCaseProvider);
      await updateUseCase(updatedPayout);

      ref.invalidate(filteredPayrollPayoutsProvider);
      ref.invalidate(employeeAggregatedBalanceProvider);
      ref.invalidate(payrollPayoutsByMonthProvider);

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, 'Выплата обновлена');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      _isSaving.value = false;
    }
  }

  /// Создание множественных выплат
  Future<void> _createMultiplePayouts() async {
    if (_selectedEmployees.isEmpty) {
      SnackBarUtils.showError(context, 'Выберите сотрудников');
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    // Если сумма указана, создаём сразу
    if (amount != null && amount > 0) {
      await _createPayoutsWithAmount(amount);
    } else {
      // Открываем второе окно для указания индивидуальных сумм
      if (!mounted) return;
      await _openAmountModal();
    }
  }

  /// Создание выплат с единой суммой
  Future<void> _createPayoutsWithAmount(double amount) async {
    _isSaving.value = true;

    try {
      final createUseCase = ref.read(createPayoutUseCaseProvider);

      for (final employee in _selectedEmployees) {
        final payout = PayrollPayoutModel(
          id: '', // Будет сгенерировано в БД
          employeeId: employee.id,
          amount: amount,
          payoutDate: _selectedDate ?? DateTime.now(),
          method: _selectedMethod.value,
          type: _selectedType.value,
          createdAt: DateTime.now(),
        );

        await createUseCase(payout);
      }

      ref.invalidate(filteredPayrollPayoutsProvider);
      ref.invalidate(employeeAggregatedBalanceProvider);
      ref.invalidate(payrollPayoutsByMonthProvider);

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(
            context, 'Создано выплат: ${_selectedEmployees.length}');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      _isSaving.value = false;
    }
  }

  /// Открытие модального окна для указания индивидуальных сумм
  Future<void> _openAmountModal() async {
    final comment = _commentController.text.trim();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayrollPayoutAmountModal(
        selectedEmployees: _selectedEmployees,
        payoutDate: _selectedDate ?? DateTime.now(),
        method: _selectedMethod.value,
        type: _selectedType.value,
        comment: comment.isEmpty ? '' : comment,
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeProvider);

    // Сортировка сотрудников по алфавиту
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
                    _buildForm(theme, employees),
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
              isEditing ? 'Редактировать выплату' : 'Создать выплаты',
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
  Widget _buildForm(ThemeData theme, List<Employee> employees) {
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
            _buildMethodField(),
            const SizedBox(height: 16),
            _buildTypeField(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildCommentField(),
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
            labelText: 'Дата выплаты',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.event),
          ),
          controller: TextEditingController(
            text: _selectedDate != null
                ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                : '',
          ),
          validator: (_) =>
              _selectedDate == null ? 'Выберите дату выплаты' : null,
        ),
      ),
    );
  }

  /// Поле выбора сотрудника/сотрудников (GTDropdown)
  Widget _buildEmployeeField(List<Employee> employees) {
    if (isEditing) {
      // Одиночный выбор для редактирования
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
    } else {
      // Множественный выбор для создания
      return GTDropdown<Employee>(
        items: employees,
        itemDisplayBuilder: (e) => [
          e.lastName,
          e.firstName,
          if (e.middleName != null && e.middleName!.isNotEmpty) e.middleName
        ].join(' '),
        selectedItems: _selectedEmployees,
        onMultiSelectionChanged: (selectedList) {
          setState(() {
            _selectedEmployees = selectedList;
          });
        },
        labelText: 'Сотрудники',
        hintText: employees.isEmpty
            ? 'Нет доступных сотрудников'
            : 'Выберите сотрудников',
        allowMultipleSelection: true,
        validator: (_) =>
            _selectedEmployees.isEmpty ? 'Выберите сотрудников' : null,
      );
    }
  }

  /// Поле выбора способа выплаты (GTDropdown)
  Widget _buildMethodField() {
    return GTDropdown<PaymentMethod>(
      items: PaymentMethod.values,
      itemDisplayBuilder: (method) => method.displayName,
      selectedItem: _selectedMethod,
      onSelectionChanged: (method) {
        setState(() {
          _selectedMethod = method ?? PaymentMethod.values.first;
        });
      },
      labelText: 'Способ выплаты',
      hintText: 'Выберите способ выплаты',
      allowClear: false,
    );
  }

  /// Поле выбора типа выплаты (GTDropdown)
  Widget _buildTypeField() {
    return GTDropdown<PaymentType>(
      items: PaymentType.values,
      itemDisplayBuilder: (type) => type.displayName,
      selectedItem: _selectedType,
      onSelectionChanged: (type) {
        setState(() {
          _selectedType = type ?? PaymentType.values.first;
        });
      },
      labelText: 'Тип выплаты',
      hintText: 'Выберите тип выплаты',
      allowClear: false,
    );
  }

  /// Поле ввода суммы
  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: isEditing ? 'Сумма' : 'Сумма (необязательно)',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.currency_ruble),
        hintText: isEditing ? null : 'Оставьте пустым для индивидуальных сумм',
      ),
      validator: (value) {
        if (isEditing) {
          if (value == null || value.isEmpty) return 'Введите сумму';
          final num? n = num.tryParse(value.replaceAll(',', '.'));
          if (n == null || n <= 0) return 'Некорректная сумма';
        }
        return null;
      },
    );
  }

  /// Поле комментария
  Widget _buildCommentField() {
    return TextFormField(
      controller: _commentController,
      decoration: const InputDecoration(
        labelText: 'Комментарий (необязательно)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.comment_outlined),
      ),
      minLines: 1,
      maxLines: 3,
    );
  }

  /// Кнопки действий
  Widget _buildButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSaving,
      builder: (context, isSaving, _) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
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
                onPressed: isSaving ? null : _savePayout,
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
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CupertinoActivityIndicator(),
                      )
                    : Text(isEditing ? 'Обновить' : 'Продолжить'),
              ),
            ),
          ],
        );
      },
    );
  }
}

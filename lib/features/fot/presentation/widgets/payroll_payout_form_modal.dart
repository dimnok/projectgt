import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../presentation/state/employee_state.dart';
import '../../../../domain/entities/employee.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:intl/intl.dart';
import '../providers/payroll_providers.dart';
import '../providers/balance_providers.dart';
import '../../data/models/payroll_payout_model.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/gt_text_field.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../core/utils/responsive_utils.dart';
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

  /// Предзаполненный ID сотрудника
  final String? initialEmployeeId;

  /// Конструктор [PayrollPayoutFormModal].
  ///
  /// Используется для создания новой выплаты или редактирования существующей в модуле ФОТ.
  ///
  /// [payout] — модель выплаты для редактирования (если null, открывается режим создания массовых выплат).
  /// [initialEmployeeId] — ID сотрудника для предзаполнения (только для режима создания).
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollPayoutFormModal({
    super.key,
    this.payout,
    this.initialEmployeeId,
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
  final _dateController = TextEditingController();
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
    _updateDateController();

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

  void _updateDateController() {
    _dateController.text = _selectedDate != null
        ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
        : '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isEditing && _selectedEmployee == null) {
      _populateSelectedEmployee();
    } else if (!isEditing &&
        widget.initialEmployeeId != null &&
        _selectedEmployees.isEmpty) {
      _prefillEmployees();
    }
  }

  /// Предзаполняет список сотрудников одним сотрудником по ID
  void _prefillEmployees() {
    final employeeState = ref.read(employeeProvider);
    if (employeeState.employees.isNotEmpty) {
      final employee = employeeState.employees
          .where((e) => e.id == widget.initialEmployeeId)
          .firstOrNull;
      if (employee != null) {
        _selectedEmployees = [employee];
      }
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
    _dateController.dispose();
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
      setState(() {
        _selectedDate = picked;
        _updateDateController();
      });
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
      final activeCompanyId = ref.read(activeCompanyIdProvider);

      if (activeCompanyId == null) {
        throw Exception('Компания не выбрана');
      }

      final updatedPayout = PayrollPayoutModel(
        id: widget.payout!.id,
        employeeId: _selectedEmployee!.id,
        companyId: activeCompanyId,
        amount: amount,
        payoutDate: _selectedDate ?? DateTime.now(),
        method: _selectedMethod.value,
        type: _selectedType.value,
        createdAt: widget.payout!.createdAt,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      final updateUseCase = ref.read(updatePayoutUseCaseProvider);
      await updateUseCase(updatedPayout);

      ref.invalidate(filteredPayrollPayoutsProvider);
      ref.invalidate(employeeAggregatedBalanceProvider);
      ref.invalidate(payrollPayoutsByFilterProvider);

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

    // Всегда открываем окно для указания индивидуальных сумм
    if (!mounted) return;
    await _openAmountModal();
  }

  /// Открытие модального окна для указания индивидуальных сумм
  Future<void> _openAmountModal() async {
    final comment = _commentController.text.trim();
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final result = await (isDesktop
        ? showDialog<bool>(
            context: context,
            builder: (context) => PayrollPayoutAmountModal(
              selectedEmployees: _selectedEmployees,
              payoutDate: _selectedDate ?? DateTime.now(),
              method: _selectedMethod.value,
              type: _selectedType.value,
              comment: comment.isEmpty ? '' : comment,
            ),
          )
        : showModalBottomSheet<bool>(
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
          ));

    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Сортировка сотрудников по алфавиту
    final employees = List<Employee>.from(employeeState.employees)
      ..sort((a, b) =>
          _getEmployeeDisplayName(a).compareTo(_getEmployeeDisplayName(b)));

    final title = isEditing ? 'Редактировать выплату' : 'Создать выплаты';
    final content = Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildForm(theme, employees),
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
  Widget _buildForm(ThemeData theme, List<Employee> employees) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateField(),
          const SizedBox(height: 16),
          _buildEmployeeField(employees),
          const SizedBox(height: 16),
          _buildMethodField(),
          const SizedBox(height: 16),
          _buildTypeField(),
          if (isEditing) ...[
            const SizedBox(height: 16),
            _buildAmountField(),
          ],
          const SizedBox(height: 16),
          _buildCommentField(),
        ],
    );
  }

  /// Поле выбора даты
  Widget _buildDateField() {
    return GTTextField(
      controller: _dateController,
      labelText: 'Дата выплаты',
      prefixIcon: Icons.event,
      readOnly: true,
      onTap: _pickDate,
      validator: (_) => _selectedDate == null ? 'Выберите дату выплаты' : null,
    );
  }

  /// Формирует ФИО сотрудника для отображения
  String _getEmployeeDisplayName(Employee employee) {
    return [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName
    ].join(' ');
  }

  /// Поле выбора сотрудника/сотрудников (GTDropdown)
  Widget _buildEmployeeField(List<Employee> employees) {
    if (isEditing) {
      // Одиночный выбор для редактирования
      return GTDropdown<Employee>(
        items: employees,
        itemDisplayBuilder: _getEmployeeDisplayName,
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
        itemDisplayBuilder: _getEmployeeDisplayName,
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
    return GTTextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
        labelText: 'Сумма',
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
  Widget _buildCommentField() {
    return GTTextField(
      controller: _commentController,
        labelText: 'Комментарий (необязательно)',
      prefixIcon: Icons.comment_outlined,
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
              child: GTSecondaryButton(
                text: 'Отмена',
                onPressed: isSaving ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTPrimaryButton(
                text: isEditing ? 'Обновить' : 'Продолжить',
                onPressed: isSaving ? null : _savePayout,
                isLoading: isSaving,
              ),
            ),
          ],
        );
      },
    );
  }
}

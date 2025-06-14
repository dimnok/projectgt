import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/fot/data/models/payroll_bonus_model.dart';
import '../providers/payroll_filter_provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/bonus_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/payroll_providers.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/core/widgets/dropdown_typeahead_field.dart';

/// Модальное окно для добавления или редактирования премии сотрудника.
/// 
/// Позволяет выбрать сотрудника, объект, сумму, дату и комментарий для премии. 
/// Используется в модуле ФОТ для управления премиями.
class PayrollBonusFormModal extends ConsumerStatefulWidget {
  /// Модель премии для редактирования (null — для создания новой премии).
  final PayrollBonusModel? bonus;
  /// Создаёт модальное окно для добавления или редактирования премии.
  /// 
  /// [bonus] — если передан, окно откроется в режиме редактирования.
  const PayrollBonusFormModal({super.key, this.bonus});

  /// Создаёт состояние для модального окна премии.
  @override
  ConsumerState<PayrollBonusFormModal> createState() => _PayrollBonusFormModalState();
}

/// Состояние для модального окна добавления/редактирования премии.
/// 
/// Управляет формой, валидацией, выбором сотрудника, объекта, датой и сохранением премии.
class _PayrollBonusFormModalState extends ConsumerState<PayrollBonusFormModal> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _objectController = TextEditingController();
  String? _selectedEmployeeId;
  String? _selectedObjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final bonus = widget.bonus;
    if (bonus != null) {
      _selectedDate = bonus.createdAt;
      _amountController.text = bonus.amount.toString();
      if (bonus.reason != null) _noteController.text = bonus.reason!;
      _selectedEmployeeId = bonus.employeeId;
      _selectedObjectId = bonus.objectId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bonus = widget.bonus;
    if (bonus != null) {
      final filterState = ref.read(payrollFilterProvider);
      final employees = filterState.employees;
      final employee = employees.firstWhereOrNull((e) => e.id == bonus.employeeId);
      if (employee != null) {
        _employeeController.text = [employee.lastName, employee.firstName, if (employee.middleName != null && employee.middleName.isNotEmpty) employee.middleName].join(' ');
      }
      final objects = filterState.objects;
      final object = objects.firstWhereOrNull((o) => o.id == bonus.objectId);
      if (object != null) {
        _objectController.text = object.name;
      }
    }
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _objectController.dispose();
    super.dispose();
  }

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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onEmployeeSelected(dynamic employee) {
    _selectedEmployeeId = employee.id;
    _employeeController.text = [employee.lastName, employee.firstName, if (employee.middleName != null && employee.middleName.isNotEmpty) employee.middleName].join(' ');
  }

  void _onObjectSelected(dynamic object) {
    _selectedObjectId = object.id;
    _objectController.text = object.name;
  }

  Future<void> _saveBonus() async {
    debugPrint('[БОНУС] Нажатие сохранить. employeeId=$_selectedEmployeeId, objectId=$_selectedObjectId, сумма=${_amountController.text}, дата=$_selectedDate, reason=${_noteController.text}');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[БОНУС] Валидация не пройдена');
      return;
    }
    setState(() => _isSaving = true);
    try {
      const uuid = Uuid();
      final isEdit = widget.bonus != null;
      final bonus = PayrollBonusModel(
        id: isEdit ? widget.bonus!.id : uuid.v4(),
        employeeId: _selectedEmployeeId ?? '',
        type: 'manual',
        amount: num.parse(_amountController.text.replaceAll(',', '.')),
        reason: _noteController.text.isNotEmpty ? _noteController.text : null,
        createdAt: _selectedDate ?? DateTime.now(),
        objectId: _selectedObjectId,
      );
      debugPrint('[БОНУС] Модель для сохранения: $bonus');
      if (isEdit) {
        final updateBonus = ref.read(updateBonusUseCaseProvider);
        debugPrint('[БОНУС] Вызов updateBonus...');
        await updateBonus(bonus);
        debugPrint('[БОНУС] updateBonus завершён');
      } else {
        final createBonus = ref.read(createBonusUseCaseProvider);
        debugPrint('[БОНУС] Вызов createBonus...');
        await createBonus(bonus);
        debugPrint('[БОНУС] createBonus завершён');
      }
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(allBonusesProvider);
        ref.invalidate(employeeAggregatedBalanceProvider);
        ref.invalidate(payrollPayoutsByMonthProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Премия обновлена' : 'Премия добавлена')),
        );
        debugPrint('[БОНУС] Сохранение завершено, окно закрыто');
      }
    } catch (e, st) {
      debugPrint('[БОНУС][ОШИБКА] $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка:   0{e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollFilterProvider);
    final employees = filterState.employees;
    final objects = filterState.objects;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final screenWidth = MediaQuery.of(context).size.width;
    final modalContent = Container(
      margin: isDesktop ? const EdgeInsets.only(top: 48) : EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.bonus == null ? 'Добавить премию' : 'Редактировать премию',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    ),
                    const Divider(),
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 51),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Дата
                            GestureDetector(
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
                            ),
                            const SizedBox(height: 16),
                            // Сотрудник
                            DropdownTypeAheadField<dynamic>(
                              controller: _employeeController,
                              labelText: 'Сотрудник',
                              hintText: employees.isEmpty ? 'Нет доступных значений' : 'Выберите сотрудника',
                              items: employees,
                              displayStringForOption: (e) => [e.lastName, e.firstName, if (e.middleName != null && e.middleName.isNotEmpty) e.middleName].join(' '),
                              onSelected: employees.isEmpty ? (_) {} : _onEmployeeSelected,
                              validator: (value) => _selectedEmployeeId == null ? 'Выберите сотрудника' : null,
                              allowCustomValues: false,
                            ),
                            const SizedBox(height: 16),
                            // Объект
                            DropdownTypeAheadField<dynamic>(
                              controller: _objectController,
                              labelText: 'Объект',
                              hintText: objects.isEmpty ? 'Нет доступных значений' : 'Выберите объект',
                              items: objects,
                              displayStringForOption: (o) => o.name,
                              onSelected: objects.isEmpty ? (_) {} : _onObjectSelected,
                              validator: (value) => _selectedObjectId == null ? 'Выберите объект' : null,
                              allowCustomValues: false,
                            ),
                            const SizedBox(height: 16),
                            // Сумма
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Сумма',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_ruble),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Введите сумму';
                                final num? n = num.tryParse(value.replaceAll(',', '.'));
                                if (n == null || n <= 0) return 'Некорректная сумма';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Примечание
                            TextFormField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Примечание',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.comment_outlined),
                                hintText: 'Причина или комментарий',
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveBonus,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(widget.bonus == null ? 'Сохранить' : 'Обновить'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (isDesktop) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.5,
          ),
          child: modalContent,
        ),
      );
    } else {
      return modalContent;
    }
  }
} 
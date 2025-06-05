import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/fot/data/models/payroll_penalty_model.dart';
import '../providers/payroll_filter_provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/penalty_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/payroll_providers.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/core/widgets/dropdown_typeahead_field.dart';

/// Модальное окно для добавления или редактирования штрафа сотрудника.
/// 
/// Позволяет выбрать сотрудника, объект, сумму, дату и комментарий для штрафа. 
/// Используется в модуле ФОТ для управления штрафами.
class PayrollPenaltyFormModal extends ConsumerStatefulWidget {
  /// Модель штрафа для редактирования (null — для создания нового штрафа).
  final PayrollPenaltyModel? penalty;
  /// Создаёт модальное окно для добавления или редактирования штрафа.
  /// 
  /// [penalty] — если передан, окно откроется в режиме редактирования.
  const PayrollPenaltyFormModal({super.key, this.penalty});

  /// Создаёт состояние для модального окна штрафа.
  @override
  ConsumerState<PayrollPenaltyFormModal> createState() => _PayrollPenaltyFormModalState();
}

/// Состояние для модального окна добавления/редактирования штрафа.
/// 
/// Управляет формой, валидацией, выбором сотрудника, объекта, датой и сохранением штрафа.
class _PayrollPenaltyFormModalState extends ConsumerState<PayrollPenaltyFormModal> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _objectController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _selectedEmployeeId;
  String? _selectedObjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final penalty = widget.penalty;
    if (penalty != null) {
      _selectedDate = penalty.date ?? penalty.createdAt;
      _amountController.text = penalty.amount.toString();
      if (penalty.reason != null) _noteController.text = penalty.reason!;
      _selectedEmployeeId = penalty.employeeId;
      _selectedObjectId = penalty.objectId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final penalty = widget.penalty;
    if (penalty != null) {
      final filterState = ref.read(payrollFilterProvider);
      final employees = filterState.employees;
      final employee = employees.firstWhereOrNull((e) => e.id == penalty.employeeId);
      if (employee != null) {
        _employeeController.text = [employee.lastName, employee.firstName, if (employee.middleName != null && employee.middleName.isNotEmpty) employee.middleName].join(' ');
      }
      final objects = filterState.objects;
      final object = objects.firstWhereOrNull((o) => o.id == penalty.objectId);
      if (object != null) {
        _objectController.text = object.name;
      }
    }
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _objectController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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

  Future<void> _savePenalty() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      const uuid = Uuid();
      final isEdit = widget.penalty != null;
      final penalty = PayrollPenaltyModel(
        id: isEdit ? widget.penalty!.id : uuid.v4(),
        employeeId: _selectedEmployeeId,
        type: 'manual', // фиксированное значение
        amount: num.parse(_amountController.text.replaceAll(',', '.')),
        reason: _noteController.text.isNotEmpty ? _noteController.text : null,
        createdAt: DateTime.now(),
        objectId: _selectedObjectId,
        date: _selectedDate ?? DateTime.now(),
      );
      if (isEdit) {
        final updatePenalty = ref.read(updatePenaltyUseCaseProvider);
        await updatePenalty(penalty);
      } else {
        final createPenalty = ref.read(createPenaltyUseCaseProvider);
        await createPenalty(penalty);
      }
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(allPenaltiesProvider);
        ref.invalidate(employeeAggregatedBalanceProvider);
        ref.invalidate(payrollPayoutsByMonthProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Штраф обновлён' : 'Штраф добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка:  ${e.toString()}')),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
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
                              widget.penalty == null ? 'Добавить штраф' : 'Редактировать штраф',
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
                              validator: (value) => _selectedEmployeeId == null ? 'Обязательное поле' : null,
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
                              validator: (value) => _selectedObjectId == null ? 'Обязательное поле' : null,
                              allowCustomValues: false,
                            ),
                            const SizedBox(height: 16),
                            // Сумма
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Сумма штрафа',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_ruble),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Обязательное поле';
                                final num? val = num.tryParse(value.replaceAll(',', '.'));
                                if (val == null || val <= 0) return 'Некорректная сумма';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Примечание
                            TextFormField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Комментарий',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.comment_outlined),
                              ),
                              minLines: 1,
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
                            onPressed: _isSaving ? null : _savePenalty,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(widget.penalty == null ? 'Сохранить' : 'Обновить'),
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
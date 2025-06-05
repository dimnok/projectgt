import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/payroll_filter_provider.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:collection/collection.dart';
import '../providers/payroll_providers.dart';
import '../providers/balance_providers.dart';
import '../../data/models/payroll_payout_model.dart';
import 'payroll_payout_amount_modal.dart';

/// Модальное окно для создания/редактирования выплаты
class PayrollPayoutFormModal extends ConsumerStatefulWidget {
  /// Выплата для редактирования (null для создания новой)
  final PayrollPayoutModel? payout;

  const PayrollPayoutFormModal({
    super.key,
    this.payout,
  });

  @override
  ConsumerState<PayrollPayoutFormModal> createState() => _PayrollPayoutFormModalState();
}

class _PayrollPayoutFormModalState extends ConsumerState<PayrollPayoutFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  
  // Для редактирования - одиночный выбор
  final _singleEmployeeController = SingleValueDropDownController();
  
  // Для создания - множественный выбор
  final _multiEmployeeController = MultiValueDropDownController();
  
  final _isSaving = ValueNotifier<bool>(false);
  
  String? _selectedEmployeeId; // Для редактирования
  List<String> _selectedEmployeeIds = []; // Для создания
  DateTime? _selectedDate;
  String _method = 'cash';
  String _type = 'salary'; // Добавляем тип оплаты

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
    _selectedEmployeeId = payout.employeeId;
    _amountController.text = payout.amount.toString();
    _selectedDate = payout.payoutDate;
    _method = payout.method;
    _type = payout.type; // Инициализируем тип при редактировании
  }

  @override
  void dispose() {
    _commentController.dispose();
    _amountController.dispose();
    _singleEmployeeController.dispose();
    _multiEmployeeController.dispose();
    _isSaving.dispose();
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _proceedToNextStep() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (isEditing) {
      // Для редактирования - сохраняем как раньше
      await _saveEditedPayout();
    } else {
      // Для создания - переходим ко второму этапу
      await _proceedToBulkAmountSelection();
    }
  }

  Future<void> _saveEditedPayout() async {
    if (_selectedEmployeeId == null) {
      return;
    }
    
    _isSaving.value = true;
    
    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      
        final updatedPayout = widget.payout!.copyWith(
          employeeId: _selectedEmployeeId!,
          amount: amount,
          payoutDate: _selectedDate!,
          method: _method,
        type: _type, // Добавляем тип при обновлении
        );
        
        final updateUseCase = ref.read(updatePayoutUseCaseProvider);
        await updateUseCase(updatedPayout);
      
      // Обновляем провайдеры
      ref.invalidate(filteredPayrollPayoutsProvider);
      ref.invalidate(employeeAggregatedBalanceProvider);
      ref.invalidate(payrollPayoutsByMonthProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выплата обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _proceedToBulkAmountSelection() async {
    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одного сотрудника')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату выплаты')),
      );
      return;
    }

    // Получаем выбранных сотрудников
    final filterState = ref.read(payrollFilterProvider);
    final allEmployees = filterState.employees;
    final selectedEmployees = allEmployees
        .where((emp) => _selectedEmployeeIds.contains(emp.id))
        .toList();

    if (selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось найти выбранных сотрудников')),
      );
      return;
    }

    // Открываем второй модал
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
        ),
        builder: (ctx) => PayrollPayoutAmountModal(
          selectedEmployees: selectedEmployees,
          payoutDate: _selectedDate!,
          method: _method,
          type: _type, // Передаем тип во второй модал
          comment: _commentController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollFilterProvider);
    final employees = filterState.employees;
    final employeeDropDownList = employees.map((e) {
      final fio = [e.lastName, e.firstName, if (e.middleName != null && e.middleName.isNotEmpty) e.middleName].join(' ');
      return DropDownValueModel(name: fio, value: e.id);
    }).toList();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Устанавливаем начальное значение для dropdown при редактировании
    if (isEditing && _selectedEmployeeId != null) {
      final selectedEmployee = employeeDropDownList.firstWhereOrNull((e) => e.value == _selectedEmployeeId);
      if (selectedEmployee != null) {
        _singleEmployeeController.setDropDown(selectedEmployee);
      }
    }
    
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
                              isEditing ? 'Редактировать выплату' : 'Массовые выплаты',
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
                    
                    if (!isEditing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Этап 1 из 2: Выберите сотрудников, дату и способ выплаты',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
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
                            // Дата выплаты
                            GestureDetector(
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
                                  validator: (_) => _selectedDate == null ? 'Выберите дату' : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Выбор сотрудников
                            if (isEditing)
                              // Для редактирования - одиночный выбор
                            DropDownTextField(
                                controller: _singleEmployeeController,
                              dropDownList: employeeDropDownList,
                              listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
                              textFieldDecoration: const InputDecoration(
                                labelText: 'Сотрудник',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                if (val is DropDownValueModel) {
                                  setState(() {
                                    _selectedEmployeeId = val.value as String;
                                  });
                                }
                              },
                              validator: (val) => _selectedEmployeeId == null ? 'Выберите сотрудника' : null,
                              )
                            else
                              // Для создания - множественный выбор
                              DropDownTextField.multiSelection(
                                controller: _multiEmployeeController,
                                dropDownList: employeeDropDownList,
                                submitButtonText: 'Ок',
                                submitButtonColor: Colors.green,
                                checkBoxProperty: CheckBoxProperty(
                                  fillColor: WidgetStateProperty.all<Color>(Colors.green),
                                  checkColor: Colors.white,
                                ),
                                displayCompleteItem: true,
                                textFieldDecoration: const InputDecoration(
                                  labelText: 'Сотрудники',
                                  hintText: 'Выберите одного или несколько сотрудников',
                                  border: OutlineInputBorder(),
                                ),
                                listTextStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
                                onChanged: (val) {
                                  if (val == null) return;
                                  final list = val is List<DropDownValueModel> 
                                      ? val 
                                      : List<DropDownValueModel>.from(val);
                                  _selectedEmployeeIds = list
                                      .map((e) => e.value as String?)
                                      .where((value) => value != null)
                                      .cast<String>()
                                      .toList();
                                },
                              ),
                            
                            const SizedBox(height: 16),
                            
                            // Сумма выплаты (только для редактирования)
                            if (isEditing) ...[
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Сумма выплаты',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_ruble),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Введите сумму';
                                final amount = double.tryParse(val.replaceAll(',', '.'));
                                if (amount == null || amount <= 0) return 'Введите корректную сумму';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            ],
                            
                            // Способ выплаты
                            DropdownButtonFormField<String>(
                              value: _method,
                              decoration: const InputDecoration(
                                labelText: 'Способ',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'card', child: Text('Карта')),
                                DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                                DropdownMenuItem(value: 'bank_transfer', child: Text('Банковский перевод')),
                              ],
                              onChanged: (val) => setState(() => _method = val ?? 'cash'),
                            ),
                            const SizedBox(height: 16),
                            
                            // Тип оплаты
                            DropdownButtonFormField<String>(
                              value: _type,
                              decoration: const InputDecoration(
                                labelText: 'Тип оплаты',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'salary', child: Text('Зарплата')),
                                DropdownMenuItem(value: 'advance', child: Text('Аванс')),
                              ],
                              onChanged: (val) => setState(() => _type = val ?? 'salary'),
                            ),
                            const SizedBox(height: 16),
                            
                            // Комментарий
                            TextFormField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                labelText: 'Комментарий',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.comment_outlined),
                              ),
                              maxLines: 2,
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
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _isSaving,
                            builder: (context, isSaving, child) {
                              return ElevatedButton(
                                onPressed: isSaving ? null : _proceedToNextStep,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                child: isSaving
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(isEditing ? 'Сохранить' : 'Далее'),
                              );
                            },
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
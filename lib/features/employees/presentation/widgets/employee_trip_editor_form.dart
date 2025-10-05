import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:uuid/uuid.dart';

/// Форма для добавления/редактирования суточных выплат сотрудника.
///
/// Позволяет настроить ставку суточных для конкретного сотрудника
/// с указанием объекта, суммы и минимального количества часов.
class EmployeeTripEditorForm extends ConsumerStatefulWidget {
  /// Сотрудник, для которого настраиваются суточные.
  final Employee employee;

  /// Существующая ставка для редактирования (опционально).
  final BusinessTripRate? existingRate;

  /// Callback при успешном сохранении.
  final VoidCallback? onSaved;

  /// Конструктор [EmployeeTripEditorForm].
  const EmployeeTripEditorForm({
    super.key,
    required this.employee,
    this.existingRate,
    this.onSaved,
  });

  @override
  ConsumerState<EmployeeTripEditorForm> createState() =>
      _EmployeeTripEditorFormState();
}

class _EmployeeTripEditorFormState
    extends ConsumerState<EmployeeTripEditorForm> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей формы
  final _rateController = TextEditingController();
  final _minimumHoursController = TextEditingController();

  // Выбранные значения
  ObjectEntity? _selectedObject;
  DateTime _validFrom = DateTime.now();
  DateTime? _validTo;

  // Состояние загрузки
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _minimumHoursController.dispose();
    super.dispose();
  }

  /// Инициализация формы с существующими данными.
  void _initializeForm() {
    if (widget.existingRate != null) {
      final rate = widget.existingRate!;
      _rateController.text = rate.rate.toString();
      _minimumHoursController.text = rate.minimumHours.toString();
      _validFrom = rate.validFrom;
      _validTo = rate.validTo;
      // Для объекта потребуется загрузка из провайдера
    }
  }

  /// Обработка сохранения формы.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedObject == null) {
      SnackBarUtils.showError(context, 'Выберите объект');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rate = BusinessTripRate(
        id: widget.existingRate?.id ?? const Uuid().v4(),
        objectId: _selectedObject!.id,
        employeeId: widget.employee.id,
        rate: double.parse(_rateController.text),
        minimumHours: double.parse(_minimumHoursController.text),
        validFrom: _validFrom,
        validTo: _validTo,
      );

      final createUseCase = ref.read(createBusinessTripRateUseCaseProvider);
      await createUseCase(rate);

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Суточные сохранены');
        widget.onSaved?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка сохранения: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final objectsState = ref.watch(objectProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Суточные для ${widget.employee.firstName} ${widget.employee.lastName}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Выбор объекта
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GTDropdown<ObjectEntity>(
                        items: objectsState.objects,
                        itemDisplayBuilder: (object) => object.name,
                        selectedItem: _selectedObject,
                        onSelectionChanged: (value) {
                          setState(() {
                            _selectedObject = value;
                          });
                        },
                        labelText: 'Объект работы',
                        hintText: 'Выберите объект',
                        allowClear: false,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Выберите объект'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Настройки ставки
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Настройки выплат',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Сумма командировочных
                      TextFormField(
                        controller: _rateController,
                        decoration: const InputDecoration(
                          labelText: 'Сумма суточных (₽/смена)',
                          hintText: 'Введите сумму',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите сумму';
                          }
                          final number = double.tryParse(value);
                          if (number == null || number < 0) {
                            return 'Введите корректную сумму';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Минимальные часы
                      TextFormField(
                        controller: _minimumHoursController,
                        decoration: const InputDecoration(
                          labelText: 'Минимум часов для начисления',
                          hintText: 'Например: 5',
                          border: OutlineInputBorder(),
                          helperText:
                              'Суточные будут начислены только если сотрудник отработал не менее указанного количества часов',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите минимальное количество часов';
                          }
                          final number = double.tryParse(value);
                          if (number == null || number < 0) {
                            return 'Введите корректное значение';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Период действия
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Период действия',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Дата начала
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Действует с'),
                        subtitle: Text(
                          '${_validFrom.day.toString().padLeft(2, '0')}.${_validFrom.month.toString().padLeft(2, '0')}.${_validFrom.year}',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _validFrom,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _validFrom = date;
                            });
                          }
                        },
                      ),

                      // Дата окончания (опционально)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: const Text('Действует до'),
                        subtitle: Text(
                          _validTo != null
                              ? '${_validTo!.day.toString().padLeft(2, '0')}.${_validTo!.month.toString().padLeft(2, '0')}.${_validTo!.year}'
                              : 'Бессрочно',
                        ),
                        trailing: _validTo != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _validTo = null;
                                  });
                                },
                              )
                            : null,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _validTo ??
                                _validFrom.add(const Duration(days: 365)),
                            firstDate: _validFrom,
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _validTo = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Кнопки управления
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CupertinoActivityIndicator(),
                            )
                          : const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

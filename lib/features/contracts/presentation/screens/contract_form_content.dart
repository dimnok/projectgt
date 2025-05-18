import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/contract.dart';

/// Контент формы создания/редактирования договора.
///
/// Используется для отображения, валидации и управления всеми полями договора, включая выбор контрагента, объекта, дат, суммы и статуса.
/// Позволяет переиспользовать UI для создания и редактирования договоров.
///
/// Пример использования:
/// ```dart
/// ContractFormContent(
///   isNew: true,
///   isLoading: false,
///   numberController: ..., // инициализированный TextEditingController
///   ...
/// )
/// ```
class ContractFormContent extends StatelessWidget {
  /// Является ли форма созданием нового договора (`true`) или редактированием (`false`).
  final bool isNew;
  /// Флаг загрузки состояния (блокирует поля и кнопки).
  final bool isLoading;
  /// Контроллер для поля "Номер договора".
  final TextEditingController numberController;
  /// Контроллер для поля "Сумма".
  final TextEditingController amountController;
  /// Дата заключения договора.
  final DateTime? date;
  /// Дата окончания действия договора.
  final DateTime? endDate;
  /// ID выбранного контрагента.
  final String? selectedContractorId;
  /// ID выбранного объекта.
  final String? selectedObjectId;
  /// Статус договора (активен, приостановлен, завершён).
  final ContractStatus status;
  /// Ключ формы для валидации.
  final GlobalKey<FormState> formKey;
  /// Колбэк для сохранения формы.
  final VoidCallback onSave;
  /// Колбэк для отмены/закрытия формы.
  final VoidCallback onCancel;
  /// Колбэк при изменении даты договора.
  final ValueChanged<DateTime> onDateChanged;
  /// Колбэк при изменении даты окончания.
  final ValueChanged<DateTime?> onEndDateChanged;
  /// Колбэк при изменении выбранного контрагента.
  final ValueChanged<String?> onContractorChanged;
  /// Колбэк при изменении выбранного объекта.
  final ValueChanged<String?> onObjectChanged;
  /// Колбэк при изменении статуса договора.
  final ValueChanged<ContractStatus?> onStatusChanged;
  /// Список элементов для выпадающего списка контрагентов.
  final List<DropdownMenuItem<String>> contractorItems;
  /// Список элементов для выпадающего списка объектов.
  final List<DropdownMenuItem<String>> objectItems;

  /// Конструктор [ContractFormContent]. Все параметры обязательны.
  const ContractFormContent({
    super.key,
    required this.isNew,
    required this.isLoading,
    required this.numberController,
    required this.amountController,
    required this.date,
    required this.endDate,
    required this.selectedContractorId,
    required this.selectedObjectId,
    required this.status,
    required this.formKey,
    required this.onSave,
    required this.onCancel,
    required this.onDateChanged,
    required this.onEndDateChanged,
    required this.onContractorChanged,
    required this.onObjectChanged,
    required this.onStatusChanged,
    required this.contractorItems,
    required this.objectItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Form(
          key: formKey,
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
                        isNew ? 'Новый договор' : 'Редактировать договор',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: onCancel,
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
                    color: theme.colorScheme.outline.withAlpha(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Данные договора', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Номер договора
                      TextFormField(
                        controller: numberController,
                        decoration: const InputDecoration(
                          labelText: 'Номер договора *',
                          hintText: 'Введите номер',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Введите номер' : null,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),
                      // Дата договора
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Дата договора *',
                              ),
                              child: InkWell(
                                onTap: isLoading ? null : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: date ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) onDateChanged(picked);
                                },
                                child: Text(
                                  date != null ? _formatDate(date!) : 'Выбрать дату',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Дата окончания',
                              ),
                              child: InkWell(
                                onTap: isLoading ? null : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: endDate ?? date ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  onEndDateChanged(picked);
                                },
                                child: Text(
                                  endDate != null ? _formatDate(endDate!) : 'Выбрать дату',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Контрагент
                      DropdownButtonFormField<String>(
                        value: selectedContractorId,
                        items: contractorItems,
                        onChanged: isLoading ? null : onContractorChanged,
                        decoration: const InputDecoration(
                          labelText: 'Контрагент *',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Выберите контрагента' : null,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 16),
                      // Объект
                      DropdownButtonFormField<String>(
                        value: selectedObjectId,
                        items: objectItems,
                        onChanged: isLoading ? null : onObjectChanged,
                        decoration: const InputDecoration(
                          labelText: 'Объект *',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Выберите объект' : null,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 16),
                      // Сумма
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Сумма *',
                          hintText: 'Введите сумму',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Введите сумму';
                          final value = double.tryParse(v.replaceAll(',', '.'));
                          if (value == null || value < 0) return 'Некорректная сумма';
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),
                      // Статус
                      DropdownButtonFormField<ContractStatus>(
                        value: status,
                        items: const [
                          DropdownMenuItem(value: ContractStatus.active, child: Text('В работе')),
                          DropdownMenuItem(value: ContractStatus.suspended, child: Text('Приостановлен')),
                          DropdownMenuItem(value: ContractStatus.completed, child: Text('Завершен')),
                        ],
                        onChanged: isLoading ? null : onStatusChanged,
                        decoration: const InputDecoration(
                          labelText: 'Статус *',
                        ),
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
                      onPressed: onCancel,
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
                      onPressed: isLoading ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isNew ? 'Создать' : 'Сохранить'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Форматирует дату в строку вида ДД.ММ.ГГГГ для отображения в UI.
  ///
  /// [date] — дата для форматирования.
  ///
  /// Возвращает строку в формате "дд.мм.гггг".
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
} 
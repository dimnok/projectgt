import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';

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

  /// Контроллер для поля "Ставка НДС (%)".
  final TextEditingController vatRateController;

  /// Включен ли НДС в стоимость.
  final bool isVatIncluded;

  /// Контроллер для поля "НДС (сумма)".
  final TextEditingController vatAmountController;

  /// Контроллер для поля "Аванс".
  final TextEditingController advanceAmountController;

  /// Контроллер для поля "Гарантийные удержания".
  final TextEditingController warrantyRetentionAmountController;

  /// Контроллер для поля "Процент гарантийных удержаний".
  final TextEditingController warrantyRetentionRateController;

  /// Контроллер для поля "Срок гарантийных обязательств".
  final TextEditingController warrantyPeriodMonthsController;

  /// Контроллер для поля "Генподрядные".
  final TextEditingController generalContractorFeeAmountController;

  /// Контроллер для поля "Процент генподрядных".
  final TextEditingController generalContractorFeeRateController;

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

  /// Колбэк при изменении настройки включения НДС.
  final ValueChanged<bool> onVatIncludedChanged;

  /// Список элементов для выпадающего списка контрагентов.
  final Map<String, String> contractorItems;

  /// Список элементов для выпадающего списка объектов.
  final Map<String, String> objectItems;

  /// Конструктор [ContractFormContent]. Все параметры обязательны.
  const ContractFormContent({
    super.key,
    required this.isNew,
    required this.isLoading,
    required this.numberController,
    required this.amountController,
    required this.vatRateController,
    required this.isVatIncluded,
    required this.vatAmountController,
    required this.advanceAmountController,
    required this.warrantyRetentionAmountController,
    required this.warrantyRetentionRateController,
    required this.warrantyPeriodMonthsController,
    required this.generalContractorFeeAmountController,
    required this.generalContractorFeeRateController,
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
    required this.onVatIncludedChanged,
    required this.contractorItems,
    required this.objectItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
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
              Text('Данные договора',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
                      // Номер договора
                      TextFormField(
                        controller: numberController,
                        decoration: const InputDecoration(
                          labelText: 'Номер договора *',
                          hintText: 'Введите номер',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Введите номер'
                            : null,
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
                                onTap: isLoading
                                    ? null
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: date ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          onDateChanged(picked);
                                        }
                                      },
                                child: Text(
                                  date != null
                                      ? _formatDate(date!)
                                      : 'Выбрать дату',
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
                                onTap: isLoading
                                    ? null
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              endDate ?? date ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        onEndDateChanged(picked);
                                      },
                                child: Text(
                                  endDate != null
                                      ? _formatDate(endDate!)
                                      : 'Выбрать дату',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Контрагент
                      GTDropdown<MapEntry<String, String>>(
                        items: contractorItems.entries.toList(),
                        itemDisplayBuilder: (entry) => entry.value,
                        selectedItem: selectedContractorId != null && contractorItems.containsKey(selectedContractorId)
                            ? MapEntry(selectedContractorId!, contractorItems[selectedContractorId]!)
                            : null,
                        onSelectionChanged: (entry) => onContractorChanged(entry?.key),
                        labelText: 'Контрагент *',
                        hintText: 'Выберите контрагента',
                        allowClear: false,
                        readOnly: isLoading,
                        validator: (v) => selectedContractorId == null || selectedContractorId!.isEmpty
                            ? 'Выберите контрагента'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Объект
                      GTDropdown<MapEntry<String, String>>(
                        items: objectItems.entries.toList(),
                        itemDisplayBuilder: (entry) => entry.value,
                        selectedItem: selectedObjectId != null && objectItems.containsKey(selectedObjectId)
                            ? MapEntry(selectedObjectId!, objectItems[selectedObjectId]!)
                            : null,
                        onSelectionChanged: (entry) => onObjectChanged(entry?.key),
                        labelText: 'Объект *',
                        hintText: 'Выберите объект',
                        allowClear: false,
                        readOnly: isLoading,
                        validator: (v) => selectedObjectId == null || selectedObjectId!.isEmpty
                            ? 'Выберите объект'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Сумма
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Сумма *',
                          hintText: 'Введите сумму',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Введите сумму';
                          }
                          final value = double.tryParse(v.replaceAll(',', '.'));
                          if (value == null || value < 0) {
                            return 'Некорректная сумма';
                          }
                          return null;
                        },
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),
                      // НДС
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: vatRateController,
                              decoration: const InputDecoration(
                                labelText: 'Ставка НДС (%)',
                                hintText: '20',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              enabled: !isLoading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: vatAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Сумма НДС',
                                hintText: '0.00',
                              ),
                              readOnly: true, // Рассчитывается автоматически
                              enabled: !isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('НДС включен в стоимость'),
                        value: isVatIncluded,
                        onChanged: isLoading ? null : onVatIncludedChanged,
                      ),
                      const SizedBox(height: 16),
                      // Аванс
                      TextFormField(
                        controller: advanceAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Сумма аванса',
                          hintText: '0.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),
                      // Гарантийные удержания
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: warrantyRetentionRateController,
                              decoration: const InputDecoration(
                                labelText: 'Гарантийные удержания (%)',
                                hintText: '5',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              enabled: !isLoading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: warrantyPeriodMonthsController,
                              decoration: const InputDecoration(
                                labelText: 'Срок гарантии (мес.)',
                                hintText: '12',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(),
                              enabled: !isLoading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: warrantyRetentionAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Сумма удержания',
                                hintText: '0.00',
                              ),
                              readOnly: true, // Только для отображения
                              enabled: !isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Генподрядные
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: generalContractorFeeRateController,
                              decoration: const InputDecoration(
                                labelText: 'Генподрядные (%)',
                                hintText: '3',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              enabled: !isLoading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: generalContractorFeeAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Сумма генподрядных',
                                hintText: '0.00',
                              ),
                              readOnly: true, // Только для отображения
                              enabled: !isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Статус
                      GTDropdown<ContractStatus>(
                        items: const [
                          ContractStatus.active,
                          ContractStatus.suspended,
                          ContractStatus.completed,
                        ],
                        itemDisplayBuilder: (status) {
                          switch (status) {
                            case ContractStatus.active:
                              return 'В работе';
                            case ContractStatus.suspended:
                              return 'Приостановлен';
                            case ContractStatus.completed:
                              return 'Завершен';
                          }
                        },
                        selectedItem: status,
                        onSelectionChanged: onStatusChanged,
                        labelText: 'Статус *',
                        hintText: 'Выберите статус',
                        allowClear: false,
                        readOnly: isLoading,
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
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CupertinoActivityIndicator(),
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

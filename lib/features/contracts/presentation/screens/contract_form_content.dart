import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';

/// Контент формы создания/редактирования договора.
///
/// Используется для отображения, валидации и управления всеми полями договора, включая выбор контрагента, объекта, дат, суммы и статуса.
/// Позволяет переиспользовать UI для создания и редактирования договоров.
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

  /// Контроллер для поля "Наименование организации" подрядчика.
  final TextEditingController contractorLegalNameController;

  /// Контроллер для поля "Должность" представителя подрядчика.
  final TextEditingController contractorPositionController;

  /// Контроллер для поля "ФИО Подписанта" со стороны подрядчика.
  final TextEditingController contractorSignerController;

  /// Контроллер для поля "Наименование организации" заказчика.
  final TextEditingController customerLegalNameController;

  /// Контроллер для поля "Должность" представителя заказчика.
  final TextEditingController customerPositionController;

  /// Контроллер для поля "ФИО Подписанта" со стороны заказчика.
  final TextEditingController customerSignerController;

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

  /// Показывать ли заголовок формы (используется, когда форма не в модальном окне).
  final bool showHeader;

  /// Показывать ли кнопки в футере (используется, когда форма не в модальном окне).
  final bool showFooter;

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
    required this.contractorLegalNameController,
    required this.contractorPositionController,
    required this.contractorSignerController,
    required this.customerLegalNameController,
    required this.customerPositionController,
    required this.customerSignerController,
    required this.date,
    required this.endDate,
    required this.selectedContractorId,
    required this.selectedObjectId,
    required this.status,
    this.showHeader = true,
    this.showFooter = true,
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
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
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
          ],
          const GTSectionTitle(title: 'Данные договора'),
          const SizedBox(height: 16),
          // Номер договора
          GTTextField(
            controller: numberController,
            labelText: 'Номер договора *',
            hintText: 'Введите номер',
            prefixIcon: CupertinoIcons.doc_text,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Введите номер' : null,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          // Даты договора
          Row(
            children: [
              Expanded(
                child: GTTextField(
                  labelText: 'Дата заключения *',
                  hintText: 'Выберите дату',
                  readOnly: true,
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
                  controller: TextEditingController(
                    text: date != null ? formatRuDate(date!) : '',
                  ),
                  prefixIcon: CupertinoIcons.calendar,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  labelText: 'Дата окончания',
                  hintText: 'Выберите дату',
                  readOnly: true,
                  onTap: isLoading
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? date ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          onEndDateChanged(picked);
                        },
                  controller: TextEditingController(
                    text: endDate != null ? formatRuDate(endDate!) : '',
                  ),
                  prefixIcon: CupertinoIcons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Контрагент
          GTDropdown<MapEntry<String, String>>(
            items: contractorItems.entries.toList(),
            itemDisplayBuilder: (entry) => entry.value,
            selectedItem: selectedContractorId != null &&
                    contractorItems.containsKey(selectedContractorId)
                ? MapEntry(selectedContractorId!,
                    contractorItems[selectedContractorId]!)
                : null,
            onSelectionChanged: (entry) => onContractorChanged(entry?.key),
            labelText: 'Контрагент *',
            hintText: 'Выберите контрагента',
            prefixIcon: CupertinoIcons.person_2,
            allowClear: false,
            readOnly: isLoading,
            validator: (v) =>
                selectedContractorId == null || selectedContractorId!.isEmpty
                    ? 'Выберите контрагента'
                    : null,
          ),
          const SizedBox(height: 16),
          // Объект
          GTDropdown<MapEntry<String, String>>(
            items: objectItems.entries.toList(),
            itemDisplayBuilder: (entry) => entry.value,
            selectedItem: selectedObjectId != null &&
                    objectItems.containsKey(selectedObjectId)
                ? MapEntry(selectedObjectId!, objectItems[selectedObjectId]!)
                : null,
            onSelectionChanged: (entry) => onObjectChanged(entry?.key),
            labelText: 'Объект *',
            hintText: 'Выберите объект',
            prefixIcon: CupertinoIcons.building_2_fill,
            allowClear: false,
            readOnly: isLoading,
            validator: (v) =>
                selectedObjectId == null || selectedObjectId!.isEmpty
                    ? 'Выберите объект'
                    : null,
          ),
          const SizedBox(height: 16),
          // Сумма
          GTTextField(
            controller: amountController,
            labelText: 'Сумма договора *',
            hintText: '0.00',
            suffixText: '₽',
            prefixIcon: CupertinoIcons.money_rubl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [amountFormatter()],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Введите сумму';
              }
              final value = parseAmount(v);
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
                child: GTTextField(
                  controller: vatRateController,
                  labelText: 'Ставка НДС (%)',
                  hintText: '20',
                  prefixIcon: CupertinoIcons.percent,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  controller: vatAmountController,
                  labelText: 'Сумма НДС',
                  hintText: '0.00',
                  suffixText: '₽',
                  readOnly: true, // Рассчитывается автоматически
                  enabled: !isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: isLoading ? null : () => onVatIncludedChanged(!isVatIncluded),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'НДС включен в стоимость',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch.adaptive(
                    value: isVatIncluded,
                    onChanged: isLoading ? null : onVatIncludedChanged,
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Аванс
          GTTextField(
            controller: advanceAmountController,
            labelText: 'Сумма аванса',
            hintText: '0.00',
            suffixText: '₽',
            prefixIcon: CupertinoIcons.creditcard,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [amountFormatter()],
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          // Гарантийные удержания
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GTTextField(
                  controller: warrantyRetentionRateController,
                  labelText: 'Удержания (%)',
                  hintText: '5',
                  prefixIcon: CupertinoIcons.shield,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  controller: warrantyPeriodMonthsController,
                  labelText: 'Срок (мес.)',
                  hintText: '12',
                  keyboardType: const TextInputType.numberWithOptions(),
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  controller: warrantyRetentionAmountController,
                  labelText: 'Сумма',
                  hintText: '0.00',
                  suffixText: '₽',
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
                child: GTTextField(
                  controller: generalContractorFeeRateController,
                  labelText: 'Генподрядные (%)',
                  hintText: '3',
                  prefixIcon: CupertinoIcons.briefcase,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTTextField(
                  controller: generalContractorFeeAmountController,
                  labelText: 'Сумма генподрядных',
                  hintText: '0.00',
                  suffixText: '₽',
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
            prefixIcon: CupertinoIcons.info,
            allowClear: false,
            readOnly: isLoading,
          ),
          const SizedBox(height: 24),

          const GTSectionTitle(title: 'Подрядчик (Исполнитель)'),
          const SizedBox(height: 16),
          GTTextField(
            controller: contractorLegalNameController,
            labelText: 'Наименование организации',
            hintText: 'ООО "ГТ-Строй"',
            prefixIcon: CupertinoIcons.house,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GTTextField(
                  controller: contractorPositionController,
                  labelText: 'Должность',
                  hintText: 'Генеральный директор',
                  prefixIcon: CupertinoIcons.person_badge_plus,
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: GTTextField(
                  controller: contractorSignerController,
                  labelText: 'ФИО Подписанта',
                  hintText: 'Иванов И.И.',
                  prefixIcon: CupertinoIcons.person,
                  enabled: !isLoading,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const GTSectionTitle(title: 'Заказчик (Клиент)'),
          const SizedBox(height: 16),
          GTTextField(
            controller: customerLegalNameController,
            labelText: 'Наименование организации',
            hintText: 'АО "Заказчик-Групп"',
            prefixIcon: CupertinoIcons.house_alt,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GTTextField(
                  controller: customerPositionController,
                  labelText: 'Должность',
                  hintText: 'Технический директор',
                  prefixIcon: CupertinoIcons.person_badge_plus,
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: GTTextField(
                  controller: customerSignerController,
                  labelText: 'ФИО Подписанта',
                  hintText: 'Петров П.П.',
                  prefixIcon: CupertinoIcons.person,
                  enabled: !isLoading,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          if (showFooter) ...[
            const Divider(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GTSecondaryButton(
                    text: 'Отмена',
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GTPrimaryButton(
                    text: isNew ? 'Создать' : 'Сохранить',
                    onPressed: isLoading ? null : onSave,
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

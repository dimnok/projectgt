import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';

/// Контент формы данных компании.
///
/// Содержит все поля ввода и логику их адаптивного расположения.
class CompanyFormContent extends StatelessWidget {
  /// Признак отображения в десктопном режиме.
  final bool isDesktop;

  /// Состояние загрузки данных.
  final bool isLoading;

  /// Состояние процесса поиска по ИНН.
  final bool isSearching;

  // Контроллеры
  /// Контроллер для полного наименования компании.
  final TextEditingController nameFullController;

  /// Контроллер для краткого наименования компании.
  final TextEditingController nameShortController;

  /// Контроллер для ИНН.
  final TextEditingController innController;

  /// Контроллер для КПП.
  final TextEditingController kppController;

  /// Контроллер для ОГРН.
  final TextEditingController ogrnController;

  /// Контроллер для ОКПО.
  final TextEditingController okpoController;

  /// Контроллер для юридического адреса.
  final TextEditingController legalAddressController;

  /// Контроллер для фактического адреса.
  final TextEditingController actualAddressController;

  /// Контроллер для ФИО руководителя.
  final TextEditingController directorNameController;

  /// Контроллер для должности руководителя.
  final TextEditingController directorPositionController;

  /// Контроллер для основания полномочий руководителя.
  final TextEditingController directorBasisController;

  /// Контроллер для телефона руководителя.
  final TextEditingController directorPhoneController;

  /// Контроллер для ФИО главного бухгалтера.
  final TextEditingController chiefAccountantNameController;

  /// Контроллер для телефона главного бухгалтера.
  final TextEditingController chiefAccountantPhoneController;

  /// Контроллер для контактного лица.
  final TextEditingController contactPersonController;

  /// Контроллер для адреса веб-сайта.
  final TextEditingController websiteController;

  /// Контроллер для электронной почты.
  final TextEditingController emailController;

  /// Контроллер для телефона компании.
  final TextEditingController phoneController;

  /// Контроллер для описания сферы деятельности.
  final TextEditingController activityDescriptionController;

  /// Контроллер для системы налогообложения.
  final TextEditingController taxationSystemController;

  /// Контроллер для ставки НДС.
  final TextEditingController vatRateController;

  /// Является ли компания плательщиком НДС.
  final bool isVatPayer;

  /// Коллбэк изменения статуса плательщика НДС.
  final ValueChanged<bool> onVatPayerChanged;

  /// Коллбэк изменения системы налогообложения.
  final ValueChanged<String?> onTaxationSystemChanged;

  /// Коллбэк для запуска поиска данных по ИНН.
  final VoidCallback onSearchByInn;

  /// Список систем налогообложения, актуальных на 2026 год в РФ.
  static const List<String> taxationSystems = [
    'ОСНО',
    'УСН «Доходы»',
    'УСН «Доходы минус расходы»',
    'АУСН «Доходы»',
    'АУСН «Доходы минус расходы»',
    'ЕСХН',
  ];

  /// Создаёт экземпляр [CompanyFormContent].
  const CompanyFormContent({
    super.key,
    required this.isDesktop,
    required this.isLoading,
    required this.isSearching,
    required this.nameFullController,
    required this.nameShortController,
    required this.innController,
    required this.kppController,
    required this.ogrnController,
    required this.okpoController,
    required this.legalAddressController,
    required this.actualAddressController,
    required this.directorNameController,
    required this.directorPositionController,
    required this.directorBasisController,
    required this.directorPhoneController,
    required this.chiefAccountantNameController,
    required this.chiefAccountantPhoneController,
    required this.contactPersonController,
    required this.websiteController,
    required this.emailController,
    required this.phoneController,
    required this.activityDescriptionController,
    required this.taxationSystemController,
    required this.vatRateController,
    required this.isVatPayer,
    required this.onVatPayerChanged,
    required this.onTaxationSystemChanged,
    required this.onSearchByInn,
  });

  Widget _buildResponsiveRow(List<Widget> children) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SectionTitle(title: 'Поиск по ИНН'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GTTextField(
                controller: innController,
                labelText: 'ИНН организации',
                hintText: '10 или 12 цифр',
                prefixIcon: CupertinoIcons.number,
                enabled: !isLoading && !isSearching,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            GTSecondaryButton(
              text: 'Поиск',
              isLoading: isSearching,
              onPressed: isLoading || isSearching ? null : onSearchByInn,
            ),
          ],
        ),
        const SizedBox(height: 32),

        const _SectionTitle(title: 'Основная информация'),
        const SizedBox(height: 16),
        GTTextField(
          controller: nameFullController,
          labelText: 'Полное наименование',
          enabled: !isLoading,
          validator: (v) =>
              v == null || v.isEmpty ? 'Введите наименование' : null,
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: nameShortController,
          labelText: 'Краткое наименование',
          enabled: !isLoading,
          validator: (v) =>
              v == null || v.isEmpty ? 'Введите краткое наименование' : null,
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: activityDescriptionController,
          labelText: 'Сфера деятельности',
          enabled: !isLoading,
        ),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Юридические данные'),
        const SizedBox(height: 16),
        _buildResponsiveRow([
          GTTextField(
            controller: kppController,
            labelText: 'КПП',
            enabled: !isLoading,
          ),
          GTTextField(
            controller: ogrnController,
            labelText: 'ОГРН',
            enabled: !isLoading,
          ),
        ]),
        const SizedBox(height: 16),
        GTTextField(
          controller: okpoController,
          labelText: 'ОКПО',
          enabled: !isLoading,
        ),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Налогообложение'),
        const SizedBox(height: 16),
        _buildResponsiveRow([
          GTDropdown<String>(
            items: taxationSystems,
            itemDisplayBuilder: (item) => item,
            selectedItem: taxationSystemController.text.isEmpty
                ? null
                : taxationSystems.contains(taxationSystemController.text)
                ? taxationSystemController.text
                : null,
            onSelectionChanged: (value) {
              taxationSystemController.text = value ?? '';
              onTaxationSystemChanged(value);
            },
            labelText: 'Система налогообложения',
            hintText: 'Выберите систему',
            borderRadius: 16,
            readOnly: isLoading,
          ),
          Row(
            children: [
              Expanded(
                child: isVatPayer
                    ? GTTextField(
                        controller: vatRateController,
                        labelText: 'Ставка НДС (%)',
                        keyboardType: TextInputType.number,
                        enabled: !isLoading,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'НДС',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: isVatPayer,
                onChanged: isLoading ? null : onVatPayerChanged,
                activeThumbColor: Colors.green,
                activeTrackColor: Colors.green.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
              ),
            ],
          ),
        ]),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Контакты'),
        const SizedBox(height: 16),
        _buildResponsiveRow([
          GTTextField(
            controller: websiteController,
            labelText: 'Сайт',
            prefixIcon: CupertinoIcons.globe,
            enabled: !isLoading,
          ),
          GTTextField(
            controller: emailController,
            labelText: 'Email',
            prefixIcon: CupertinoIcons.mail,
            enabled: !isLoading,
          ),
        ]),
        const SizedBox(height: 16),
        _buildResponsiveRow([
          GTTextField(
            controller: phoneController,
            labelText: 'Телефон компании',
            prefixIcon: CupertinoIcons.phone,
            enabled: !isLoading,
          ),
          GTTextField(
            controller: contactPersonController,
            labelText: 'Контактное лицо',
            prefixIcon: CupertinoIcons.person_crop_square,
            enabled: !isLoading,
          ),
        ]),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Адреса'),
        const SizedBox(height: 16),
        GTTextField(
          controller: legalAddressController,
          labelText: 'Юридический адрес',
          prefixIcon: CupertinoIcons.location,
          maxLines: 2,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        GTTextField(
          controller: actualAddressController,
          labelText: 'Фактический адрес',
          prefixIcon: CupertinoIcons.location_north,
          maxLines: 2,
          enabled: !isLoading,
        ),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Руководство'),
        const SizedBox(height: 16),
        GTTextField(
          controller: directorNameController,
          labelText: 'ФИО Руководителя',
          prefixIcon: CupertinoIcons.person,
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow([
          GTTextField(
            controller: directorPositionController,
            labelText: 'Должность',
            enabled: !isLoading,
          ),
          GTTextField(
            controller: directorPhoneController,
            labelText: 'Телефон',
            prefixIcon: CupertinoIcons.phone,
            enabled: !isLoading,
          ),
        ]),
        const SizedBox(height: 16),
        GTTextField(
          controller: directorBasisController,
          labelText: 'Основание полномочий',
          hintText: 'Устава, Доверенности...',
          prefixIcon: CupertinoIcons.doc_plaintext,
          enabled: !isLoading,
        ),

        const SizedBox(height: 24),
        const _SectionTitle(title: 'Бухгалтерия'),
        const SizedBox(height: 16),
        _buildResponsiveRow([
          GTTextField(
            controller: chiefAccountantNameController,
            labelText: 'ФИО Главбуха',
            prefixIcon: CupertinoIcons.person_crop_circle,
            enabled: !isLoading,
          ),
          GTTextField(
            controller: chiefAccountantPhoneController,
            labelText: 'Телефон',
            prefixIcon: CupertinoIcons.phone,
            enabled: !isLoading,
          ),
        ]),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.1,
      ),
    );
  }
}

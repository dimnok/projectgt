import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'contractor_bank_accounts_list.dart';

/// Вспомогательный класс для работы с типами контрагентов.
///
/// Предоставляет методы для получения цветов и иконок
/// для различных значений [ContractorType].
class ContractorHelper {
  /// Возвращает цвет, соответствующий типу контрагента, для визуальной индикации.
  static Color typeColor(ContractorType type) {
    switch (type) {
      case ContractorType.customer:
        return Colors.blue;
      case ContractorType.contractor:
        return Colors.green;
      case ContractorType.supplier:
        return Colors.orange;
    }
  }

  /// Возвращает иконку, соответствующую типу контрагента.
  static IconData typeIcon(ContractorType type) {
    switch (type) {
      case ContractorType.customer:
        return CupertinoIcons.briefcase;
      case ContractorType.contractor:
        return CupertinoIcons.hammer;
      case ContractorType.supplier:
        return CupertinoIcons.cube;
    }
  }
}

/// Утилиты для отображения диалоговых окон в модуле контрагентов.
class ContractorDialogs {
  /// Показывает диалог подтверждения удаления.
  static Future<bool?> showConfirmDelete({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    return GTConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      type: GTConfirmationType.danger,
    );
  }
}

/// Виджет аватара/логотипа контрагента.
class ContractorAvatar extends StatelessWidget {
  /// Данные контрагента.
  final Contractor contractor;

  /// Радиус аватара.
  final double radius;

  /// Использовать ли Hero-анимацию.
  final bool useHero;

  /// Создает виджет аватара.
  const ContractorAvatar({
    super.key,
    required this.contractor,
    this.radius = 32,
    this.useHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar = contractor.logoUrl != null && contractor.logoUrl!.isNotEmpty
        ? CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(contractor.logoUrl!),
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              ContractorHelper.typeIcon(contractor.type),
              size: radius * 0.8,
              color: theme.colorScheme.primary,
            ),
          );

    if (useHero) {
      return Hero(tag: 'contractor_avatar_${contractor.id}', child: avatar);
    }

    return avatar;
  }
}

/// Виджет, отображающий все разделы детальной информации контрагента.
class ContractorDetailsSections extends StatelessWidget {
  /// Данные контрагента.
  final Contractor contractor;

  /// Фиксированная ширина метки (для десктопа).
  final double? labelWidth;

  /// Создает список разделов информации.
  const ContractorDetailsSections({
    super.key,
    required this.contractor,
    this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContractorSection(
          title: 'Основная информация',
          items: [
            ContractorInfoRow(
              label: 'Сфера деятельности',
              value: contractor.activityDescription ?? '',
              icon: CupertinoIcons.briefcase,
              labelWidth: labelWidth,
            ),
          ],
        ),
        ContractorSection(
          title: 'Юридические данные',
          items: [
            ContractorInfoRow(
              label: 'ИНН',
              value: contractor.inn,
              icon: CupertinoIcons.number,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'КПП',
              value: contractor.kpp ?? '',
              icon: CupertinoIcons.number,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'ОГРН',
              value: contractor.ogrn ?? '',
              icon: CupertinoIcons.number,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'ОКПО',
              value: contractor.okpo ?? '',
              icon: CupertinoIcons.number,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'Система налогообложения',
              value: contractor.taxationSystem ?? '',
              icon: CupertinoIcons.percent,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'Плательщик НДС',
              value: contractor.isVatPayer
                  ? 'Да (${contractor.vatRate}%)'
                  : 'Нет',
              icon: CupertinoIcons.money_rubl,
              labelWidth: labelWidth,
            ),
          ],
        ),
        ContractorSection(
          title: 'Контакты',
          items: [
            ContractorInfoRow(
              label: 'Телефон компании',
              value: contractor.phone,
              icon: CupertinoIcons.phone,
              labelWidth: labelWidth,
              isActionable: true,
            ),
            ContractorInfoRow(
              label: 'Email',
              value: contractor.email,
              icon: CupertinoIcons.mail,
              labelWidth: labelWidth,
              isActionable: true,
            ),
            ContractorInfoRow(
              label: 'Сайт',
              value: contractor.website ?? '',
              icon: CupertinoIcons.globe,
              labelWidth: labelWidth,
              isActionable: true,
            ),
            ContractorInfoRow(
              label: 'Контактное лицо',
              value: contractor.contactPerson ?? '',
              icon: CupertinoIcons.person_crop_circle,
              labelWidth: labelWidth,
            ),
          ],
        ),
        ContractorSection(
          title: 'Адреса',
          items: [
            ContractorInfoRow(
              label: 'Юридический адрес',
              value: contractor.legalAddress,
              icon: CupertinoIcons.location,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'Фактический адрес',
              value: contractor.actualAddress,
              icon: CupertinoIcons.location_north,
              labelWidth: labelWidth,
            ),
          ],
        ),
        ContractorSection(
          title: 'Руководство и бухгалтерия',
          items: [
            ContractorInfoRow(
              label: 'Генеральный директор',
              value: contractor.director,
              icon: CupertinoIcons.person,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'Телефон директора',
              value: contractor.directorPhone ?? '',
              icon: CupertinoIcons.phone,
              labelWidth: labelWidth,
              isActionable: true,
            ),
            ContractorInfoRow(
              label: 'Основание полномочий',
              value: contractor.directorBasis ?? '',
              icon: CupertinoIcons.doc_plaintext,
              labelWidth: labelWidth,
              isActionable: false,
            ),
            ContractorInfoRow(
              label: 'Главный бухгалтер',
              value: contractor.chiefAccountantName ?? '',
              icon: CupertinoIcons.person_crop_circle_fill,
              labelWidth: labelWidth,
            ),
            ContractorInfoRow(
              label: 'Телефон бухгалтера',
              value: contractor.chiefAccountantPhone ?? '',
              icon: CupertinoIcons.phone,
              labelWidth: labelWidth,
              isActionable: true,
            ),
          ],
        ),
        ContractorBankAccountsList(contractorId: contractor.id),
      ],
    );
  }
}

/// Виджет информационной строки контрагента.
///
/// Унифицированный компонент для отображения пары "Иконка - Метка - Значение".
/// Используется в детальной информации как на мобильных, так и на десктопных экранах.
class ContractorInfoRow extends StatelessWidget {
  /// Иконка поля (опционально).
  final IconData? icon;

  /// Текстовая метка поля.
  final String label;

  /// Значение поля.
  final String value;

  /// Является ли значение интерактивным (например, телефон или email).
  final bool isActionable;

  /// Фиксированная ширина метки для выравнивания на десктопе.
  final double? labelWidth;

  /// Показывать ли разделитель снизу.
  final bool showDivider;

  /// Создает информационную строку.
  const ContractorInfoRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.isActionable = false,
    this.labelWidth,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value.trim().isEmpty ? '—' : value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
              ],
              if (labelWidth != null)
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildValue(theme, displayValue),
                    ],
                  ),
                ),
              if (labelWidth != null) ...[
                const SizedBox(width: 24),
                Expanded(child: _buildValue(theme, displayValue)),
              ],
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: icon != null ? 30 : 0,
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
      ],
    );
  }

  Widget _buildValue(ThemeData theme, String displayValue) {
    return SelectableText(
      displayValue,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: isActionable && value.isNotEmpty
            ? theme.colorScheme.primary
            : null,
      ),
    );
  }
}

/// Виджет заголовка раздела для модуля контрагентов.
///
/// Обертка над базовым стилем заголовков с дополнительными отступами и фоновой подложкой.
class ContractorSection extends StatelessWidget {
  /// Текст заголовка.
  final String title;

  /// Список элементов раздела.
  final List<Widget> items;

  /// Показывать ли фоновую подложку под заголовком.
  final bool showBackground;

  /// Создает раздел информации.
  const ContractorSection({
    super.key,
    required this.title,
    required this.items,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: showBackground
                ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
                : EdgeInsets.zero,
            decoration: showBackground
                ? BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }
}

/// Виджет для отображения элемента детальной информации о контрагенте.
///
/// Представляет собой вертикальную пару "Метка - Значение" с настроенными стилями
/// и поддержкой выделения текста.
class ContractorDetailItem extends StatelessWidget {
  /// Текстовая метка поля.
  final String label;

  /// Значение поля. Если пусто, отображается прочерк.
  final String value;

  /// Создает элемент детальной информации.
  const ContractorDetailItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value.isEmpty ? '—' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

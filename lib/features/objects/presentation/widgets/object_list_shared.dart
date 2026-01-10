import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';

/// Вспомогательный класс для работы с объектами.
class ObjectHelper {
  /// Возвращает иконку для объекта.
  static IconData get icon => Icons.location_city_rounded;

  /// Возвращает цвет для объекта.
  static Color color(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}

/// Утилиты для отображения диалоговых окон в модуле объектов.
class ObjectDialogs {
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

/// Виджет иконки объекта (аватар).
class ObjectAvatar extends StatelessWidget {
  /// Данные объекта.
  final ObjectEntity object;

  /// Радиус аватара.
  final double radius;

  /// Использовать ли Hero-анимацию.
  final bool useHero;

  /// Создает виджет аватара.
  const ObjectAvatar({
    super.key,
    required this.object,
    this.radius = 32,
    this.useHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        ObjectHelper.icon,
        size: radius * 0.8,
        color: theme.colorScheme.primary,
      ),
    );

    if (useHero) {
      return Hero(tag: 'object_avatar_${object.id}', child: avatar);
    }

    return avatar;
  }
}

/// Виджет информационной строки объекта.
class ObjectInfoRow extends StatelessWidget {
  /// Иконка поля (опционально).
  final IconData? icon;

  /// Текстовая метка поля.
  final String label;

  /// Значение поля.
  final String value;

  /// Фиксированная ширина метки для выравнивания на десктопе.
  final double? labelWidth;

  /// Показывать ли разделитель снизу.
  final bool showDivider;

  /// Создает информационную строку.
  const ObjectInfoRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
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
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}

/// Виджет заголовка раздела для модуля объектов.
class ObjectSection extends StatelessWidget {
  /// Текст заголовка.
  final String title;

  /// Список элементов раздела.
  final List<Widget> items;

  /// Показывать ли фоновую подложку под заголовком.
  final bool showBackground;

  /// Создает раздел информации.
  const ObjectSection({
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

/// Виджет, отображающий все разделы детальной информации объекта.
class ObjectDetailsSections extends StatelessWidget {
  /// Данные объекта.
  final ObjectEntity object;

  /// Фиксированная ширина метки (для десктопа).
  final double? labelWidth;

  /// Создает список разделов информации.
  const ObjectDetailsSections({
    super.key,
    required this.object,
    this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ObjectSection(
          title: 'Основная информация',
          items: [
            ObjectInfoRow(
              label: 'Наименование',
              value: object.name,
              icon: Icons.location_city_rounded,
              labelWidth: labelWidth,
            ),
            ObjectInfoRow(
              label: 'Адрес',
              value: object.address,
              icon: Icons.place_outlined,
              labelWidth: labelWidth,
            ),
          ],
        ),
        ObjectSection(
          title: 'Дополнительно',
          items: [
            ObjectInfoRow(
              label: 'Описание',
              value: object.description ?? '',
              icon: CupertinoIcons.doc_text,
              labelWidth: labelWidth,
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

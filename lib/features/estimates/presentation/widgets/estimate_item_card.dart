import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../presentation/widgets/cupertino_dialog_widget.dart';

/// Карточка позиции сметы для мобильного вида
///
/// Отображает подробную информацию о позиции сметы в виде карточки.
/// Поддерживает жесты свайпа для удаления позиции.
class EstimateItemCard extends StatelessWidget {
  /// Позиция сметы для отображения
  final Estimate item;

  /// Обработчик нажатия на карточку (открывает диалог редактирования)
  final void Function(Estimate) onEdit;

  /// Обработчик удаления позиции
  final void Function(String) onDelete;

  /// Обработчик дублирования позиции
  final void Function(Estimate) onDuplicate;

  /// Форматтер для отображения денежных сумм
  final NumberFormat moneyFormat = NumberFormat('###,##0.00', 'ru_RU');

  /// Разрешено ли редактирование
  final bool canEdit;

  /// Разрешено ли удаление
  final bool canDelete;

  /// Разрешено ли дублирование
  final bool canDuplicate;

  /// Создает карточку позиции сметы.
  EstimateItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    this.canEdit = true,
    this.canDelete = true,
    this.canDuplicate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Определяем доступные направления свайпа
    DismissDirection dismissDirection = DismissDirection.none;
    if (canDelete && canDuplicate) {
      dismissDirection = DismissDirection.horizontal;
    } else if (canDelete) {
      dismissDirection = DismissDirection.endToStart;
    } else if (canDuplicate) {
      dismissDirection = DismissDirection.startToEnd;
    }

    return Dismissible(
      key: Key(item.id),
      direction: dismissDirection,
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Icon(
          CupertinoIcons.doc_on_doc,
          color: theme.colorScheme.onPrimaryContainer,
          size: 16,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          CupertinoIcons.trash,
          color: theme.colorScheme.error,
          size: 16,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && canDelete) {
          // Удаление (свайп влево)
          return await CupertinoDialogs.showDeleteConfirmDialog<bool>(
            context: context,
            title: 'Удаление позиции',
            message: 'Вы действительно хотите удалить позицию №${item.number}?',
            onConfirm: () => onDelete(item.id),
          );
        } else if (direction == DismissDirection.startToEnd && canDuplicate) {
          // Дублирование (свайп вправо)
          onDuplicate(item);
          // Возвращаем false, чтобы не удалять карточку из списка после дублирования
          return false;
        }
        return false;
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 30),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: canEdit ? () => onEdit(item) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с номером и системой
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${item.number}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      item.system,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Название
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Подсистема и артикул в одну строку для экономии места
                Row(
                  children: [
                    if (item.subsystem.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.square_grid_2x2,
                              size: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.subsystem,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.article.isNotEmpty && item.subsystem.isNotEmpty)
                      const SizedBox(width: 8),
                    if (item.article.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.qrcode,
                              size: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.article,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Производитель, если есть
                if (item.manufacturer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.building_2_fill,
                          size: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.manufacturer,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 12, thickness: 0.5),

                // Информация о цене, количестве и сумме в одну строку
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${moneyFormat.format(item.price)} ₽',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber,
                      ),
                    ),
                    Text(
                      '${moneyFormat.format(item.total)} ₽',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

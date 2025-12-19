import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../presentation/widgets/cupertino_dialog_widget.dart';
import 'estimate_details_modal.dart';

/// Карточка позиции сметы для мобильного вида
///
/// Отображает подробную информацию о позиции сметы в виде карточки.
/// Поддерживает жесты свайпа для удаления позиции.
class EstimateItemCard extends StatelessWidget {
  /// Позиция сметы для отображения
  final Estimate item;

  /// Данные о выполнении
  final EstimateCompletionModel? completion;

  /// Обработчик редактирования
  final void Function(Estimate) onEdit;

  /// Обработчик удаления позиции
  final void Function(String) onDelete;

  /// Обработчик дублирования позиции
  final void Function(Estimate) onDuplicate;

  /// Форматтер для отображения денежных сумм
  final NumberFormat moneyFormat = NumberFormat('###,##0.00', 'ru_RU');
  final NumberFormat quantityFormat = NumberFormat('###,##0.###', 'ru_RU');

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
    this.completion,
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
    final isDark = theme.brightness == Brightness.dark;
    final completedQuantity = completion?.completedQuantity ?? 0.0;

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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.4 : 0.08,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => EstimateDetailsModal.show(
              context,
              item: item,
              completion: completion,
            ),
            onLongPress: canEdit ? () => onEdit(item) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название верхней строкой: Номер + Наименование
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${item.number} ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              TextSpan(
                                text: item.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.system,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Информация о количестве, цене и выполнении
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Слева: Количество по смете
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Смета',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              '${quantityFormat.format(item.quantity)} ${item.unit}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // По середине: Цена за ед.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Цена ед.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              '${moneyFormat.format(item.price)} ₽',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Справа: Количество сделанного
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Сделано',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              '${quantityFormat.format(completedQuantity)} ${item.unit}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

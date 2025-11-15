import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/inventory/domain/entities/inventory_item.dart';
import 'package:projectgt/features/inventory/presentation/providers/inventory_provider.dart';

/// Данные накладной для отображения.
class ReceiptInfo {
  final String receiptNumber;
  final DateTime receiptDate;

  const ReceiptInfo({
    required this.receiptNumber,
    required this.receiptDate,
  });
}

/// Запись истории движения ТМЦ.
class MovementHistoryItem {
  final DateTime date;
  final String description;

  const MovementHistoryItem({
    required this.date,
    required this.description,
  });
}

/// Провайдер для получения ТМЦ по ID.
final inventoryItemProvider = FutureProvider.family<InventoryItem?, String>(
  (ref, itemId) async {
    final repository = ref.watch(inventoryRepositoryProvider);
    return await repository.getInventoryItem(itemId);
  },
);

/// Провайдер для получения информации о накладной по ID.
final receiptInfoProvider = FutureProvider.family<ReceiptInfo?, String>(
  (ref, receiptId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('inventory_receipts')
          .select('receipt_number, receipt_date')
          .eq('id', receiptId)
          .maybeSingle();

      if (response == null) return null;

      return ReceiptInfo(
        receiptNumber: response['receipt_number'] as String,
        receiptDate: DateTime.parse(response['receipt_date'] as String),
      );
    } catch (e) {
      return null;
    }
  },
);

/// Провайдер для получения истории движений ТМЦ.
final movementHistoryProvider =
    FutureProvider.family<List<MovementHistoryItem>, String>(
  (ref, itemId) async {
    // TODO: Заглушка для примера. Заменить на реальную загрузку из БД
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      MovementHistoryItem(
        date: DateTime(2025, 10, 16),
        description: 'Выдан на объект ЦОД Дубна',
      ),
      MovementHistoryItem(
        date: DateTime(2025, 10, 15),
        description: 'Сдан на склад',
      ),
      MovementHistoryItem(
        date: DateTime(2025, 10, 13),
        description: 'Выдан Иванов И.И.',
      ),
    ];

    // Реальный код (закомментирован):
    /*
    try {
      final client = Supabase.instance.client;
      final movements = await client.from('inventory_movements').select('''
            movement_type,
            to_location_type,
            to_location_id,
            to_responsible_id,
            moved_at
          ''').eq('item_id', itemId).order('moved_at', ascending: false);

      if (movements.isEmpty) return [];

      final historyItems = <MovementHistoryItem>[];

      for (final movement in movements) {
        final date = DateTime.parse(movement['moved_at'] as String);
        final toLocationType = movement['to_location_type'] as String;
        final toLocationId = movement['to_location_id'] as String?;
        final toResponsibleId = movement['to_responsible_id'] as String?;

        String description = '';

        if (toLocationType == 'warehouse') {
          description = 'Сдан на склад';
        } else if (toLocationType == 'employee' && toResponsibleId != null) {
          // Получаем имя сотрудника
          try {
            final employeeResponse = await client
                .from('employees')
                .select('first_name, last_name, middle_name')
                .eq('id', toResponsibleId)
                .maybeSingle();

            if (employeeResponse != null) {
              final firstName = employeeResponse['first_name'] as String? ?? '';
              final lastName = employeeResponse['last_name'] as String? ?? '';
              final middleName =
                  employeeResponse['middle_name'] as String? ?? '';

              String fullName = '';
              if (lastName.isNotEmpty) {
                fullName = lastName;
                if (firstName.isNotEmpty) {
                  final initials = '${firstName[0]}.';
                  fullName += ' $initials';
                  if (middleName.isNotEmpty) {
                    fullName += '${middleName[0]}.';
                  }
                }
              }

              description = 'Выдан $fullName';
            } else {
              description = 'Выдан сотруднику';
            }
          } catch (e) {
            description = 'Выдан сотруднику';
          }
        } else if (toLocationType == 'object' && toLocationId != null) {
          // Получаем название объекта
          try {
            final objectResponse = await client
                .from('objects')
                .select('name')
                .eq('id', toLocationId)
                .maybeSingle();

            if (objectResponse != null) {
              final objectName = objectResponse['name'] as String? ?? 'Объект';
              description = 'Выдан на объект $objectName';
            } else {
              description = 'Выдан на объект';
            }
          } catch (e) {
            description = 'Выдан на объект';
          }
        } else {
          description = 'Перемещён';
        }

        historyItems.add(MovementHistoryItem(
          date: date,
          description: description,
        ));
      }

      return historyItems;
    } catch (e) {
      return [];
    }
    */
  },
);

/// Модальное окно детального просмотра ТМЦ.
class InventoryItemViewModal extends ConsumerWidget {
  /// ID ТМЦ для отображения.
  final String itemId;

  /// Создаёт модальное окно детального просмотра ТМЦ.
  const InventoryItemViewModal({
    super.key,
    required this.itemId,
  });

  /// Показывает модальное окно детального просмотра ТМЦ.
  static Future<void> show({
    required BuildContext context,
    required String itemId,
  }) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 900;

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 500 : double.infinity,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: InventoryItemViewModal(
            itemId: itemId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemAsync = ref.watch(inventoryItemProvider(itemId));

    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return _buildErrorState(
            context,
            theme,
            'ТМЦ не найдена',
          );
        }
        return _buildContent(context, ref, theme, item);
      },
      loading: () => _buildLoadingState(context, theme),
      error: (error, stack) => _buildErrorState(
        context,
        theme,
        'Ошибка загрузки данных: ${error.toString()}',
      ),
    );
  }

  /// Строит содержимое модального окна с данными ТМЦ.
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    InventoryItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой закрытия
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Фото
          _buildPhoto(context, theme, item.photoUrl),

          const SizedBox(height: 20),

          // Информация о стоимости
          if (item.price != null) _buildPriceInfo(context, theme, item.price!),

          // Информация о накладной
          _buildReceiptInfo(context, ref, theme, item.receiptId),

          // История движений
          _buildHistoryBlock(context, ref, theme, item.id),
        ],
      ),
    );
  }

  /// Строит блок с фото.
  Widget _buildPhoto(BuildContext context, ThemeData theme, String? photoUrl) {
    return Container(
      width: double.infinity,
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPhotoPlaceholder(context, theme),
            )
          : _buildPhotoPlaceholder(context, theme),
    );
  }

  /// Строит заглушку для фото.
  Widget _buildPhotoPlaceholder(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Фото отсутствует',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Строит блок с информацией о стоимости.
  Widget _buildPriceInfo(BuildContext context, ThemeData theme, double price) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            '₽',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Стоимость',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(price),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Строит блок с информацией о накладной.
  Widget _buildReceiptInfo(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String? receiptId,
  ) {
    // Если накладной нет, показываем "Накладная отсутствует"
    if (receiptId == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Накладная отсутствует',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final receiptAsync = ref.watch(receiptInfoProvider(receiptId));

    return receiptAsync.when(
      data: (receiptInfo) {
        if (receiptInfo == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Накладная № ${receiptInfo.receiptNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Дата накладной ${formatRuDate(receiptInfo.receiptDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(radius: 8),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Строит блок с историей движений ТМЦ.
  Widget _buildHistoryBlock(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String itemId,
  ) {
    final historyAsync = ref.watch(movementHistoryProvider(itemId));

    return historyAsync.when(
      data: (historyItems) {
        if (historyItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'История',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...historyItems.map((item) {
                final isIssued = item.description.startsWith('Выдан');
                final arrowColor = isIssued ? Colors.red : Colors.green;
                final arrowIcon =
                    isIssued ? Icons.arrow_upward : Icons.arrow_downward;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        arrowIcon,
                        size: 16,
                        color: arrowColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRuDate(item.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CupertinoActivityIndicator(radius: 8),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Строит состояние загрузки.
  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(
              radius: 10,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Загрузка данных...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Строит состояние ошибки.
  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

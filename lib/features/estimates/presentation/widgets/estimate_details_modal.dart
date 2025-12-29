import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../domain/entities/estimate.dart';
import '../providers/estimate_providers.dart';

/// Модальное окно с детальной информацией о позиции сметы.
class EstimateDetailsModal extends ConsumerWidget {
  /// Позиция сметы.
  final Estimate item;

  /// Данные о выполнении позиции.
  final EstimateCompletionModel? completion;

  /// Создает экземпляр [EstimateDetailsModal].
  const EstimateDetailsModal({
    super.key,
    required this.item,
    this.completion,
  });

  /// Отображает модальное окно.
  static Future<void> show(
    BuildContext context, {
    required Estimate item,
    EstimateCompletionModel? completion,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EstimateDetailsModal(
        item: item,
        completion: completion,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return MobileBottomSheetContent(
      title: 'Детали позиции',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Полное название и номер
          _buildSectionTitle(theme, 'Наименование'),
          Text(
            '№${item.number} ${item.name}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // 2. Характеристики
          _buildSectionTitle(theme, 'Характеристики'),
          _buildInfoRow('Система', item.system),
          _buildInfoRow('Подсистема', item.subsystem.isEmpty ? '—' : item.subsystem),
          _buildInfoRow('Артикул', item.article.isEmpty ? '—' : item.article),
          _buildInfoRow('Производитель', item.manufacturer.isEmpty ? '—' : item.manufacturer),
          const SizedBox(height: 20),

          // 3. Плановые данные (Смета)
          _buildSectionTitle(theme, 'По смете'),
          _buildInfoRow('Количество', '${formatQuantity(item.quantity)} ${item.unit}'),
          _buildInfoRow('Цена ед.', formatCurrency(item.price)),
          _buildInfoRow('Итого стоимость', formatCurrency(item.total), isBold: true),
          const SizedBox(height: 20),

          // 4. Фактические данные (Выполнение)
          _buildSectionTitle(theme, 'Выполнение'),
          _buildInfoRow(
            'Сделано',
            '${formatQuantity(completion?.completedQuantity ?? 0)} ${item.unit}',
            valueColor: Colors.green[700],
            onTap: () => _showHistory(context, ref),
            showChevron: true,
          ),
          _buildInfoRow(
            'Сумма вып.',
            formatCurrency(completion?.completedTotal ?? 0),
            valueColor: Colors.green[700],
          ),
          _buildInfoRow(
            'Остаток',
            '${formatQuantity(completion?.remainingQuantity ?? item.quantity)} ${item.unit}',
            valueColor: Colors.amber[800],
          ),
          _buildInfoRow(
            'Процент выполнения',
            '${(completion?.percentage ?? 0).toStringAsFixed(1)}%',
            isBold: true,
            valueColor: _getPercentageColor(completion?.percentage ?? 0),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompletionHistoryModal(
        estimateId: item.id,
        unit: item.unit,
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    VoidCallback? onTap,
    bool showChevron = false,
  }) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      color: valueColor,
                    ),
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: content,
      );
    }

    return content;
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 100) return Colors.green;
    if (percentage > 0) return Colors.blue;
    return Colors.grey;
  }
}

class _CompletionHistoryModal extends ConsumerWidget {
  final String estimateId;
  final String unit;

  const _CompletionHistoryModal({
    required this.estimateId,
    required this.unit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(estimateCompletionHistoryProvider(estimateId));
    final theme = Theme.of(context);

    return MobileBottomSheetContent(
      title: 'История выполнения',
      child: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('История выполнения пуста'),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = history[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatRuDate(record.date),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${formatQuantity(record.quantity)} $unit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CupertinoActivityIndicator(),
          ),
        ),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text('Ошибка загрузки: $e'),
          ),
        ),
      ),
    );
  }
}



import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/vor.dart';
import '../providers/estimate_providers.dart';

/// Виджет детальной информации о ведомости ВОР.
///
/// Отображается при раскрытии карточки в списке ВОР.
class VorCardDetails extends ConsumerWidget {
  /// Данные ведомости.
  final Vor vor;

  /// Создает экземпляр [VorCardDetails].
  const VorCardDetails({super.key, required this.vor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exportService = ref.watch(vorExportServiceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.15,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Основная информация
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailSection(
                  title: 'Общая информация',
                  children: [
                    _DetailRow(
                      label: 'Создан:',
                      value:
                          '${formatRuDateTime(vor.createdAt)} (${vor.createdByName ?? 'Неизвестно'})',
                    ),
                    _DetailRow(
                      label: 'Системы:',
                      value: vor.systems.join(', '),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // История статусов и файлов
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailSection(
                  title: 'История статусов',
                  children: vor.statusHistory
                      .map(
                        (item) => _HistoryRow(
                          date: item.createdAt,
                          user: item.userName ?? 'Система',
                          content: Vor.getStatusText(item.status),
                          icon: CupertinoIcons.tag,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _DetailSection(
                  title: 'Файлы',
                  children: [
                    if (vor.excelUrl != null)
                      _HistoryRow(
                        date: vor.createdAt,
                        user: vor.createdByName ?? '',
                        content: 'Ведомость ВОР.xlsx',
                        icon: CupertinoIcons.doc,
                        onTap: () => exportService.exportVorToExcel(vor.id),
                      ),
                    if (vor.pdfUrl != null)
                      _HistoryRow(
                        date: vor
                            .createdAt, // В будущем добавить дату загрузки PDF
                        user: '',
                        content: 'Подписанный PDF.pdf',
                        icon: CupertinoIcons.doc_checkmark,
                        onTap: () {
                          // TODO(task): Реализовать скачивание PDF
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final DateTime date;
  final String user;
  final String content;
  final IconData icon;
  final VoidCallback? onTap;

  const _HistoryRow({
    required this.date,
    required this.user,
    required this.content,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: onTap != null ? theme.colorScheme.primary : null,
                        decoration: onTap != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                    Text(
                      '${formatRuDate(date)} — $user',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/providers/profiles_cache_provider.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';

/// Виджет списка смен внутри группы месяца.
///
/// Отображает карточки смен с агрегированными данными (без подписок на провайдеры).
/// Поддерживает infinite scroll для подгрузки дополнительных смен.
class MonthWorksList extends ConsumerStatefulWidget {
  /// Группа месяца со сменами.
  final MonthGroup group;

  /// Колбэк при выборе смены.
  final Function(Work work) onWorkSelected;

  /// Колбэк для подгрузки дополнительных смен (infinite scroll).
  final VoidCallback onLoadMore;

  /// Выбранная смена (для подсветки в desktop режиме).
  final Work? selectedWork;

  /// Создаёт виджет списка смен месяца.
  const MonthWorksList({
    super.key,
    required this.group,
    required this.onWorkSelected,
    required this.onLoadMore,
    this.selectedWork,
  });

  @override
  ConsumerState<MonthWorksList> createState() => _MonthWorksListState();
}

class _MonthWorksListState extends ConsumerState<MonthWorksList> {
  final _scrollController = ScrollController();

  /// Флаг, чтобы не загружать одновременно несколько порций смен.
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Обработчик скролла для infinite scroll.
  ///
  /// Срабатывает при приближении к концу списка (200px).
  /// Содержит дебаунс для предотвращения множественных запросов.
  void _onScroll() {
    // Пропускаем, если уже загружаем дополнительные смены
    if (_isLoadingMore) return;

    final position = _scrollController.position;
    final isAtEnd = position.pixels >= position.maxScrollExtent - 200;

    if (isAtEnd) {
      // Устанавливаем флаг и запускаем загрузку
      _isLoadingMore = true;
      widget.onLoadMore();

      // Сбрасываем флаг через 500ms, чтобы предотвратить spam запросов
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final works = widget.group.works;

    // Если смены ещё не загружены, показываем индикатор
    if (works == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    // Если смен нет, показываем сообщение
    if (works.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Нет смен в этом месяце',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
      );
    }

    // Отображаем список смен с поддержкой infinite scroll.
    //
    // ВАЖНО: Не используем shrinkWrap: true, потому что это ломает расчёт
    // maxScrollExtent. Вместо этого родитель (ConstrainedBox) задаёт
    // фиксированную высоту, что позволяет ListView правильно вычислить
    // границы скролла и срабатывает infinite scroll при приближении к концу.
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: works.length,
      itemBuilder: (context, index) {
        final work = works[index];
        return _buildWorkCard(context, work);
      },
    );
  }

  /// Строит карточку смены с агрегированными данными.
  Widget _buildWorkCard(BuildContext context, Work work) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final selected = isDesktop && work.id == widget.selectedWork?.id;
    final formatter = NumberFormat('#,##0', 'ru_RU');

    // Получаем название объекта
    final objectName = ref
            .watch(objectProvider)
            .objects
            .where((o) => o.id == work.objectId)
            .map((o) => o.name)
            .firstOrNull ??
        work.objectId;

    // Получаем статус работы с цветом
    final (statusText, statusColor) = _getWorkStatusInfo(work.status);

    return Consumer(
      builder: (context, ref, _) {
        final profileAsync = ref.watch(userProfileProvider(work.openedBy));

        final String createdBy = profileAsync.when(
          data: (profile) =>
              profile?.shortName ?? 'ID: ${work.openedBy.substring(0, 4)}...',
          loading: () => '...',
          error: (_, __) => 'ID: ${work.openedBy.substring(0, 4)}...',
        );

        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? 0 : 16,
            vertical: isDesktop ? 6 : 8,
          ),
          elevation: isDesktop ? 0 : 8,
          shadowColor: isDesktop
              ? null
              : theme.colorScheme.shadow.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
            side: BorderSide(
              color: selected
                  ? Colors.green
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => widget.onWorkSelected(work),
            borderRadius:
                BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Иконка смены
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Icon(
                          work.status.toLowerCase() == 'closed'
                              ? Icons.lock
                              : Icons.lock_open,
                          color: work.status.toLowerCase() == 'closed'
                              ? Colors.red
                              : Colors.green,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Информация о смене
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Цветовая точка статуса только в мобильном режиме
                                if (!isDesktop) ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _formatDate(work.date),
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              objectName,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Открыл: $createdBy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isDesktop) ...[
                        AppBadge(
                          text: statusText,
                          color: statusColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Агрегированные данные из БД
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${formatter.format(work.totalAmount ?? 0)} ₽',
                            style: (isDesktop
                                    ? theme.textTheme.bodySmall
                                    : theme.textTheme.titleSmall)
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if ((work.employeesCount ?? 0) > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${formatter.format(((work.totalAmount ?? 0) / (work.employeesCount ?? 1)).round())} ₽/чел',
                              style: (isDesktop
                                      ? theme.textTheme.bodySmall
                                      : theme.textTheme.bodyMedium)
                                  ?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Форматирует дату в строку ДД.ММ.ГГГГ.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Возвращает текст и цвет статуса смены.
  (String, Color) _getWorkStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ('Открыта', Colors.green);
      case 'closed':
        return ('Закрыта', Colors.red);
      default:
        return ('Неизвестно', Colors.grey);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/providers/profiles_cache_provider.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/di/providers.dart';

/// Sliver-версия списка смен для использования внутри CustomScrollView.
///
/// Обеспечивает эффективный ленивый рендеринг и автоматическую подгрузку данных (infinite scroll).
class SliverMonthWorksList extends ConsumerWidget {
  /// Группа смен за месяц.
  final MonthGroup group;

  /// Колбэк, вызываемый при выборе смены.
  final Function(Work work) onWorkSelected;

  /// Колбэк, вызываемый для загрузки следующей порции смен.
  final VoidCallback onLoadMore;

  /// Выбранная смена (для подсветки в режиме master-detail).
  final Work? selectedWork;

  /// Флаг компактного режима отображения (для master-списка).
  final bool isCompact;

  /// Создаёт Sliver-список смен.
  const SliverMonthWorksList({
    super.key,
    required this.group,
    required this.onWorkSelected,
    required this.onLoadMore,
    this.selectedWork,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final works = group.works;

    // Если смены ещё не загружены или null
    if (works == null) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CupertinoActivityIndicator()),
        ),
      );
    }

    if (works.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Нет смен в этом месяце',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ),
      );
    }

    final hasMore = works.length < group.worksCount;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Если дошли до последнего элемента и есть еще данные - показываем лоадер и грузим
          if (index == works.length) {
            // Микро-задержка перед вызовом загрузки, чтобы избежать ошибок во время build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onLoadMore();
            });

            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }

          final work = works[index];
          return _buildWorkCard(context, ref, work);
        },
        // Добавляем +1 элемент для лоадера, если есть еще данные
        childCount: works.length + (hasMore ? 1 : 0),
      ),
    );
  }

  Widget _buildWorkCard(BuildContext context, WidgetRef ref, Work work) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final selected = isDesktop && work.id == selectedWork?.id;
    final formatter = NumberFormat('#,##0', 'ru_RU');

    // Получаем название объекта
    final objectName = ref
            .watch(objectProvider)
            .objects
            .where((o) => o.id == work.objectId)
            .map((o) => o.name)
            .firstOrNull ??
        work.objectId;

    final (statusText, statusColor) = _getWorkStatusInfo(work.status);

    final profileAsync = ref.watch(userProfileProvider(work.openedBy));
    final String createdBy = profileAsync.when(
      data: (profile) =>
          profile?.shortName ?? 'ID: ${work.openedBy.substring(0, 4)}...',
      loading: () => '...',
      error: (_, __) => 'ID: ${work.openedBy.substring(0, 4)}...',
    );

    if (!isDesktop) {
      return _buildMobileWorkCard(
        context,
        work,
        objectName,
        createdBy,
        formatter,
        statusText,
        statusColor,
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      elevation: 0,
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.cardColor,
      shadowColor: null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: () => onWorkSelected(work),
        borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Иконка
              SizedBox(
                width: isCompact ? 40 : 48,
                height: isCompact ? 40 : 48,
                child: Center(
                  child: Icon(
                    work.status.toLowerCase() == 'closed'
                        ? CupertinoIcons.lock_fill
                        : CupertinoIcons.lock_open_fill,
                    color: work.status.toLowerCase() == 'closed'
                        ? Colors.red
                        : Colors.green,
                    size: isCompact ? 24 : 32,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Инфо
              Expanded(
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(work.date),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.blue : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  objectName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: selected ? Colors.blue : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  createdBy,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: selected
                                        ? Colors.blue.withValues(alpha: 0.7)
                                        : theme.colorScheme.secondary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${formatter.format(work.totalAmount ?? 0)} ₽',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.blue
                                      : theme.colorScheme.primary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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

              if (!isCompact)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
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
      ),
    );
  }

  Widget _buildMobileWorkCard(
    BuildContext context,
    Work work,
    String objectName,
    String createdBy,
    NumberFormat formatter,
    String statusText,
    Color statusColor,
  ) {
    final theme = Theme.of(context);

    // Профессиональный, компактный дизайн с акцентом на данные
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // Убрали тень для чистого flat-дизайна
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Цветной индикатор статуса слева
            Container(
              width: 4,
              color: statusColor,
            ),
            // Контент карточки
            Expanded(
              child: InkWell(
                onTap: () => onWorkSelected(work),
                // Убираем выделение при наведении (hover)
                hoverColor: Colors.transparent,
                // Убираем выделение при нажатии
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Левая колонка: Дата и Автор
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(work.date),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              createdBy,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Правая колонка: Объект и Сумма
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              objectName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${formatter.format(work.totalAmount ?? 0)} ₽',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

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

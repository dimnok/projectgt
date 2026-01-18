import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import '../../providers/work_search_provider.dart';
import '../../providers/work_search_date_provider.dart';
import '../../widgets/export_results_table_view.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import '../../widgets/export_search_action.dart';

/// Таб "Поиск" для расширенного поиска и фильтрации данных.
class ExportTabSearch extends ConsumerStatefulWidget {
  /// Создаёт таб поиска.
  const ExportTabSearch({super.key});

  @override
  ConsumerState<ExportTabSearch> createState() => _ExportTabSearchState();
}

class _ExportTabSearchState extends ConsumerState<ExportTabSearch> {
  @override
  Widget build(BuildContext context) {
    // Проверяем, является ли устройство десктопом
    if (!ResponsiveUtils.isDesktop(context)) {
      return _buildMobileUnavailableMessage(context);
    }

    final theme = Theme.of(context);
    final searchState = ref.watch(workSearchProvider);
    final selectedObjectId = ref.watch(exportSelectedObjectIdProvider);

    // Объект обязателен для поиска
    if (selectedObjectId == null) {
      return _buildObjectSelectionPrompt(context, theme);
    }

    return _buildSearchResults(context, theme, searchState);
  }

  /// Строит результаты поиска.
  Widget _buildSearchResults(
    BuildContext context,
    ThemeData theme,
    WorkSearchState searchState,
  ) {
    if (searchState.isLoading) {
      final isLightTheme = theme.brightness == Brightness.light;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(
                radius: 15,
                color: isLightTheme ? Colors.green : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Загрузка данных...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                searchState.error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Ничего не найдено',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте выбрать другой объект или изменить запрос поиска',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Получаем информацию о роли для прав редактирования
    final user = ref.watch(authProvider).user;
    final roleAsync = user?.roleId != null
        ? ref.watch(roleByIdProvider(user!.roleId!))
        : const AsyncValue<dynamic>.data(null);

    final isAdmin = roleAsync.when(
      data: (role) =>
          role?.name == 'Администратор' || role?.name == 'Супер-админ',
      loading: () => false,
      error: (_, __) => false,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ExportResultsTableView(
              results: searchState.results,
              totalQuantity: searchState.totalQuantity,
              totalSum: searchState.totalSum,
              canEdit: isAdmin,
              onEdit: (result) {
                if (result.workItemId == null ||
                    result.workId == null ||
                    result.objectId == null) {
                  SnackBarUtils.showError(
                    context,
                    'Недостаточно данных для редактирования',
                  );
                  return;
                }
                ModalUtils.showExportWorkItemEditModal(
                  context,
                  initialData: result,
                );
              },
              onNavigateToWork: (result) {
                if (result.workId != null) {
                  context.goNamed(
                    'work_details',
                    pathParameters: {'workId': result.workId!},
                    extra: {'initialTabIndex': 1},
                  );
                }
              },
              onMaterialTap: (materialName) {
                ref.read(exportSearchQueryProvider.notifier).state =
                    materialName;
                ref.read(exportSearchVisibleProvider.notifier).state = true;

                final selectedObjectId = ref.read(
                  exportSelectedObjectIdProvider,
                );
                final filters = ref.read(exportSearchFilterProvider);
                final dateRange = ref.read(workSearchDateRangeProvider);

                ref
                    .read(workSearchProvider.notifier)
                    .searchMaterials(
                      objectId: selectedObjectId,
                      startDate: dateRange?.start,
                      endDate: dateRange?.end,
                      searchQuery: materialName,
                      systemFilters: filters['system']?.toList(),
                      sectionFilters: filters['section']?.toList(),
                      floorFilters: filters['floor']?.toList(),
                    );
              },
            ),
          ),
          if (searchState.totalPages > 1)
            _buildPaginationControls(context, theme, searchState),
        ],
      ),
    );
  }

  /// Строит сообщение о недоступности модуля на мобильных устройствах.
  Widget _buildMobileUnavailableMessage(BuildContext context) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.desktop_windows_rounded,
                size: 80,
                color: isLightTheme ? Colors.blue : Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Модуль доступен только на компьютере',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Расширенный поиск и фильтрация данных требуют большого экрана для комфортной работы. Мобильная версия находится в разработке.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.grey.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isLightTheme ? Colors.blue : Colors.blue.shade300,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Используйте компьютер или планшет с шириной экрана более 900px для доступа к этому модулю.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит подсказку для выбора объекта.
  Widget _buildObjectSelectionPrompt(BuildContext context, ThemeData theme) {
    final isLightTheme = theme.brightness == Brightness.light;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_city_rounded,
                size: 64,
                color: isLightTheme ? Colors.blue : Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Выберите объект для начала поиска',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? Colors.blue.withValues(alpha: 0.08)
                    : Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 20,
                    color: isLightTheme ? Colors.blue : Colors.blue.shade300,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Нажмите на чип объекта выше для начала работы',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isLightTheme
                          ? Colors.blue.shade700
                          : Colors.blue.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит элементы управления пагинацией.
  Widget _buildPaginationControls(
    BuildContext context,
    ThemeData theme,
    WorkSearchState searchState,
  ) {
    final canGoPrevious = searchState.currentPage > 1;
    final canGoNext = searchState.currentPage < searchState.totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            onPressed: canGoPrevious
                ? () => ref.read(workSearchProvider.notifier).previousPage()
                : null,
            tooltip: 'Предыдущая страница',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          Text(
            'Страница ${searchState.currentPage} из ${searchState.totalPages}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${searchState.totalCount} записей)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            onPressed: canGoNext
                ? () => ref.read(workSearchProvider.notifier).nextPage()
                : null,
            tooltip: 'Следующая страница',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

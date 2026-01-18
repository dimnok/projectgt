import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/providers.dart';
import '../providers/work_search_provider.dart';
import '../providers/work_search_date_provider.dart';
import '../../data/datasources/work_search_data_source.dart';
import 'export_search_action.dart';
import '../providers/repositories_providers.dart';

/// Провайдер для получения списка ID объектов, у которых есть работы.
final objectsWithWorksProvider = FutureProvider<Set<String>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('works')
      .select('object_id')
      .not('object_id', 'is', null);

  final objectIds = response
      .map((item) => item['object_id'] as String?)
      .whereType<String>()
      .toSet();

  return objectIds;
});

/// Провайдер для получения уникальных значений фильтров для объекта.
final workSearchFilterValuesProvider =
    FutureProvider.autoDispose<WorkSearchFilterValues?>((ref) async {
  final selectedObjectId = ref.watch(exportSelectedObjectIdProvider);
  final filters = ref.watch(exportSearchFilterProvider);
  final searchQuery = ref.watch(exportSearchQueryProvider);
  final dateRange = ref.watch(workSearchDateRangeProvider);

  if (selectedObjectId == null || selectedObjectId.isEmpty) {
    return null;
  }

  final repository = ref.watch(workSearchRepositoryProvider);

  try {
    return await repository.getFilterValues(
      objectId: selectedObjectId,
      startDate: dateRange?.start,
      endDate: dateRange?.end,
      systemFilters: filters['system']?.toList(),
      sectionFilters: filters['section']?.toList(),
      searchQuery: searchQuery,
    );
  } catch (e) {
    debugPrint('Ошибка загрузки фильтров: $e');
    return null;
  }
});

/// Виджет чипов фильтров для результатов поиска.
class ExportSearchFilterChips extends ConsumerWidget {
  /// Конструктор виджета чипов фильтров.
  const ExportSearchFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(workSearchProvider);
    final filters = ref.watch(exportSearchFilterProvider);
    final objectsState = ref.watch(objectProvider);
    final selectedObjectId = ref.watch(exportSelectedObjectIdProvider);
    final objectsWithWorksAsync = ref.watch(objectsWithWorksProvider);
    final filterValuesAsync = ref.watch(workSearchFilterValuesProvider);

    // Показываем чипы фильтров если выбран объект или есть результаты
    final shouldShowFilters =
        selectedObjectId != null || searchState.results.isNotEmpty;

    if (!shouldShowFilters) {
      // Но показываем чипы объектов, если они есть
      return objectsWithWorksAsync.when(
        data: (objectsWithWorks) {
          final filteredObjects = objectsState.objects
              .where((object) => objectsWithWorks.contains(object.id))
              .toList();

          if (filteredObjects.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Объект:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...filteredObjects.map((object) {
                    final isSelected = selectedObjectId == object.id;
                    return _FilterChipItem(
                      label: object.name,
                      isSelected: isSelected,
                      onSelected: (selected) {
                        final newObjectId = selected ? object.id : null;
                        ref
                            .read(exportSelectedObjectIdProvider.notifier)
                            .state = newObjectId;
                        ref.read(exportSearchQueryProvider.notifier).state = '';

                        if (newObjectId == null) {
                          ref.read(exportSearchFilterProvider.notifier).state = {
                            'system': <String>{},
                            'section': <String>{},
                            'floor': <String>{},
                          };
                        }

                        _reloadSearch(ref, ref.read(exportSearchFilterProvider));
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    }

    final filterValues = filterValuesAsync.valueOrNull;
    final systems = filterValues?.systems ?? [];
    final sections = filterValues?.sections ?? [];
    final floors = filterValues?.floors ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Чипы объектов
            objectsWithWorksAsync.when(
              data: (objectsWithWorks) {
                final filteredObjects = objectsState.objects
                    .where((object) => objectsWithWorks.contains(object.id))
                    .toList();

                if (filteredObjects.isEmpty) return const SizedBox.shrink();

                return Row(
                  children: [
                    Text(
                      'Объект:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...filteredObjects.map((object) {
                      final isSelected = selectedObjectId == object.id;
                      return _FilterChipItem(
                        label: object.name,
                        isSelected: isSelected,
                        onSelected: (selected) {
                          final newObjectId = selected ? object.id : null;
                          ref.read(exportSelectedObjectIdProvider.notifier).state = newObjectId;
                          ref.read(exportSearchQueryProvider.notifier).state = '';

                          if (newObjectId == null) {
                            ref.read(exportSearchFilterProvider.notifier).state = {
                              'system': <String>{},
                              'section': <String>{},
                              'floor': <String>{},
                            };
                          }
                          _reloadSearch(ref, ref.read(exportSearchFilterProvider));
                        },
                      );
                    }),
                    const SizedBox(width: 12),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            // Фильтры
            if (systems.isNotEmpty) ...[
              _buildFilterChipGroup(
                context,
                theme,
                'Система',
                systems,
                filters['system'] ?? <String>{},
                (value) {
                  final newFilters = Map<String, Set<String>>.from(filters);
                  final newSet = Set<String>.from(newFilters['system'] ?? {});
                  if (newSet.contains(value)) {
                    newSet.remove(value);
                  } else {
                    newSet.add(value);
                  }
                  newFilters['system'] = newSet;
                  // При Multi-select не очищаем участки автоматически, 
                  // чтобы пользователь мог добавить вторую систему к уже выбранным участкам
                  ref.read(exportSearchFilterProvider.notifier).state = newFilters;
                  _reloadSearch(ref, newFilters);
                },
              ),
              const SizedBox(width: 12),
            ],
            
            if (sections.isNotEmpty) ...[
              _buildFilterChipGroup(
                context,
                theme,
                'Участок',
                sections,
                filters['section'] ?? <String>{},
                (value) {
                  final newFilters = Map<String, Set<String>>.from(filters);
                  final newSet = Set<String>.from(newFilters['section'] ?? {});
                  if (newSet.contains(value)) {
                    newSet.remove(value);
                  } else {
                    newSet.add(value);
                  }
                  newFilters['section'] = newSet;
                  ref.read(exportSearchFilterProvider.notifier).state = newFilters;
                  _reloadSearch(ref, newFilters);
                },
              ),
              const SizedBox(width: 12),
            ],
            
            if (floors.isNotEmpty) ...[
              _buildFilterChipGroup(
                context,
                theme,
                'Этаж',
                floors,
                filters['floor'] ?? <String>{},
                (value) {
                  final newFilters = Map<String, Set<String>>.from(filters);
                  final newSet = Set<String>.from(newFilters['floor'] ?? {});
                  if (newSet.contains(value)) {
                    newSet.remove(value);
                  } else {
                    newSet.add(value);
                  }
                  newFilters['floor'] = newSet;
                  ref.read(exportSearchFilterProvider.notifier).state = newFilters;
                  _reloadSearch(ref, newFilters);
                },
              ),
            ],
            
            // Кнопка сброса
            if (filters.values.any((set) => set.isNotEmpty)) ...[
              const SizedBox(width: 12),
              ActionChip(
                avatar: const Icon(Icons.close, size: 14),
                label: const Text('Сбросить всё'),
                onPressed: () {
                  ref.read(exportSearchFilterProvider.notifier).state = {
                    'system': <String>{},
                    'section': <String>{},
                    'floor': <String>{},
                  };
                  ref.read(exportSearchQueryProvider.notifier).state = '';
                  _reloadSearch(ref, {
                    'system': <String>{},
                    'section': <String>{},
                    'floor': <String>{},
                  });
                },
                backgroundColor: theme.colorScheme.errorContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _reloadSearch(WidgetRef ref, Map<String, Set<String>> filters) {
    final selectedObjectId = ref.read(exportSelectedObjectIdProvider);
    final dateRange = ref.read(workSearchDateRangeProvider);
    if (selectedObjectId == null || selectedObjectId.isEmpty) return;

    ref.read(workSearchProvider.notifier).searchMaterials(
          objectId: selectedObjectId,
          startDate: dateRange?.start,
          endDate: dateRange?.end,
          searchQuery: ref.read(exportSearchQueryProvider),
          systemFilters: filters['system']?.toList(),
          sectionFilters: filters['section']?.toList(),
          floorFilters: filters['floor']?.toList(),
        );
  }

  Widget _buildFilterChipGroup(
    BuildContext context,
    ThemeData theme,
    String label,
    List<String> values,
    Set<String> selected,
    ValueChanged<String> onToggle,
  ) {
    return Row(
      children: [
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        ...values.map((value) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _FilterChipItem(
            label: value,
            isSelected: selected.contains(value),
            onSelected: (_) => onToggle(value),
          ),
        )),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: isLightTheme && isSelected
          ? Colors.green
          : theme.colorScheme.onPrimaryContainer,
      side: isLightTheme && isSelected
          ? const BorderSide(color: Colors.green, width: 1)
          : null,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isSelected
            ? (isLightTheme
                ? Colors.green
                : theme.colorScheme.onPrimaryContainer)
            : theme.colorScheme.onSurface,
      ),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

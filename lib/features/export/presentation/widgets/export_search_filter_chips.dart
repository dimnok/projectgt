import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/providers.dart';
import '../providers/work_search_provider.dart';
import '../../domain/entities/work_search_result.dart';
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

  if (selectedObjectId == null || selectedObjectId.isEmpty) {
    return null;
  }

  final repository = ref.watch(workSearchRepositoryProvider);

  try {
    return await repository.getFilterValues(
      objectId: selectedObjectId,
    );
  } catch (e) {
    debugPrint('Ошибка загрузки фильтров: $e');
    return null;
  }
});

/// Виджет чипов фильтров для результатов поиска.
/// Показывает доступные значения систем, участков и этажей из результатов поиска.
/// Чипы обновляются динамически при выборе фильтров.
class ExportSearchFilterChips extends ConsumerWidget {
  /// Конструктор виджета чипов фильтров.
  const ExportSearchFilterChips({super.key});

  /// Фильтрует результаты по системам для извлечения доступных значений участков.
  List<WorkSearchResult> _getFilteredResultsForSection(
      List<WorkSearchResult> results, Map<String, Set<String>> filters) {
    return results.where((result) {
      // Фильтр по системе
      if (filters['system']?.isNotEmpty ?? false) {
        if (!filters['system']!.contains(result.system)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Фильтрует результаты по системам и участкам для извлечения доступных значений этажей.
  List<WorkSearchResult> _getFilteredResultsForFloor(
      List<WorkSearchResult> results, Map<String, Set<String>> filters) {
    return results.where((result) {
      // Фильтр по системе
      if (filters['system']?.isNotEmpty ?? false) {
        if (!filters['system']!.contains(result.system)) {
          return false;
        }
      }
      // Фильтр по участку
      if (filters['section']?.isNotEmpty ?? false) {
        if (!filters['section']!.contains(result.section)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
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
                    final isLightTheme = theme.brightness == Brightness.light;
                    final checkmarkColor = isLightTheme && isSelected
                        ? Colors.green
                        : theme.colorScheme.onPrimaryContainer;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(object.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newObjectId = selected ? object.id : null;
                          ref
                              .read(exportSelectedObjectIdProvider.notifier)
                              .state = newObjectId;
                          ref.read(exportSearchQueryProvider.notifier).state =
                              '';

                          // При отмене выбора объекта сбрасываем все фильтры
                          if (newObjectId == null) {
                            ref
                                .read(exportSearchFilterProvider.notifier)
                                .state = {
                              'system': <String>{},
                              'section': <String>{},
                              'floor': <String>{},
                            };
                          }

                          ref.read(workSearchProvider.notifier).searchMaterials(
                                objectId: newObjectId,
                                searchQuery: null,
                                systemFilters: newObjectId == null
                                    ? null
                                    : filters['system']?.toList(),
                                sectionFilters: newObjectId == null
                                    ? null
                                    : filters['section']?.toList(),
                                floorFilters: newObjectId == null
                                    ? null
                                    : filters['floor']?.toList(),
                              );
                        },
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: checkmarkColor,
                        side: isLightTheme && isSelected
                            ? const BorderSide(color: Colors.green, width: 1)
                            : null,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (isLightTheme
                                  ? Colors.green
                                  : theme.colorScheme.onPrimaryContainer)
                              : theme.colorScheme.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
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

    // Используем значения фильтров из провайдера (все данные объекта)
    // или из результатов поиска как fallback
    final filterValues = filterValuesAsync.valueOrNull;
    final systems = filterValues?.systems ??
        searchState.results
            .map((r) => r.system)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
      ..sort();

    // Для участков и этажей применяем каскадную фильтрацию
    final filteredForSection =
        _getFilteredResultsForSection(searchState.results, filters);
    final sections = filterValues != null
        ? _applyCascadeFilter(
            filterValues.sections,
            filters,
            'section',
            (r) => r.section,
            filteredForSection,
          )
        : filteredForSection
            .map((r) => r.section)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
      ..sort();

    final filteredForFloor =
        _getFilteredResultsForFloor(searchState.results, filters);
    final floors = filterValues != null
        ? _applyCascadeFilter(
            filterValues.floors,
            filters,
            'floor',
            (r) => r.floor,
            filteredForFloor,
          )
        : filteredForFloor
            .map((r) => r.floor)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
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

                if (filteredObjects.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Row(
                  children: [
                    Text(
                      'Объект:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...filteredObjects.map((object) {
                      final isSelected = selectedObjectId == object.id;
                      final isLightTheme = theme.brightness == Brightness.light;
                      final checkmarkColor = isLightTheme && isSelected
                          ? Colors.green
                          : theme.colorScheme.onPrimaryContainer;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(object.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            final newObjectId = selected ? object.id : null;
                            ref
                                .read(exportSelectedObjectIdProvider.notifier)
                                .state = newObjectId;
                            ref.read(exportSearchQueryProvider.notifier).state =
                                '';

                            // При отмене выбора объекта сбрасываем все фильтры
                            if (newObjectId == null) {
                              ref
                                  .read(exportSearchFilterProvider.notifier)
                                  .state = {
                                'system': <String>{},
                                'section': <String>{},
                                'floor': <String>{},
                              };
                            }

                            ref
                                .read(workSearchProvider.notifier)
                                .searchMaterials(
                                  objectId: newObjectId,
                                  searchQuery: null,
                                  systemFilters: newObjectId == null
                                      ? null
                                      : filters['system']?.toList(),
                                  sectionFilters: newObjectId == null
                                      ? null
                                      : filters['section']?.toList(),
                                  floorFilters: newObjectId == null
                                      ? null
                                      : filters['floor']?.toList(),
                                );
                          },
                          selectedColor: theme.colorScheme.primaryContainer,
                          checkmarkColor: checkmarkColor,
                          side: isLightTheme && isSelected
                              ? const BorderSide(color: Colors.green, width: 1)
                              : null,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isLightTheme
                                    ? Colors.green
                                    : theme.colorScheme.onPrimaryContainer)
                                : theme.colorScheme.onSurface,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Остальные фильтры
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
                  // Очищаем фильтры, которые зависят от системы
                  newFilters['section'] = <String>{};
                  newFilters['floor'] = <String>{};
                  ref.read(exportSearchFilterProvider.notifier).state =
                      newFilters;
                  // Перезагружаем поиск с новыми фильтрами
                  _reloadSearch(ref, newFilters);
                },
              ),
              const SizedBox(width: 16),
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
                  ref.read(exportSearchFilterProvider.notifier).state =
                      newFilters;
                  // Перезагружаем поиск с новыми фильтрами
                  _reloadSearch(ref, newFilters);
                },
              ),
              const SizedBox(width: 16),
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
                  ref.read(exportSearchFilterProvider.notifier).state =
                      newFilters;
                  // Перезагружаем поиск с новыми фильтрами
                  _reloadSearch(ref, newFilters);
                },
              ),
            ],
            // Кнопка сброса фильтров
            if (filters.values.any((set) => set.isNotEmpty)) ...[
              const SizedBox(width: 16),
              ActionChip(
                avatar: const Icon(Icons.close, size: 18),
                label: const Text('Сбросить'),
                onPressed: () {
                  ref.read(exportSearchFilterProvider.notifier).state = {
                    'system': <String>{},
                    'section': <String>{},
                    'floor': <String>{},
                  };
                  ref.read(exportSearchQueryProvider.notifier).state = '';
                  // Объект не сбрасываем, используем текущий выбранный
                  final currentObjectId =
                      ref.read(exportSelectedObjectIdProvider);
                  ref.read(workSearchProvider.notifier).searchMaterials(
                        objectId: currentObjectId,
                        searchQuery: null,
                        systemFilters: null,
                        sectionFilters: null,
                        floorFilters: null,
                      );
                },
                backgroundColor: theme.colorScheme.errorContainer,
                labelStyle:
                    TextStyle(color: theme.colorScheme.onErrorContainer),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Применяет каскадную фильтрацию к списку значений.
  /// Показывает только те значения, которые есть в отфильтрованных результатах.
  List<String> _applyCascadeFilter(
    List<String> allValues,
    Map<String, Set<String>> filters,
    String filterKey,
    String Function(WorkSearchResult) getValue,
    List<WorkSearchResult> filteredResults,
  ) {
    // Если нет фильтров выше по иерархии, показываем все значения
    final hasUpperFilters = filters.entries
        .where((e) => e.key != filterKey)
        .any((e) => e.value.isNotEmpty);

    if (!hasUpperFilters) {
      return allValues;
    }

    // Иначе показываем только те, что есть в отфильтрованных результатах
    final availableValues =
        filteredResults.map(getValue).where((s) => s.isNotEmpty).toSet();

    return allValues.where((v) => availableValues.contains(v)).toList()..sort();
  }

  /// Перезагружает поиск с учетом текущих фильтров.
  void _reloadSearch(WidgetRef ref, Map<String, Set<String>> filters) {
    final selectedObjectId = ref.read(exportSelectedObjectIdProvider);
    if (selectedObjectId == null || selectedObjectId.isEmpty) return;

    ref.read(workSearchProvider.notifier).searchMaterials(
          objectId: selectedObjectId,
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
        ...values.map((value) {
          final isSelected = selected.contains(value);
          final isLightTheme = theme.brightness == Brightness.light;
          final checkmarkColor = isLightTheme && isSelected
              ? Colors.green
              : theme.colorScheme.onPrimaryContainer;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(value),
              selected: isSelected,
              onSelected: (_) => onToggle(value),
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: checkmarkColor,
              side: isLightTheme && isSelected
                  ? const BorderSide(color: Colors.green, width: 1)
                  : null,
              labelStyle: TextStyle(
                color: isSelected
                    ? (isLightTheme
                        ? Colors.green
                        : theme.colorScheme.onPrimaryContainer)
                    : theme.colorScheme.onSurface,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ],
    );
  }
}

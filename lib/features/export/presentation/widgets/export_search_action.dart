import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/work_search_provider.dart';

/// Провайдер запроса поиска для таба поиска.
final exportSearchQueryProvider = StateProvider<String>((ref) => '');

/// Провайдер выбранного объекта для поиска.
final exportSelectedObjectIdProvider = StateProvider<String?>((ref) => null);

/// Видимость поля поиска.
final exportSearchVisibleProvider = StateProvider<bool>((ref) => false);

/// Фильтры для результатов поиска.
final exportSearchFilterProvider =
    StateProvider<Map<String, Set<String>>>((ref) => {
          'system': <String>{},
          'section': <String>{},
          'floor': <String>{},
        });

/// Контроллер поля ввода с авто-диспозом.
final _exportSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final initial = ref.read(exportSearchQueryProvider);
  final c = TextEditingController(text: initial);
  ref.onDispose(c.dispose);
  // Синхронизируемся при внешнем изменении провайдера
  ref.listen<String>(exportSearchQueryProvider, (prev, next) {
    if (c.text != next) {
      c.text = next;
      c.selection = TextSelection.fromPosition(
        TextPosition(offset: c.text.length),
      );
    }
  });
  return c;
});

/// Виджет действий поиска для AppBar: анимированное поле + кнопка лупы.
class ExportSearchAction extends ConsumerStatefulWidget {
  /// Конструктор виджета действий поиска.
  const ExportSearchAction({super.key});

  @override
  ConsumerState<ExportSearchAction> createState() => _ExportSearchActionState();
}

class _ExportSearchActionState extends ConsumerState<ExportSearchAction> {
  Timer? _debounceTimer;
  static const int _debounceDelayMs = 500;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _performSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: _debounceDelayMs), () {
      final selectedObjectId = ref.read(exportSelectedObjectIdProvider);

      if (query.trim().isEmpty) {
        // Если запрос пустой, но есть выбранный объект - загружаем его работы
        if (selectedObjectId != null) {
          final filters = ref.read(exportSearchFilterProvider);
          ref.read(workSearchProvider.notifier).searchMaterials(
                objectId: selectedObjectId,
                searchQuery: null,
                systemFilters: filters['system']?.toList(),
                sectionFilters: filters['section']?.toList(),
                floorFilters: filters['floor']?.toList(),
              );
        } else {
          ref.read(workSearchProvider.notifier).clearResults();
        }
      } else {
        final filters = ref.read(exportSearchFilterProvider);
        ref.read(workSearchProvider.notifier).searchMaterials(
              objectId: selectedObjectId,
              searchQuery: query.trim(),
              systemFilters: filters['system']?.toList(),
              sectionFilters: filters['section']?.toList(),
              floorFilters: filters['floor']?.toList(),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = ref.watch(exportSearchVisibleProvider);
    final query = ref.watch(exportSearchQueryProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: visible ? 450 : 0,
          child: visible
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    // Предотвращаем закрытие при клике внутри поля
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.06),
                            blurRadius: 1,
                            offset: const Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: ref.watch(_exportSearchControllerProvider),
                        autofocus: true,
                        onChanged: (v) {
                          ref.read(exportSearchQueryProvider.notifier).state =
                              v;
                          _performSearch(v);
                        },
                        decoration: InputDecoration(
                          hintText: 'Поиск по наименованию работ...',
                          isDense: true,
                          border: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          icon: Icon(
            query.trim().isNotEmpty ? Icons.close : Icons.search,
            color: query.trim().isNotEmpty ? Colors.red : null,
          ),
          onPressed: () {
            if (query.trim().isNotEmpty) {
              ref.read(exportSearchQueryProvider.notifier).state = '';
              // Если есть выбранный объект, загружаем его работы
              final selectedObjectId = ref.read(exportSelectedObjectIdProvider);
              if (selectedObjectId != null) {
                final filters = ref.read(exportSearchFilterProvider);
                ref.read(workSearchProvider.notifier).searchMaterials(
                      objectId: selectedObjectId,
                      searchQuery: null,
                      systemFilters: filters['system']?.toList(),
                      sectionFilters: filters['section']?.toList(),
                      floorFilters: filters['floor']?.toList(),
                    );
              } else {
                ref.read(workSearchProvider.notifier).clearResults();
              }
            } else {
              final v = !ref.read(exportSearchVisibleProvider);
              ref.read(exportSearchVisibleProvider.notifier).state = v;
            }
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import '../../domain/entities/timesheet_entry.dart';

/// Провайдеры состояния поиска табеля
final timesheetSearchQueryProvider = StateProvider<String>((ref) => '');

/// Видимость поля поиска в AppBar
final timesheetSearchVisibleProvider = StateProvider<bool>((ref) => false);

/// Режим фильтрации списка сотрудников табеля по сумме часов за выбранный период.
enum TimesheetEmployeeListScope {
  /// Базовый список (фильтр по объектам и правила для уволенных без изменений).
  all,

  /// Только сотрудники с суммой часов в периоде больше нуля.
  withHours,

  /// Только сотрудники с нулевой суммой часов в периоде (в том числе без строк в табеле).
  withoutHours,
}

/// Активный режим отображения списка сотрудников ([TimesheetEmployeeListScope]).
final timesheetEmployeeListScopeProvider =
    StateProvider<TimesheetEmployeeListScope>(
      (ref) => TimesheetEmployeeListScope.all,
    );

/// Контроллер поля ввода поиска с авто-диспозом
final _timesheetSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final initial = ref.read(timesheetSearchQueryProvider);
      final controller = TextEditingController(text: initial);
      ref.onDispose(controller.dispose);

      // Синхронизируемся при внешнем изменении провайдера
      ref.listen<String>(timesheetSearchQueryProvider, (prev, next) {
        if (controller.text != next) {
          controller.text = next;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      });

      return controller;
    });

/// Виджет поиска по ФИО в шапке экрана табеля: раскрываемое поле и кнопка «хрома».
class TimesheetSearchAction extends ConsumerWidget {
  /// Конструктор виджета действий поиска.
  const TimesheetSearchAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final appearance = MobileAtmosphereAppearance.of(context);
    final visible = ref.watch(timesheetSearchVisibleProvider);
    final query = ref.watch(timesheetSearchQueryProvider);
    final hasQuery = query.trim().isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: visible ? 420 : 0,
          child: visible
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: appearance.chromeFill,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: appearance.chromeBorder),
                    ),
                    child: TextField(
                      controller: ref.watch(_timesheetSearchControllerProvider),
                      autofocus: true,
                      onChanged: (value) =>
                          ref
                                  .read(timesheetSearchQueryProvider.notifier)
                                  .state =
                              value,
                      decoration: InputDecoration(
                        hintText: 'Поиск по ФИО...',
                        isDense: true,
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 40,
                        ),
                        border: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        prefixIcon: Icon(
                          Icons.person_search_rounded,
                          size: 20,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        MobileAtmosphereChromeCircleButton(
          appearance: appearance,
          tooltip: hasQuery ? 'Очистить поиск' : 'Поиск по ФИО',
          icon: hasQuery ? Icons.close_rounded : Icons.search_rounded,
          iconColor: hasQuery ? scheme.error : null,
          onTap: () {
            if (hasQuery) {
              ref.read(timesheetSearchQueryProvider.notifier).state = '';
            } else {
              final newVisible = !ref.read(timesheetSearchVisibleProvider);
              ref.read(timesheetSearchVisibleProvider.notifier).state =
                  newVisible;
            }
          },
        ),
      ],
    );
  }
}

/// Фильтр записей табеля по выбранным объектам (только UI, без перезапроса).
List<TimesheetEntry> filterTimesheetByObjects(
  List<TimesheetEntry> entries,
  List<String>? objectIds,
) {
  if (objectIds == null || objectIds.isEmpty) return entries;
  final ids = objectIds.toSet();
  return entries.where((e) => ids.contains(e.objectId)).toList();
}

/// Утилита фильтрации записей табеля по ФИО сотрудника
List<TimesheetEntry> filterTimesheetByEmployeeName(
  List<TimesheetEntry> entries,
  String query,
) {
  final searchQuery = query.trim().toLowerCase();
  if (searchQuery.isEmpty) return entries;

  return entries.where((entry) {
    final employeeName = (entry.employeeName ?? '').toLowerCase();
    // Поиск по частичному совпадению в ФИО
    return employeeName.contains(searchQuery);
  }).toList();
}

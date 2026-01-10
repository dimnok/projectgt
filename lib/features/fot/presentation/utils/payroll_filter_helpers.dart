import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../providers/payroll_filter_providers.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';

/// Вспомогательные функции для работы с компактными фильтрами ФОТ.
class PayrollFilterHelpers {
  /// Получает отображаемое имя объекта или количество выбранных.
  static String getObjectName(WidgetRef ref, List<String> selectedIds) {
    if (selectedIds.isEmpty) return 'Все объекты';
    final objects = ref.watch(availableObjectsForPayrollProvider);
    if (selectedIds.length == 1) {
      final obj = objects.firstWhereOrNull((o) => o.id == selectedIds.first);
      return obj?.name ?? 'Объект';
    }
    return 'Выбрано: ${selectedIds.length}';
  }

  /// Переключает на следующий/предыдущий объект (одиночный выбор).
  static void handleObjectSwitch(
    WidgetRef ref,
    List<String> selectedIds,
    int delta,
  ) {
    final objects = ref.read(availableObjectsForPayrollProvider);
    if (objects.isEmpty) return;

    String? currentId;
    if (selectedIds.length == 1) {
      currentId = selectedIds.first;
    }

    int currentIndex = -1;
    if (currentId != null) {
      currentIndex = objects.indexWhere((o) => o.id == currentId);
    }

    int nextIndex;
    if (currentIndex == -1) {
      nextIndex = delta > 0 ? 0 : objects.length - 1;
    } else {
      nextIndex = (currentIndex + delta) % objects.length;
      if (nextIndex < 0) nextIndex = objects.length - 1;
    }

    ref.read(payrollFilterProvider.notifier).setSelectedObjects([
      objects[nextIndex].id as String,
    ]);
  }

  /// Показывает компактное окно выбора месяца.
  static void showMonthSelection(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final filterState = ref.watch(payrollFilterProvider);
            final currentYear = filterState.selectedYear;

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: DesktopDialogContent(
                title: 'Выбор периода',
                width: 350,
                footer: GTPrimaryButton(
                  text: 'Текущий месяц',
                  onPressed: () {
                    final now = DateTime.now();
                    ref
                        .read(payrollFilterProvider.notifier)
                        .setYearAndMonth(now.year, now.month);
                    Navigator.pop(context);
                  },
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Переключатель года
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => ref
                              .read(payrollFilterProvider.notifier)
                              .setYearAndMonth(
                                currentYear - 1,
                                filterState.selectedMonth,
                              ),
                        ),
                        Text(
                          '$currentYear',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => ref
                              .read(payrollFilterProvider.notifier)
                              .setYearAndMonth(
                                currentYear + 1,
                                filterState.selectedMonth,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Сетка месяцев
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected = filterState.selectedMonth == month;
                        final monthName = DateFormat(
                          'MMMM',
                          'ru',
                        ).format(DateTime(currentYear, month));

                        return InkWell(
                          onTap: () {
                            ref
                                .read(payrollFilterProvider.notifier)
                                .setYearAndMonth(currentYear, month);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline
                                          .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              monthName.substring(0, 1).toUpperCase() +
                                  monthName.substring(1, 3),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : null,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Показывает компактное окно выбора объектов.
  static void showObjectSelection(BuildContext context, WidgetRef ref) {
    final objects = ref.read(availableObjectsForPayrollProvider);
    if (objects.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final filterState = ref.watch(payrollFilterProvider);
            final selectedIds = filterState.selectedObjectIds;

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: DesktopDialogContent(
                title: 'Выбор объектов',
                width: 400,
                footer: GTPrimaryButton(
                  text: 'Закрыть',
                  onPressed: () => Navigator.pop(context),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Все объекты'),
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: Checkbox(
                        value: selectedIds.isEmpty,
                        onChanged: (val) {
                          ref
                              .read(payrollFilterProvider.notifier)
                              .setSelectedObjects([]);
                        },
                      ),
                      onTap: () {
                        ref
                            .read(payrollFilterProvider.notifier)
                            .setSelectedObjects([]);
                      },
                    ),
                    const Divider(height: 1),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: SingleChildScrollView(
                        child: Column(
                          children: objects.map((obj) {
                            final isSelected = selectedIds.contains(obj.id);
                            return ListTile(
                              title: Text(obj.name),
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  final newList = List<String>.from(
                                    selectedIds,
                                  );
                                  if (val == true) {
                                    newList.add(obj.id as String);
                                  } else {
                                    newList.remove(obj.id as String);
                                  }
                                  ref
                                      .read(payrollFilterProvider.notifier)
                                      .setSelectedObjects(newList);
                                },
                              ),
                              onTap: () {
                                final newList = List<String>.from(selectedIds);
                                if (isSelected) {
                                  newList.remove(obj.id as String);
                                } else {
                                  newList.add(obj.id as String);
                                }
                                ref
                                    .read(payrollFilterProvider.notifier)
                                    .setSelectedObjects(newList);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

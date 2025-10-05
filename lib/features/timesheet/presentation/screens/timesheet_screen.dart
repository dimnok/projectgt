import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import '../providers/timesheet_provider.dart';
import '../widgets/timesheet_filter_widget.dart';
import '../widgets/timesheet_calendar_view.dart';
import '../widgets/timesheet_pdf_action.dart';

/// Основной экран модуля "Табель" для отображения рабочих часов сотрудников.
class TimesheetScreen extends ConsumerWidget {
  /// Создает экран табеля.
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheetState = ref.watch(timesheetProvider);
    final searchQuery = ref.watch(timesheetSearchQueryProvider);

    // Фильтруем записи по поисковому запросу
    final filteredEntries = filterTimesheetByEmployeeName(
      timesheetState.entries,
      searchQuery,
    );

    return Scaffold(
      appBar: const AppBarWidget(
        title: 'Табель рабочего времени',
        actions: [
          TimesheetSearchAction(),
          SizedBox(width: 8),
          TimesheetFiltersAction(),
          SizedBox(width: 8),
          TimesheetPdfAction(),
          SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.timesheet),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Сообщение об ошибке
          if (timesheetState.error != null)
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timesheetState.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          // Контент табеля с loader только поверх данных
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withAlpha(51),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      TimesheetCalendarView(
                        entries:
                            filteredEntries, // Используем отфильтрованные записи
                        startDate: timesheetState.startDate,
                        endDate: timesheetState.endDate,
                      ),
                      if (timesheetState.isLoading)
                        Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.8),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

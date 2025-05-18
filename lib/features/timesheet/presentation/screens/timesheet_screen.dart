import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import '../providers/timesheet_provider.dart';
import '../widgets/timesheet_filter_widget.dart';
import '../widgets/timesheet_calendar_view.dart';

/// Основной экран модуля "Табель" для отображения рабочих часов сотрудников.
class TimesheetScreen extends ConsumerWidget {
  /// Создает экран табеля.
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheetState = ref.watch(timesheetProvider);
    
    return Scaffold(
      appBar: const AppBarWidget(title: 'Табель рабочего времени'),
      drawer: const AppDrawer(activeRoute: AppRoute.timesheet),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Фильтры
          const TimesheetFilterWidget(),
          // Сообщение об ошибке
          if (timesheetState.error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    timesheetState.error!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
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
                        entries: timesheetState.entries,
                        startDate: timesheetState.startDate,
                        endDate: timesheetState.endDate,
                      ),
                      if (timesheetState.isLoading)
                        Container(
                          color: Colors.black.withValues(alpha: 0.04),
                          child: const Center(child: CircularProgressIndicator()),
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
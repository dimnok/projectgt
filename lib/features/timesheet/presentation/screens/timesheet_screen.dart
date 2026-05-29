import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_main_surface.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

import '../providers/timesheet_provider.dart';
import '../widgets/timesheet_filter_widget.dart';
import '../widgets/timesheet_calendar_view.dart';
import '../widgets/timesheet_hours_loading_indicator.dart';

/// Отступы шапки и тела — как у экрана списка договоров ([gridGutter] 16).
const _kTimesheetHeaderPadding = EdgeInsets.fromLTRB(16, 20, 16, 8);
const _kTimesheetBodyPadding = EdgeInsets.fromLTRB(16, 0, 16, 10);

/// Основной экран модуля «Табель»: фон и шапка в стиле списка договоров
/// ([MobileAtmosphereBackdrop], круглый «хром» для меню и темы).
class TimesheetScreen extends ConsumerWidget {
  /// Создаёт экран табеля.
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheetState = ref.watch(timesheetProvider);
    final searchQuery = ref.watch(timesheetSearchQueryProvider);
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;

    final filteredEntries = filterTimesheetByEmployeeName(
      filterTimesheetByObjects(
        timesheetState.entries,
        timesheetState.selectedObjectIds,
      ),
      searchQuery,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? appearance.atmosphereBase
            : Colors.transparent,
        drawer: const AppDrawer(activeRoute: AppRoute.timesheet),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: _kTimesheetHeaderPadding,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 560;
                        final menuButton = Builder(
                          builder: (ctx) => MobileAtmosphereChromeCircleButton(
                            appearance: appearance,
                            tooltip: 'Меню',
                            icon: Icons.menu_rounded,
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        );
                        final themeButton = MobileAtmosphereChromeCircleButton(
                          appearance: appearance,
                          tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
                          icon: isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          onTap: () {
                            ref
                                .read(themeSettingsProvider.notifier)
                                .setThemeMode(
                                  isDark ? ThemeMode.light : ThemeMode.dark,
                                );
                          },
                        );
                        final actions = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TimesheetSearchAction(),
                            const SizedBox(width: 4),
                            themeButton,
                          ],
                        );

                        if (narrow) {
                          return MobileAtmosphereScreenHeader(
                            appearance: appearance,
                            title: 'Табель рабочего времени',
                            leading: menuButton,
                            trailing: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: actions,
                            ),
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            menuButton,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Табель рабочего времени',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: scheme.onSurface),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  reverse: true,
                                  child: actions,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (timesheetState.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            timesheetState.error!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: _kTimesheetBodyPadding,
                      child: MobileAtmosphereMainSurface(
                        child: Stack(
                          children: [
                            TimesheetCalendarView(
                              entries: filteredEntries,
                              startDate: timesheetState.startDate,
                              endDate: timesheetState.endDate,
                              employeeNameSearchQuery: searchQuery,
                            ),
                            if (timesheetState.isLoading)
                              ColoredBox(
                                color: scheme.surface.withValues(alpha: 0.8),
                                child: const TimesheetHoursLoadingIndicator(),
                              ),
                          ],
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
}

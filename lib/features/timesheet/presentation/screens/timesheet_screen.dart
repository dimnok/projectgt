import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_main_surface.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

import '../providers/timesheet_employees_catalog_sync.dart';
import '../providers/timesheet_provider.dart';
import '../widgets/timesheet_calendar_view.dart';
import '../widgets/timesheet_mobile_search_field.dart';
import '../widgets/timesheet_hours_loading_indicator.dart';

/// Отступы шапки и тела — как у экрана списка договоров ([gridGutter] 16).
const _kTimesheetHeaderPadding = EdgeInsets.fromLTRB(16, 20, 16, 8);
const _kTimesheetBodyPadding = EdgeInsets.fromLTRB(16, 0, 16, 10);

/// Основной экран модуля «Табель»: фон и шапка в стиле списка договоров
/// ([MobileAtmosphereBackdrop], круглый «хром» для меню и темы).
class TimesheetScreen extends ConsumerStatefulWidget {
  /// Создаёт экран табеля.
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(timesheetEmployeesCatalogSyncProvider);
    final timesheetState = ref.watch(timesheetProvider);
    final gridEntries = ref.watch(timesheetGridEntriesProvider);
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;

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
                        final useMobileList =
                            EmployeesLayoutUtils.useEmployeesMobileList(
                              context,
                            );
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
                        const titleText = 'Табель рабочего времени';

                        if (useMobileList) {
                          return Row(
                            children: [
                              menuButton,
                              const SizedBox(width: 8),
                              const Expanded(
                                child: TimesheetMobileSearchField(),
                              ),
                              const SizedBox(width: 8),
                              themeButton,
                            ],
                          );
                        }

                        if (narrow) {
                          return MobileAtmosphereScreenHeader(
                            appearance: appearance,
                            title: titleText,
                            leading: menuButton,
                            trailing: themeButton,
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            menuButton,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                titleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: scheme.onSurface),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: themeButton,
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
                              entries: gridEntries,
                              startDate: timesheetState.startDate,
                              endDate: timesheetState.endDate,
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

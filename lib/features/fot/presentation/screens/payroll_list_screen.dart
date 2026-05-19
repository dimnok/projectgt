import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_main_surface.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart'
    show AppRoute, AppDrawer;

import '../../../../core/di/providers.dart';
import '../../../../presentation/state/employee_state.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../providers/payroll_filter_providers.dart';
import '../providers/payroll_providers.dart';
import '../widgets/payroll_export_action.dart';
import '../widgets/payroll_search_action.dart';
import '../widgets/payroll_tab_segment.dart';
import '../widgets/payroll_table_widget.dart';
import 'tabs/payroll_tab_bonuses.dart';
import 'tabs/payroll_tab_penalties.dart';
import 'tabs/payroll_tab_payouts.dart';

/// Отступы шапки и тела — как у экрана табеля.
const _kPayrollHeaderPadding = EdgeInsets.fromLTRB(16, 20, 16, 8);
const _kPayrollBodyPadding = EdgeInsets.fromLTRB(16, 0, 16, 10);

/// Экран списка расчётов ФОТ: фон и шапка в стиле модуля «Табель».
class PayrollListScreen extends ConsumerStatefulWidget {
  /// Конструктор экрана списка расчётов ФОТ.
  const PayrollListScreen({super.key});

  @override
  ConsumerState<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends ConsumerState<PayrollListScreen> {
  bool _initialLoadStarted = false;
  int _selectedTabIndex = 0;

  static const List<String> _monthNames = [
    'январь',
    'февраль',
    'март',
    'апрель',
    'май',
    'июнь',
    'июль',
    'август',
    'сентябрь',
    'октябрь',
    'ноябрь',
    'декабрь',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeData);
  }

  Future<void> _initializeData() async {
    if (_initialLoadStarted) return;
    _initialLoadStarted = true;

    try {
      await Future.wait([
        ref.read(employeeProvider.notifier).getEmployees(),
        ref.read(objectProvider.notifier).loadObjects(),
      ]);
      ref.invalidate(filteredPayrollsProvider);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load initial payroll data',
        name: 'fot.PayrollListScreen._initializeData',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  String _screenTitle(PayrollFilterState filterState) {
    return 'ФОТ — ${_monthNames[filterState.selectedMonth - 1]} '
        '${filterState.selectedYear}';
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(payrollFilterProvider);
    final payrollsAsync = ref.watch(filteredPayrollsProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);
    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
    final isDark = appearance.isDark;
    final title = _screenTitle(filterState);

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
        drawer: const AppDrawer(activeRoute: AppRoute.payrolls),
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
                    padding: _kPayrollHeaderPadding,
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

                        final exportButton = _selectedTabIndex == 3
                            ? null
                            : const PermissionGuard(
                                module: 'payroll',
                                permission: 'export',
                                child: PayrollExportAction(),
                              );

                        final actions = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PayrollSearchAction(),
                            if (exportButton != null) ...[
                              const SizedBox(width: 4),
                              exportButton,
                            ],
                            const SizedBox(width: 4),
                            themeButton,
                          ],
                        );

                        if (narrow) {
                          return MobileAtmosphereScreenHeader(
                            appearance: appearance,
                            title: title,
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
                                title,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: PayrollTabSegment(
                      selectedIndex: _selectedTabIndex,
                      onChanged: (index) {
                        setState(() => _selectedTabIndex = index);
                        final query = ref.read(payrollSearchQueryProvider);
                        if (query.trim().isEmpty) {
                          ref.read(payrollSearchVisibleProvider.notifier).state =
                              false;
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: _kPayrollBodyPadding,
                      child: MobileAtmosphereMainSurface(
                        child: IndexedStack(
                          index: _selectedTabIndex,
                          children: [
                            _buildFotTab(payrollsAsync, searchQuery),
                            const PayrollTabBonuses(),
                            const PayrollTabPenalties(),
                            const PayrollTabPayouts(),
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

  Widget _buildFotTab(
    AsyncValue<List<PayrollCalculation>> payrollsAsync,
    String searchQuery,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return payrollsAsync.when(
      data: (payrolls) {
        final filteredPayrolls = filterPayrollsByEmployeeName(
          payrolls,
          searchQuery,
          ref,
        );
        return PayrollTableWidget(payrolls: filteredPayrolls);
      },
      loading: () => ColoredBox(
        color: scheme.surface.withValues(alpha: 0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Загрузка данных ФОТ...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: scheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки данных',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 300,
              child: Text(
                e.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              onPressed: () => ref.invalidate(filteredPayrollsProvider),
            ),
          ],
        ),
      ),
    );
  }
}

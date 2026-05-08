import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart'
    show AppRoute, AppDrawer;
import '../widgets/payroll_table_widget.dart';
import '../widgets/payroll_search_action.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_filter_providers.dart';
import '../../../../features/export/presentation/providers/repositories_providers.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'tabs/payroll_tab_penalties.dart';
import 'tabs/payroll_tab_bonuses.dart';
import 'tabs/payroll_tab_payouts.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/payroll_calculation.dart';

/// Экран: Список расчётов ФОТ за текущий месяц.
class PayrollListScreen extends ConsumerStatefulWidget {
  /// Конструктор экрана списка расчётов ФОТ.
  ///
  /// [key] — ключ виджета.
  const PayrollListScreen({super.key});

  @override
  ConsumerState<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends ConsumerState<PayrollListScreen> {
  bool _initialLoadStarted = false;
  int _selectedTabIndex = 0;

  // Цвета для thumb в зависимости от таба
  static const Map<int, Color> _thumbColors = {
    0: Color(0xFFFFFFFF), // ФОТ - белый
    1: Color(0xFF64B5F6), // Премии - голубой (Material Blue 300)
    2: Color(0xFFEF5350), // Штрафы - красноватый (Material Red 400)
    3: Color(0xFF66BB6A), // Выплаты - зелененький (Material Green 400)
  };

  // Динамические сегменты с контрастным текстом
  Map<int, Widget> _buildTabSegments(bool isDark, bool isMobile) {
    final verticalPadding = isMobile ? 4.0 : 8.0;
    final fontSize = isMobile ? 12.0 : 14.0;

    return {
      0: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
        child: Text(
          'ФОТ',
          style: TextStyle(
            fontSize: fontSize,
            color: _selectedTabIndex == 0
                ? Colors
                      .black87 // Тёмный текст на белом thumb
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
      1: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
        child: Text(
          'Премии',
          style: TextStyle(
            fontSize: fontSize,
            color: _selectedTabIndex == 1
                ? Colors
                      .white // Светлый текст на голубом thumb
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
      2: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
        child: Text(
          'Штрафы',
          style: TextStyle(
            fontSize: fontSize,
            color: _selectedTabIndex == 2
                ? Colors
                      .white // Светлый текст на красном thumb
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
      3: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding),
        child: Text(
          'Выплаты',
          style: TextStyle(
            fontSize: fontSize,
            color: _selectedTabIndex == 3
                ? Colors
                      .white // Светлый текст на зелёном thumb
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    };
  }

  static const List<String> monthNames = [
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
    // Запускаем инициализацию данных с небольшой задержкой после построения виджета
    Future.microtask(() => _initializeData());
  }

  // Метод инициализации всех необходимых данных
  Future<void> _initializeData() async {
    if (_initialLoadStarted) return;
    _initialLoadStarted = true;

    try {
      // 🚀 ОПТИМИЗАЦИЯ: Параллельная загрузка базовых данных
      await Future.wait([
        ref.read(employeeProvider.notifier).getEmployees(),
        ref.read(objectProvider.notifier).loadObjects(),
      ]);

      // Принудительно обновляем провайдер filteredPayrolls
      // (теперь он использует RPC и не зависит от employees/objects)
      ref.invalidate(filteredPayrollsProvider);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load initial payroll data',
        name: 'fot.PayrollListScreen._loadInitialData',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Экспортирует данные ФОТ в Excel через сервер
  Future<void> _exportToExcel() async {
    try {
      final filterState = ref.read(payrollFilterProvider);
      final activeCompanyId = ref.read(activeCompanyIdProvider);

      if (activeCompanyId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: компания не выбрана')),
        );
        return;
      }

      // Показываем индикатор загрузки
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Подготовка Excel на сервере...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final exportService = ref.read(workSearchExportServerServiceProvider);
      final searchQuery = ref.read(payrollSearchQueryProvider);

      final result = await exportService.exportPayroll(
        year: filterState.selectedYear,
        month: filterState.selectedMonth,
        companyId: activeCompanyId,
        objectIds: filterState.selectedObjectIds,
        searchQuery: searchQuery,
      );

      if (!mounted) return;

      if (result.success) {
        if (result.filePath == 'cancelled') return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ФОТ успешно выгружена: ${result.filename}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollFilterProvider);
    final isMobile = ResponsiveUtils.isMobile(context);

    // Используем filteredPayrollsProvider для получения данных
    final payrollsAsync = ref.watch(filteredPayrollsProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title:
            'ФОТ — ${monthNames[filterState.selectedMonth - 1]} ${filterState.selectedYear}',
        actions: [
          if (!isMobile) ...[
            const PayrollSearchAction(),
            const SizedBox(width: 8),
          ],
          if (!isMobile && _selectedTabIndex != 3) ...[
            // Кнопка экспорта в Excel
            PermissionGuard(
              module: 'payroll',
              permission: 'export',
              child: IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Экспорт в Excel',
                onPressed: _exportToExcel,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.payrolls),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- iOS-стиль с плавающим цветным переключателем ---
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 24.0,
              vertical: isMobile ? 8.0 : 16.0,
            ),
            child: CupertinoSlidingSegmentedControl<int>(
              children: _buildTabSegments(theme.brightness == Brightness.dark, isMobile),
              groupValue: _selectedTabIndex,
              onValueChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _selectedTabIndex = value;
                  });
                  // При смене таба, если поле поиска пустое, скрываем его
                  final searchQuery = ref.read(payrollSearchQueryProvider);
                  if (searchQuery.trim().isEmpty) {
                    ref.read(payrollSearchVisibleProvider.notifier).state =
                        false;
                  }
                }
              },
              backgroundColor: CupertinoColors.systemGrey6,
              thumbColor: _thumbColors[_selectedTabIndex] ?? Colors.white,
              padding: const EdgeInsets.all(2),
            ),
          ),
          // --- Контент табов ---
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                // --- Таб 0: ФОТ ---
                _buildTabContent(
                  context,
                  ref,
                  theme,
                  payrollsAsync,
                  searchQuery,
                ),
                // --- Таб 1: Премии ---
                const PayrollTabBonuses(),
                // --- Таб 2: Штрафы ---
                const PayrollTabPenalties(),
                // --- Таб 3: Выплаты ---
                const PayrollTabPayouts(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AsyncValue<List<PayrollCalculation>> payrollsAsync,
    String searchQuery,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final content = payrollsAsync.when(
      data: (payrolls) {
        final filteredPayrolls = filterPayrollsByEmployeeName(
          payrolls,
          searchQuery,
          ref,
        );
        return PayrollTableWidget(payrolls: filteredPayrolls);
      },
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Загрузка данных ФОТ...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки данных',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 300,
              child: Text(
                e.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              onPressed: () {
                ref.invalidate(filteredPayrollsProvider);
              },
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return content;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(16.0), child: content),
      ),
    );
  }
}

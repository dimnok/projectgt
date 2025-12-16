import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart'
    show AppRoute, AppDrawer;
import '../widgets/payroll_table_widget.dart';
import '../widgets/payroll_search_action.dart';
import '../widgets/payroll_filter_widget.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_filter_providers.dart';
import '../providers/payroll_export_providers.dart';
import '../providers/balance_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'tabs/payroll_tab_penalties.dart';
import 'tabs/payroll_tab_bonuses.dart';
import 'tabs/payroll_tab_payouts.dart';

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
  Map<int, Widget> _buildTabSegments(bool isDark) {
    return {
      0: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'ФОТ',
          style: TextStyle(
            color: _selectedTabIndex == 0
                ? Colors.black87 // Тёмный текст на белом thumb
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
      1: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Премии',
          style: TextStyle(
            color: _selectedTabIndex == 1
                ? Colors.white // Светлый текст на голубом thumb
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
      2: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Штрафы',
          style: TextStyle(
            color: _selectedTabIndex == 2
                ? Colors.white // Светлый текст на красном thumb
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
      3: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Выплаты',
          style: TextStyle(
            color: _selectedTabIndex == 3
                ? Colors.white // Светлый текст на зелёном thumb
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
    'декабрь'
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
    } catch (e) {
      // Игнорируем ошибки инициализации
    }
  }

  /// Экспортирует данные ФОТ в Excel
  Future<void> _exportToExcel() async {
    try {
      final filterState = ref.read(payrollFilterProvider);
      final payrolls = ref.read(filteredPayrollsProvider).asData?.value ?? [];
      final payoutsMapAsync =
          ref.read(payoutsByEmployeeAndMonthFIFOProvider).asData?.value ?? {};
      final balanceAsync =
          ref.read(employeeAggregatedBalanceProvider).asData?.value ?? {};

      if (payrolls.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет данных для экспорта')),
        );
        return;
      }

      // Формируем маппы как в таблице (FIFO распределение)
      final payoutsByEmployee = <String, double>{};
      final currentMonth = filterState.selectedMonth;

      for (final empId in payoutsMapAsync.keys) {
        final payoutsForAllMonths = payoutsMapAsync[empId] ?? {};
        payoutsByEmployee[empId] = payoutsForAllMonths[currentMonth] ?? 0;
      }

      // Вызываем экспорт через провайдер
      await ref.read(exportPayrollToExcelProvider(
        {
          'payrolls': payrolls,
          'payoutsByEmployee': payoutsByEmployee,
          'aggregatedBalance': balanceAsync,
          'year': filterState.selectedYear,
          'month': filterState.selectedMonth,
        },
      ).future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ ФОТ выгружена в Excel')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка экспорта: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollFilterProvider);

    // Используем filteredPayrollsProvider для получения данных
    final payrollsAsync = ref.watch(filteredPayrollsProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);

    return Scaffold(
      appBar: AppBarWidget(
        title:
            'ФОТ — ${monthNames[filterState.selectedMonth - 1]} ${filterState.selectedYear}',
        actions: [
          const PayrollSearchAction(),
          const SizedBox(width: 8),
          if (_selectedTabIndex != 3) ...[
            const PayrollFiltersAction(),
            const SizedBox(width: 8),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: CupertinoSlidingSegmentedControl<int>(
              children: _buildTabSegments(theme.brightness == Brightness.dark),
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 51),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: payrollsAsync.when(
                        data: (payrolls) {
                          // Применяем фильтрацию по поисковому запросу
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
                              Text(
                                'Загрузка данных ФОТ...',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        error: (e, st) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Ошибка загрузки данных',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 300,
                                child: Text(
                                  e.toString(),
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.red),
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
                      ),
                    ),
                  ),
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
}

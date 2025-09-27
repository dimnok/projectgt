import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart'
    show AppRoute, AppDrawer;
import '../widgets/payroll_filter_widget.dart';
import '../widgets/payroll_payout_filter_widget.dart';
import '../widgets/payroll_table_widget.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_filter_provider.dart';
import '../providers/balance_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'tabs/payroll_tab_penalties.dart';
import 'tabs/payroll_tab_bonuses.dart';
import 'tabs/payroll_tab_payouts.dart';

/// Экран: Список расчётов ФОТ за выбранный месяц с применением фильтров.
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
  final List<Tab> _tabs = const [
    Tab(text: 'ФОТ'),
    Tab(text: 'Штрафы'),
    Tab(text: 'Премии'),
    Tab(text: 'Выплаты'),
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
      // Инициализируем данные фильтров (сотрудники и объекты)
      final filterNotifier = ref.read(payrollFilterProvider.notifier);
      // Этот метод запустит загрузку сотрудников и объектов если нужно
      await Future.microtask(() => filterNotifier.updateDataFromProviders());

      // Принудительно обновляем провайдер filteredPayrolls
      ref.invalidate(filteredPayrollsProvider);
    } catch (e) {
      // Игнорируем ошибки инициализации
    }
  }

  // Метод обновления данных с безопасным использованием BuildContext
  void _refreshData() {
    // Обновляем данные work_hours вместо табеля
    ref.invalidate(payrollWorkHoursProvider);
    ref.invalidate(employeeAggregatedBalanceProvider);
    ref.invalidate(payrollPayoutsByMonthProvider);
    final future = ref.refresh(filteredPayrollsProvider.future);
    future.then(
      (_) {
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Данные обновлены');
        }
      },
      onError: (e) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Ошибка: ${e.toString()}');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Проверяем готовность данных перед отображением таблицы
    final isDataReady = ref.watch(payrollDataReadyProvider);

    // Используем filteredPayrollsProvider для получения отфильтрованных данных
    final payrollsAsync = ref.watch(filteredPayrollsProvider);

    // Состояние загрузки work_hours для понимания, что данные загружаются
    final workHoursState = ref.watch(payrollWorkHoursProvider);
    final workHoursLoading = workHoursState.isLoading;

    // Если данные все еще не готовы после инициализации,
    // и прошло уже некоторое время, повторяем инициализацию
    if (!isDataReady && _initialLoadStarted && !workHoursLoading) {
      Future.microtask(() => _initializeData());
    }

    return Scaffold(
      appBar: const AppBarWidget(
        title: 'ФОТ — расчёты за месяц',
        actions: [],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.payrolls),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Фильтры ФОТ - условное отображение в зависимости от выбранного таба
          if (_selectedTabIndex != 3) // Для табов ФОТ, Штрафы, Премии
            const PayrollFilterWidget()
          else // Для таба Выплаты
            const PayrollPayoutFilterWidget(),
          // --- Табы ---
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
            child: DefaultTabController(
              length: _tabs.length,
              initialIndex: _selectedTabIndex,
              child: Builder(
                builder: (context) {
                  final TabController tabController =
                      DefaultTabController.of(context);
                  tabController.addListener(() {
                    if (tabController.indexIsChanging) {
                      setState(() {
                        _selectedTabIndex = tabController.index;
                      });
                    }
                  });
                  return TabBar(
                    tabs: _tabs,
                    controller: tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.outline,
                    indicatorColor: theme.colorScheme.primary,
                  );
                },
              ),
            ),
          ),
          // --- Контент табов ---
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                // --- ФОТ ---
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
                      child: Stack(
                        children: [
                          if (isDataReady)
                            payrollsAsync.when(
                              data: (payrolls) =>
                                  PayrollTableWidget(payrolls: payrolls),
                              loading: () => Container(),
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
                                      onPressed: _refreshData,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!isDataReady ||
                              payrollsAsync.isLoading ||
                              workHoursLoading)
                            Container(
                              color: Colors.black.withValues(alpha: 0.04),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      !isDataReady
                                          ? 'Инициализация данных...'
                                          : 'Загрузка данных...',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // --- Штрафы ---
                const PayrollTabPenalties(),
                // --- Премии ---
                const PayrollTabBonuses(),
                // --- Выплаты ---
                const PayrollTabPayouts(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

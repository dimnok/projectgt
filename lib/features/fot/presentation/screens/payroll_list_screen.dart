import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart' show AppRoute, AppDrawer;
import '../widgets/payroll_filter_widget.dart';
import '../widgets/payroll_table_widget.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_filter_provider.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_provider.dart';

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
      // 1. Сначала загружаем табель
      await ref.read(timesheetProvider.notifier).loadTimesheet();
      
      // 2. Инициализируем данные фильтров (сотрудники и объекты)
      final filterNotifier = ref.read(payrollFilterProvider.notifier);
      // Этот метод запустит загрузку сотрудников и объектов если нужно
      await Future.microtask(() => filterNotifier.updateDataFromProviders());
      
      // 3. Принудительно обновляем провайдер filteredPayrolls
      ref.invalidate(filteredPayrollsProvider);
    } catch (e) {
      // Игнорируем ошибки инициализации
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Проверяем готовность данных перед отображением таблицы
    final isDataReady = ref.watch(payrollDataReadyProvider);
    
    // Используем filteredPayrollsProvider для получения отфильтрованных данных
    final payrollsAsync = ref.watch(filteredPayrollsProvider);
    
    // Состояние загрузки табеля для понимания, что данные загружаются
    final timesheetState = ref.watch(timesheetProvider);
    final timesheetLoading = timesheetState.isLoading;
    
    // Если данные все еще не готовы после инициализации, 
    // и прошло уже некоторое время, повторяем инициализацию
    if (!isDataReady && _initialLoadStarted && !timesheetLoading) {
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
          // Фильтры ФОТ
          const PayrollFilterWidget(),
          
          // Таблица с данными ФОТ
          Expanded(
            child: Padding(
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
                        data: (payrolls) => PayrollTableWidget(payrolls: payrolls),
                        loading: () => Container(),
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
                                  // Сохраняем контекст до асинхронной операции
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    
                                    // Перезагружаем данные табеля сначала
                                    ref.read(timesheetProvider.notifier).loadTimesheet();
                                    
                                  // Принудительно обновляем провайдер и используем результат
                                  final future = ref.refresh(filteredPayrollsProvider.future);
                                    
                                  // Безопасно обрабатываем результат
                                  future.then(
                                    (_) => scaffoldMessenger.showSnackBar(
                                      const SnackBar(content: Text('Данные обновлены'))
                                    ),
                                    onError: (e) => scaffoldMessenger.showSnackBar(
                                      SnackBar(content: Text('Ошибка: ${e.toString()}'))
                                    )
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Показываем индикатор загрузки, пока данные не готовы
                      if (!isDataReady || payrollsAsync.isLoading || timesheetLoading)
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
          ),
        ],
      ),
    );
  }
} 
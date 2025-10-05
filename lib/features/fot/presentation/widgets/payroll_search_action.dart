import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../domain/entities/payroll_transaction.dart';
import '../../data/models/payroll_payout_model.dart';
import '../../../../presentation/state/employee_state.dart';
import '../providers/payroll_filter_providers.dart';
import '../providers/payroll_providers.dart';

/// Провайдер состояния поиска в модуле ФОТ
final payrollSearchQueryProvider = StateProvider<String>((ref) => '');

/// Видимость поля поиска в AppBar модуля ФОТ
final payrollSearchVisibleProvider = StateProvider<bool>((ref) => false);

/// Виджет действий поиска для AppBar модуля ФОТ: анимированное поле + кнопка лупы
///
/// Позволяет искать сотрудников по ФИО в расчётах ФОТ.
/// При клике на иконку лупы открывается поле ввода для поиска.
/// При заполненном поле иконка меняется на крестик для очистки.
///
/// **Автоматическое скрытие:**
/// - При потере фокуса (если поле пустое)
/// - При нажатии клавиши ESC
/// - При клике вне поля поиска
class PayrollSearchAction extends ConsumerStatefulWidget {
  /// Создаёт виджет поиска для AppBar модуля ФОТ.
  const PayrollSearchAction({super.key});

  @override
  ConsumerState<PayrollSearchAction> createState() =>
      _PayrollSearchActionState();
}

class _PayrollSearchActionState extends ConsumerState<PayrollSearchAction> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Инициализируем контроллер значением из провайдера
    _controller.text = ref.read(payrollSearchQueryProvider);

    // Слушаем изменения в провайдере для синхронизации
    ref.listenManual(payrollSearchQueryProvider, (prev, next) {
      if (_controller.text != next) {
        _controller.text = next;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    });

    // Слушаем потерю фокуса
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Обработчик изменения фокуса
  void _onFocusChange() {
    // Если поле потеряло фокус и текст пустой - скрываем поле поиска
    if (!_focusNode.hasFocus) {
      final query = ref.read(payrollSearchQueryProvider);
      if (query.trim().isEmpty) {
        ref.read(payrollSearchVisibleProvider.notifier).state = false;
      }
    }
  }

  /// Обработчик нажатия клавиши ESC
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      final query = ref.read(payrollSearchQueryProvider);
      if (query.trim().isEmpty) {
        // Если поле пустое - скрываем
        ref.read(payrollSearchVisibleProvider.notifier).state = false;
      } else {
        // Если есть текст - очищаем
        ref.read(payrollSearchQueryProvider.notifier).state = '';
        _focusNode.requestFocus(); // Возвращаем фокус
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(payrollSearchQueryProvider);
    final isVisible = ref.watch(payrollSearchVisibleProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isVisible
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: _handleKeyEvent,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        onChanged: (value) => ref
                            .read(payrollSearchQueryProvider.notifier)
                            .state = value,
                        decoration: InputDecoration(
                          hintText: 'Поиск по ФИО...',
                          isDense: true,
                          border: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          prefixIcon: const Icon(Icons.person_search, size: 20),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          icon: Icon(
            query.trim().isNotEmpty ? Icons.close : Icons.search,
            color: query.trim().isNotEmpty ? Colors.red : null,
          ),
          tooltip: query.trim().isNotEmpty ? 'Очистить поиск' : 'Поиск по ФИО',
          onPressed: () {
            if (query.trim().isNotEmpty) {
              // Очищаем поиск
              ref.read(payrollSearchQueryProvider.notifier).state = '';
              _focusNode.requestFocus(); // Возвращаем фокус после очистки
            } else {
              // Переключаем видимость поля поиска
              final newVisible = !ref.read(payrollSearchVisibleProvider);
              ref.read(payrollSearchVisibleProvider.notifier).state =
                  newVisible;
              if (newVisible) {
                // Даём время на анимацию, затем фокусируем
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _focusNode.requestFocus();
                  }
                });
              }
            }
          },
        ),
      ],
    );
  }
}

/// Функция фильтрации расчётов ФОТ по ФИО, объектам и должностям
///
/// Применяет последовательную фильтрацию:
/// 1. По поисковому запросу (ФИО)
/// 2. По выбранным должностям
/// 3. По выбранным объектам
List<PayrollCalculation> filterPayrollsByEmployeeName(
  List<PayrollCalculation> payrolls,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final filterState = ref.watch(payrollFilterProvider);

  var filteredPayrolls = payrolls;

  // 1. Фильтрация по поисковому запросу (ФИО)
  if (searchQuery.isNotEmpty) {
    filteredPayrolls = filteredPayrolls.where((payroll) {
      final employee =
          employees.where((e) => e.id == payroll.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  // 2. Фильтрация по должностям
  if (filterState.selectedPositions.isNotEmpty) {
    filteredPayrolls = filteredPayrolls.where((payroll) {
      final employee =
          employees.where((e) => e.id == payroll.employeeId).firstOrNull;

      if (employee == null || employee.position == null) return false;

      return filterState.selectedPositions.contains(employee.position);
    }).toList();
  }

  // 3. Фильтрация по объектам (через work_hours)
  if (filterState.selectedObjectIds.isNotEmpty) {
    final workHoursAsync = ref.watch(payrollWorkHoursProvider);

    filteredPayrolls = workHoursAsync.when(
      data: (workHours) {
        final employeeIdsOnSelectedObjects = workHours
            .where((wh) =>
                wh.objectId != null &&
                filterState.selectedObjectIds.contains(wh.objectId))
            .map((wh) => wh.employeeId)
            .toSet();

        return filteredPayrolls
            .where((p) => employeeIdsOnSelectedObjects.contains(p.employeeId))
            .toList();
      },
      loading: () => filteredPayrolls,
      error: (_, __) => filteredPayrolls,
    );
  }

  return filteredPayrolls;
}

/// Функция фильтрации транзакций (премии/штрафы) по ФИО, объектам и должностям
///
/// Применяет последовательную фильтрацию:
/// 1. По поисковому запросу (ФИО)
/// 2. По выбранным должностям
/// 3. По выбранным объектам
List<PayrollTransaction> filterTransactionsByEmployeeName(
  List<PayrollTransaction> transactions,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final filterState = ref.watch(payrollFilterProvider);

  var filteredTransactions = transactions;

  // 1. Фильтрация по поисковому запросу (ФИО)
  if (searchQuery.isNotEmpty) {
    filteredTransactions = filteredTransactions.where((transaction) {
      final employee =
          employees.where((e) => e.id == transaction.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  // 2. Фильтрация по должностям
  if (filterState.selectedPositions.isNotEmpty) {
    filteredTransactions = filteredTransactions.where((transaction) {
      final employee =
          employees.where((e) => e.id == transaction.employeeId).firstOrNull;

      if (employee == null || employee.position == null) return false;

      return filterState.selectedPositions.contains(employee.position);
    }).toList();
  }

  // 3. Фильтрация по объектам
  if (filterState.selectedObjectIds.isNotEmpty) {
    filteredTransactions = filteredTransactions
        .where((transaction) =>
            transaction.objectId != null &&
            filterState.selectedObjectIds.contains(transaction.objectId))
        .toList();
  }

  return filteredTransactions;
}

/// Функция фильтрации выплат по ФИО и должностям
///
/// Применяет последовательную фильтрацию:
/// 1. По поисковому запросу (ФИО)
/// 2. По выбранным должностям
///
/// Примечание: Выплаты не связаны напрямую с объектами, поэтому фильтр по объектам не применяется
List<PayrollPayoutModel> filterPayoutsByEmployeeName(
  List<PayrollPayoutModel> payouts,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final filterState = ref.watch(payrollFilterProvider);

  var filteredPayouts = payouts;

  // 1. Фильтрация по поисковому запросу (ФИО)
  if (searchQuery.isNotEmpty) {
    filteredPayouts = filteredPayouts.where((payout) {
      final employee =
          employees.where((e) => e.id == payout.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  // 2. Фильтрация по должностям
  if (filterState.selectedPositions.isNotEmpty) {
    filteredPayouts = filteredPayouts.where((payout) {
      final employee =
          employees.where((e) => e.id == payout.employeeId).firstOrNull;

      if (employee == null || employee.position == null) return false;

      return filterState.selectedPositions.contains(employee.position);
    }).toList();
  }

  return filteredPayouts;
}

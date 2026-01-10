import 'package:flutter/material.dart';
import '../../../../core/widgets/gt_text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../domain/entities/payroll_transaction.dart';
import '../../data/models/payroll_payout_model.dart';
import '../../../../presentation/state/employee_state.dart';
import '../providers/payroll_filter_providers.dart';

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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GTTextField(
                        controller: _controller,
                        hintText: 'Поиск по ФИО...',
                        prefixIcon: Icons.person_search,
                        onChanged: (value) => ref
                            .read(payrollSearchQueryProvider.notifier)
                            .state = value,
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

/// Функция фильтрации расчётов ФОТ по ФИО и объектам
///
/// Применяет последовательную фильтрацию:
/// 1. По поисковому запросу (ФИО)
/// 2. По выбранным объектам
List<PayrollCalculation> filterPayrollsByEmployeeName(
  List<PayrollCalculation> payrolls,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

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

  // 2. Фильтрация по объектам (уже выполнена на сервере в filteredPayrollsProvider)
  // Оставляем это здесь только для случая fallback (клиентский расчет)
  // или если данные приходят не из RPC. 
  // В идеале RPC уже вернул нужных сотрудников.
  /*
  if (filterState.selectedObjectIds.isNotEmpty) {
    ...
  }
  */

  return filteredPayrolls;
}

/// Функция фильтрации транзакций (премии/штрафы) по ФИО и объектам
///
/// Применяет последовательную фильтрацию:
/// 1. По поисковому запросу (ФИО)
/// 2. По выбранным объектам
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

  // 2. Фильтрация по объектам
  if (filterState.selectedObjectIds.isNotEmpty) {
    filteredTransactions = filteredTransactions
        .where((transaction) =>
            transaction.objectId != null &&
            filterState.selectedObjectIds.contains(transaction.objectId))
        .toList();
  }

  return filteredTransactions;
}

/// Функция фильтрации выплат по ФИО
///
/// Применяет фильтрацию по поисковому запросу (ФИО)
List<PayrollPayoutModel> filterPayoutsByEmployeeName(
  List<PayrollPayoutModel> payouts,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

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

  return filteredPayouts;
}

/// Функция фильтрации списка сотрудников по поисковому запросу
List<dynamic> filterEmployeesBySearchQuery(
  List<dynamic> employees,
  String query,
) {
  final searchQuery = query.trim().toLowerCase();
  if (searchQuery.isEmpty) return employees;

  return employees.where((employee) {
    final fullName = [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName
    ].join(' ').toLowerCase();

    return fullName.contains(searchQuery);
  }).toList();
}

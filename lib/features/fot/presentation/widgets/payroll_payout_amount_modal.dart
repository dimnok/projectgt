import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import '../providers/payroll_providers.dart';
import '../providers/balance_providers.dart';
import '../../data/models/payroll_payout_model.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../core/widgets/gt_text_field.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/mobile_bottom_sheet_content.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../utils/payout_utils.dart';

/// Модальное окно для указания индивидуальных сумм выплат для выбранных сотрудников.
///
/// Второй этап процесса массовых выплат - после выбора сотрудников, даты и способа выплаты
/// пользователь указывает индивидуальную сумму для каждого сотрудника.
class PayrollPayoutAmountModal extends ConsumerStatefulWidget {
  /// Список выбранных сотрудников
  final List<dynamic> selectedEmployees;

  /// Дата выплаты
  final DateTime payoutDate;

  /// Способ выплаты
  final String method;

  /// Тип оплаты
  final String type;

  /// Комментарий
  final String comment;

  /// Конструктор [PayrollPayoutAmountModal].
  ///
  /// [selectedEmployees] — список выбранных сотрудников, для которых будут создаваться выплаты (обязательный параметр).
  /// [payoutDate] — дата выплаты (обязательный параметр).
  /// [method] — способ выплаты (например, 'cash', 'card', 'bank_transfer'), обязательный параметр.
  /// [type] — тип выплаты (например, 'salary', 'advance'), обязательный параметр.
  /// [comment] — комментарий к выплате (опционально, по умолчанию пустая строка).
  const PayrollPayoutAmountModal({
    super.key,
    required this.selectedEmployees,
    required this.payoutDate,
    required this.method,
    required this.type,
    required this.comment,
  });

  /// Создаёт состояние для модального окна [PayrollPayoutAmountModal].
  ///
  /// Возвращает экземпляр [_PayrollPayoutAmountModalState], реализующий логику массового ввода сумм выплат.
  @override
  ConsumerState<PayrollPayoutAmountModal> createState() =>
      _PayrollPayoutAmountModalState();
}

class _PayrollPayoutAmountModalState
    extends ConsumerState<PayrollPayoutAmountModal> {
  final Map<String, TextEditingController> _amountControllers = {};
  final _isSaving = ValueNotifier<bool>(false);
  final _totalAmount = ValueNotifier<double>(0.0);
  List<dynamic> _currentEmployees = [];

  @override
  void initState() {
    super.initState();
    _currentEmployees = List.from(widget.selectedEmployees);
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final employee in _currentEmployees) {
      _amountControllers[employee.id] = TextEditingController();
      _amountControllers[employee.id]!.addListener(_updateTotal);
    }
  }

  void _updateTotal() {
    double total = 0.0;
    for (final controller in _amountControllers.values) {
      final amount = parseAmount(controller.text) ?? 0.0;
      total += amount;
    }
    _totalAmount.value = total;
  }

  void _removeEmployee(dynamic employee) {
    setState(() {
      _currentEmployees.removeWhere((emp) => emp.id == employee.id);
      _amountControllers[employee.id]?.removeListener(_updateTotal);
      _amountControllers[employee.id]?.dispose();
      _amountControllers.remove(employee.id);
      _updateTotal();
    });
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    _isSaving.dispose();
    _totalAmount.dispose();
    super.dispose();
  }

  Future<void> _savePayouts() async {
    if (_currentEmployees.isEmpty) {
      SnackBarUtils.showWarning(context, 'Нет сотрудников для выплаты');
      return;
    }

    if (_isSaving.value) return; // Предотвращаем повторные вызовы

    _isSaving.value = true;

    try {
      final payouts = <PayrollPayoutModel>[];
      final activeCompanyId = ref.read(activeCompanyIdProvider);

      if (activeCompanyId == null) {
        throw Exception('Компания не выбрана');
      }

      // Создаем выплату для каждого сотрудника
      for (final employee in _currentEmployees) {
        final amountText = _amountControllers[employee.id]?.text ?? '';
        if (amountText.isNotEmpty) {
          final amount = parseAmount(amountText) ?? 0.0;
          if (amount > 0) {
            final payout = PayrollPayoutModel(
              id: const Uuid().v4(),
              employeeId: employee.id,
              companyId: activeCompanyId,
              amount: amount,
              payoutDate: widget.payoutDate,
              method: widget.method,
              type: widget.type,
              createdAt: DateTime.now(),
              comment: widget.comment.isEmpty ? null : widget.comment,
            );
            payouts.add(payout);
          }
        }
      }

      if (payouts.isEmpty) {
        SnackBarUtils.showWarning(context, 'Введите суммы для выплат');
        _isSaving.value = false;
        return;
      }

      // Сохраняем все выплаты последовательно
      final createUseCase = ref.read(createPayoutUseCaseProvider);
      for (final payout in payouts) {
        await createUseCase(payout);
      }

      // Обновляем провайдеры
      ref.invalidate(filteredPayrollPayoutsProvider);
      ref.invalidate(employeeAggregatedBalanceProvider);
      ref.invalidate(payrollPayoutsByFilterProvider);

      if (mounted) {
        // Закрываем оба модальных окна
        Navigator.pop(context); // Закрываем второе окно
        Navigator.pop(context); // Закрываем первое окно
        SnackBarUtils.showSuccess(context, 'Создано выплат: ${payouts.length}');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка: $e');
      }
    } finally {
      _isSaving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final numberFormat =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 2);

    // Получаем баланс сотрудников
    final balanceAsync = ref.watch(employeeAggregatedBalanceProvider);

    return balanceAsync.when(
      data: (balanceMap) =>
          _buildModalContent(context, theme, isDesktop, numberFormat, balanceMap),
      loading: () => _buildLoadingModal(context, theme, isDesktop),
      error: (e, st) => _buildErrorModal(context, theme, isDesktop, e),
    );
  }

  Widget _buildModalContent(BuildContext context, ThemeData theme,
      bool isDesktop, NumberFormat numberFormat, Map<String, double> balanceMap) {
    // Форматирование для сумм в строках сотрудников
    final amountNumberFormat =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 2);

    const title = 'Массовые выплаты';
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Информационная панель
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Этап 2 из 2: Укажите суммы для каждого сотрудника',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Дата: ${DateFormat('dd.MM.yyyy').format(widget.payoutDate)}'),
                  Text('Способ: ${_getMethodDisplayName(widget.method)}'),
                  Text('Тип: ${_getTypeDisplayName(widget.type)}'),
                  if (widget.comment.isNotEmpty)
                    Text('Комментарий: ${widget.comment}'),
                  Text('Сотрудников: ${_currentEmployees.length}'),
                ],
              ),
            ),
          ),
        ),

        // Список сотрудников с суммами
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Суммы выплат',
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Список сотрудников
            for (int i = 0; i < _currentEmployees.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildEmployeeAmountRow(
                  _currentEmployees[i], theme, balanceMap, amountNumberFormat),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Итоговая сумма
            ValueListenableBuilder<double>(
              valueListenable: _totalAmount,
              builder: (context, total, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ИТОГО:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      numberFormat.format(total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );

    final footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Назад',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _isSaving,
            builder: (context, isSaving, child) {
              return GTPrimaryButton(
                text: 'Создать выплаты',
                onPressed: isSaving ? null : _savePayouts,
                isLoading: isSaving,
              );
            },
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesktopDialogContent(
          title: title,
          footer: footer,
          child: content,
        ),
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: content,
    );
  }

  Widget _buildLoadingModal(
      BuildContext context, ThemeData theme, bool isDesktop) {
    const title = 'Загрузка';
    const content = Center(
      child: Padding(
        padding: EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 16),
            Text('Загрузка балансов...'),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesktopDialogContent(
          title: title,
          child: content,
        ),
      );
    }

    return const MobileBottomSheetContent(
      title: title,
      child: content,
    );
  }

  Widget _buildErrorModal(
      BuildContext context, ThemeData theme, bool isDesktop, Object error) {
    const title = 'Ошибка';
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Ошибка загрузки балансов', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.toString(), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );

    final footer = GTPrimaryButton(
      text: 'Закрыть',
      onPressed: () => Navigator.pop(context),
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesktopDialogContent(
          title: title,
          footer: footer,
          child: content,
        ),
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: content,
    );
  }

  Widget _buildEmployeeAmountRow(dynamic employee, ThemeData theme,
      Map<String, double> balanceMap, NumberFormat numberFormat) {
    final fio = [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName.isNotEmpty)
        employee.middleName
    ].join(' ');

    final balance = balanceMap[employee.id] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // ФИО
          Expanded(
            flex: 3,
            child: Text(
              fio,
              style:
                  theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),

          // Кликабельный баланс
          GestureDetector(
            onTap: balance > 0
                ? () {
                    _amountControllers[employee.id]?.text = balance.toString();
                    _updateTotal();
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getBalanceColor(balance, theme).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getBalanceColor(balance, theme).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getBalanceIcon(balance),
                    size: 16,
                    color: _getBalanceColor(balance, theme),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    numberFormat.format(balance),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _getBalanceColor(balance, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (balance > 0) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: _getBalanceColor(balance, theme).withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Поле ввода суммы
          Expanded(
            flex: 2,
            child: GTTextField(
              controller: _amountControllers[employee.id],
              labelText: 'Сумма',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              hintText: balance > 0 ? balance.toInt().toString() : '0',
            ),
          ),
          const SizedBox(width: 8),

          // Кнопка удалить
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            tooltip: 'Удалить сотрудника',
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            onPressed: () => _removeEmployee(employee),
          ),
        ],
      ),
    );
  }

  Color _getBalanceColor(double balance, ThemeData theme) {
    if (balance > 0) {
      return Colors.green.shade600;
    } else if (balance < 0) {
      return Colors.red.shade600;
    } else {
      return theme.colorScheme.outline;
    }
  }

  IconData _getBalanceIcon(double balance) {
    if (balance > 0) {
      return Icons.trending_up;
    } else if (balance < 0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }

  String _getMethodDisplayName(String method) =>
      PayoutUtils.getMethodDisplayName(method);

  String _getTypeDisplayName(String type) =>
      PayoutUtils.getTypeDisplayName(type);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as emp_state;

/// Компактное поле поиска для мобильного списка сотрудников.
///
/// Синхронизируется с [emp_state.EmployeeState.searchQuery] через
/// [emp_state.EmployeeNotifier.setSearchQuery]. Размещается в одной строке с кнопкой меню.
/// Стили подстраиваются под светлую и тёмную тему [Theme].
class EmployeesMobileSearchField extends ConsumerStatefulWidget {
  /// Создаёт поле поиска для мобильного экрана сотрудников.
  const EmployeesMobileSearchField({super.key});

  @override
  ConsumerState<EmployeesMobileSearchField> createState() =>
      _EmployeesMobileSearchFieldState();
}

class _EmployeesMobileSearchFieldState
    extends ConsumerState<EmployeesMobileSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(emp_state.employeeProvider).searchQuery,
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _commitQuery(String value) {
    ref.read(emp_state.employeeProvider.notifier).setSearchQuery(value);
  }

  void _clear() {
    _controller.clear();
    _commitQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    ref.listen<emp_state.EmployeeState>(
      emp_state.employeeProvider,
      (previous, next) {
        if (previous?.searchQuery == next.searchQuery) return;
        if (_controller.text == next.searchQuery) return;
        _controller.text = next.searchQuery;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      },
    );

    final hasText = _controller.text.isNotEmpty;

    return GTTextField(
      controller: _controller,
      hintText: 'Поиск',
      prefixIcon: Icons.search_rounded,
      prefixIconSize: 22,
      borderRadius: 22,
      textCapitalization: TextCapitalization.none,
      onChanged: _commitQuery,
      style: TextStyle(
        color: scheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 40,
      ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      suffixIcon: hasText
          ? IconButton(
              onPressed: _clear,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: 'Очистить',
            )
          : null,
    );
  }
}

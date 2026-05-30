import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/timesheet/presentation/widgets/timesheet_filter_widget.dart';

/// Компактное поле поиска по ФИО в шапке экрана табеля.
///
/// Синхронизируется с [timesheetSearchQueryProvider]. Размещается в одной строке
/// с кнопкой меню — как [EmployeesMobileSearchField] в модуле «Сотрудники».
class TimesheetMobileSearchField extends ConsumerStatefulWidget {
  /// Создаёт поле поиска для экрана табеля.
  const TimesheetMobileSearchField({super.key});

  @override
  ConsumerState<TimesheetMobileSearchField> createState() =>
      _TimesheetMobileSearchFieldState();
}

class _TimesheetMobileSearchFieldState
    extends ConsumerState<TimesheetMobileSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(timesheetSearchQueryProvider),
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
    ref.read(timesheetSearchQueryProvider.notifier).state = value;
  }

  void _clear() {
    _controller.clear();
    _commitQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    ref.listen<String>(timesheetSearchQueryProvider, (previous, next) {
      if (previous == next) return;
      if (_controller.text == next) return;
      _controller.text = next;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });

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

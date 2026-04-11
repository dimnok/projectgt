import 'package:flutter/material.dart';
import 'package:projectgt/features/employees/presentation/widgets/add_employee_simple_dialog.dart';

/// Круглая кнопка «+» в панели поиска мобильного списка сотрудников.
///
/// Открывает [AddEmployeeSimpleDialog] (на мобильном — bottom sheet, на десктопе — диалог).
class EmployeesMobileAddEmployeeButton extends StatelessWidget {
  /// Создаёт кнопку добавления сотрудника.
  const EmployeesMobileAddEmployeeButton({
    super.key,
    required this.chromeFill,
    required this.chromeBorder,
    required this.addIconColor,
    this.onBeforeOpen,
  });

  /// Вызывается перед открытием диалога (например, сброс свайпов на экране списка).
  final VoidCallback? onBeforeOpen;

  /// Заливка «хром»-кнопки (как у кнопки меню).
  final Color chromeFill;

  /// Обводка «хром»-кнопки.
  final Color chromeBorder;

  /// Цвет иконки «+» (обычно [ColorScheme.primary]).
  final Color addIconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (onBeforeOpen != null) {
            onBeforeOpen!();
            await WidgetsBinding.instance.endOfFrame;
            if (!context.mounted) return;
          }
          AddEmployeeSimpleDialog.show(context);
        },
        borderRadius: BorderRadius.circular(22),
        child: Tooltip(
          message: 'Добавить сотрудника',
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chromeFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: chromeBorder),
            ),
            child: Icon(Icons.add_rounded, size: 26, color: addIconColor),
          ),
        ),
      ),
    );
  }
}

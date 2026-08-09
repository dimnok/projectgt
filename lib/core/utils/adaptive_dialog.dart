import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Показывает адаптивный модальный диалог: `Dialog` на десктопе,
/// `showModalBottomSheet` на мобильном/планшете.
///
/// [builder] получает контекст и возвращает содержимое диалога. Обёртка
/// (`DesktopDialogContent` / `MobileBottomSheetContent`) лежит в самом виджете,
/// здесь только выбирается способ показа.
///
/// [T] — тип результата, который вернёт диалог через `Navigator.pop(result)`.
///
/// Название намеренно отличается от `showAdaptiveDialog` из `material.dart`,
/// чтобы избежать конфликта имён.
Future<T?> showAdaptiveModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (ResponsiveUtils.isDesktop(context)) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: builder(context),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => builder(context),
  );
}

/// Показывает стандартный `DatePicker` (ru-локаль, диапазон 2020–2100).
///
/// Возвращает выбранную дату или `null`, если пользователь отменил выбор.
/// Используется как единая точка выбора дат в формах модулей.
Future<DateTime?> pickRuDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime(2100),
  );
}

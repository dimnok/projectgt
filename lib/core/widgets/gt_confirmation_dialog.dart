import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';

/// Типы окна подтверждения.
enum GTConfirmationType {
  /// Информационное сообщение.
  info,

  /// Предупреждение.
  warning,

  /// Опасное действие (например, удаление).
  danger,
}

/// Универсальный виджет окна подтверждения для всего проекта.
///
/// Адаптируется под десктоп (диалог по центру) и мобильные устройства (bottom sheet).
/// Использует системные кастомные виджеты [DesktopDialogContent] и [MobileBottomSheetContent].
class GTConfirmationDialog extends StatelessWidget {
  /// Заголовок окна.
  final String title;

  /// Основной текст сообщения.
  final String message;

  /// Текст кнопки подтверждения.
  final String confirmText;

  /// Текст кнопки отмены.
  final String cancelText;

  /// Тип окна, влияющий на акцентный цвет.
  final GTConfirmationType type;

  /// Создаёт виджет окна подтверждения в строгом минималистичном стиле.
  const GTConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Подтвердить',
    this.cancelText = 'Отмена',
    this.type = GTConfirmationType.info,
  });

  /// Показывает окно подтверждения.
  ///
  /// Возвращает [true], если нажата кнопка подтверждения, и [false] (или null), если отмена.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
    GTConfirmationType type = GTConfirmationType.info,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GTConfirmationDialog(
            title: title,
            message: message,
            confirmText: confirmText,
            cancelText: cancelText,
            type: type,
          ),
        ),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (context) => GTConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          type: type,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final Color accentColor;
    switch (type) {
      case GTConfirmationType.danger:
        accentColor = theme.colorScheme.error;
        break;
      case GTConfirmationType.warning:
        accentColor = Colors.orange.shade700;
        break;
      case GTConfirmationType.info:
        accentColor = theme.colorScheme.primary;
        break;
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          letterSpacing: 0.2,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        width: 500,
        scrollable: false,
        showDividers: false,
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              text: cancelText,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 12),
            GTPrimaryButton(
              text: confirmText,
              backgroundColor: type == GTConfirmationType.danger
                  ? accentColor
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
        child: content,
      );
    } else {
      return MobileBottomSheetContent(
        title: title,
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        footer: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: GTPrimaryButton(
                text: confirmText,
                backgroundColor: type == GTConfirmationType.danger
                    ? accentColor
                    : null,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GTSecondaryButton(
                text: cancelText,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
        child: content,
      );
    }
  }
}

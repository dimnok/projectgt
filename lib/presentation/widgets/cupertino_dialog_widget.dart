import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Переиспользуемый виджет диалога в стиле Cupertino.
///
/// Предоставляет стандартизированный диалог в iOS-стиле с возможностью
/// настройки заголовка, сообщения, текста кнопок и действий.
class CupertinoConfirmDialog extends StatelessWidget {
  /// Заголовок диалога.
  final String title;
  
  /// Сообщение или описание.
  final String message;
  
  /// Текст кнопки отмены.
  final String cancelButtonText;
  
  /// Текст кнопки подтверждения.
  final String confirmButtonText;
  
  /// Действие при подтверждении.
  final VoidCallback onConfirm;
  
  /// Действие при отмене (опционально).
  final VoidCallback? onCancel;
  
  /// Является ли действие подтверждения деструктивным (выделяется красным цветом).
  final bool isDestructiveAction;
  
  /// Виджет содержимого (опциональный).
  /// 
  /// Если указан, заменяет стандартное текстовое сообщение.
  final Widget? contentWidget;

  /// Создаёт виджет [CupertinoConfirmDialog].
  const CupertinoConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.cancelButtonText = 'Отмена',
    this.confirmButtonText = 'OK',
    this.onCancel,
    this.isDestructiveAction = false,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: contentWidget ?? Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            context.pop();
            if (onCancel != null) onCancel!();
          },
          child: Text(cancelButtonText),
        ),
        CupertinoDialogAction(
          onPressed: onConfirm,
          isDestructiveAction: isDestructiveAction,
          child: Text(confirmButtonText),
        ),
      ],
    );
  }
}

/// Вспомогательные методы для показа диалогов Cupertino
class CupertinoDialogs {
  /// Показывает подтверждающий диалог в стиле iOS
  /// 
  /// Упрощает использование CupertinoConfirmDialog, автоматически
  /// вызывая showCupertinoDialog.
  static Future<T?> showConfirmDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String cancelButtonText = 'Отмена',
    String confirmButtonText = 'OK',
    VoidCallback? onCancel,
    bool isDestructiveAction = false,
    Widget? contentWidget,
    bool barrierDismissible = false,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: contentWidget ?? Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              if (onCancel != null) onCancel();
              Navigator.of(context).pop(false as T);
            },
            child: Text(cancelButtonText),
          ),
          CupertinoDialogAction(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true as T);
            },
            isDestructiveAction: isDestructiveAction,
            child: Text(confirmButtonText),
          ),
        ],
      ),
    );
  }
  
  /// Показывает диалог подтверждения дублирования в стиле iOS
  /// 
  /// Специализированный диалог для подтверждения операции дублирования записи.
  static Future<T?> showDuplicateConfirmDialog<T>({
    required BuildContext context,
    required VoidCallback onConfirm,
    String title = 'Подтверждение дублирования',
    String message = 'Вы действительно хотите создать дубликат этой записи?',
    String cancelButtonText = 'Отмена',
    String confirmButtonText = 'Дублировать',
    VoidCallback? onCancel,
    Widget? contentWidget,
    bool barrierDismissible = false,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: contentWidget ?? Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              if (onCancel != null) onCancel();
              Navigator.of(context).pop(false as T);
            },
            child: Text(cancelButtonText),
          ),
          CupertinoDialogAction(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true as T);
            },
            isDestructiveAction: false,
            child: Text(confirmButtonText),
          ),
        ],
      ),
    );
  }
  
  /// Показывает диалог подтверждения удаления в стиле iOS
  /// 
  /// Специализированный диалог для подтверждения операции удаления записи.
  static Future<T?> showDeleteConfirmDialog<T>({
    required BuildContext context,
    required VoidCallback onConfirm,
    String title = 'Подтверждение удаления',
    String message = 'Вы уверены, что хотите удалить эту запись? Это действие невозможно отменить.',
    String cancelButtonText = 'Отмена',
    String confirmButtonText = 'Удалить',
    VoidCallback? onCancel,
    Widget? contentWidget,
    bool barrierDismissible = false,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: contentWidget ?? Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              if (onCancel != null) onCancel();
              Navigator.of(context).pop(false as T);
            },
            child: Text(cancelButtonText),
          ),
          CupertinoDialogAction(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true as T);
            },
            isDestructiveAction: true,
            child: Text(confirmButtonText),
          ),
        ],
      ),
    );
  }
  
  /// Показывает диалог с сообщением в стиле iOS
  /// 
  /// Простой диалог с одной кнопкой "OK"
  static Future<T?> showMessageDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    Widget? contentWidget,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: contentWidget ?? Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              if (onPressed != null) onPressed();
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
} 
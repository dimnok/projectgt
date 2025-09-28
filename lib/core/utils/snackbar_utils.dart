import 'package:flutter/material.dart';

/// Утилиты для отображения единообразных SnackBar уведомлений в приложении.
///
/// Предоставляет методы для показа уведомлений с современным стилем:
/// floating behavior, скругленные углы, адаптивная ширина.
///
/// Пример использования:
/// ```dart
/// SnackBarUtils.showSuccess(context, 'Данные сохранены');
/// SnackBarUtils.showError(context, 'Ошибка сохранения');
/// SnackBarUtils.showWarning(context, 'Проверьте введенные данные');
/// SnackBarUtils.showInfo(context, 'Информация обновлена');
/// ```
class SnackBarUtils {
  /// Показывает успешное уведомление (зеленое).
  ///
  /// [context] — BuildContext для отображения SnackBar.
  /// [message] — текст уведомления.
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.green[600],
      icon: Icons.check_circle_outline,
    );
  }

  /// Показывает уведомление об ошибке (красное).
  ///
  /// [context] — BuildContext для отображения SnackBar.
  /// [message] — текст уведомления.
  /// Отображается дольше других типов уведомлений (3 секунды).
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.red[600],
      icon: Icons.error_outline,
      duration: const Duration(milliseconds: 3000), // Дольше для ошибок
    );
  }

  /// Показывает информационное уведомление (синее).
  ///
  /// [context] — BuildContext для отображения SnackBar.
  /// [message] — текст уведомления.
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.blue[600],
      icon: Icons.info_outline,
    );
  }

  /// Показывает предупреждение (оранжевое).
  ///
  /// [context] — BuildContext для отображения SnackBar.
  /// [message] — текст уведомления.
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.orange[600],
      icon: Icons.warning_outlined,
    );
  }

  /// Показывает предупреждение поверх всех модальных окон.
  ///
  /// Использует корневой Overlay для отображения поверх модальных окон.
  /// [context] — BuildContext для получения доступа к корневому Overlay.
  /// [message] — текст уведомления.
  static void showWarningOverlay(BuildContext context, String message) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = _createOverlayEntry(
      message: message,
      backgroundColor: Colors.orange[600],
      icon: Icons.warning_outlined,
      context: context,
    );

    overlay.insert(overlayEntry);

    // Автоматически удаляем через 2 секунды
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry.remove();
    });
  }

  // ===== Варианты с заранее кэшированным ScaffoldMessenger =====
  /// Унифицированный показ через уже кэшированный [ScaffoldMessengerState].
  static void showByMessenger({
    required ScaffoldMessengerState messenger,
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  /// Показывает успешное уведомление через заранее кэшированный [ScaffoldMessengerState].
  ///
  /// [messenger] — ссылка на кэшированный messenger (полученный до await).
  /// [message] — текст уведомления, отображаемый пользователю.
  static void showSuccessByMessenger(
      ScaffoldMessengerState messenger, String message) {
    showByMessenger(
      messenger: messenger,
      message: message,
      backgroundColor: Colors.green[600],
      icon: Icons.check_circle_outline,
    );
  }

  /// Показывает уведомление об ошибке через заранее кэшированный [ScaffoldMessengerState].
  ///
  /// [messenger] — ссылка на кэшированный messenger (полученный до await).
  /// [message] — текст ошибки. Отображается дольше стандартного уведомления.
  static void showErrorByMessenger(
      ScaffoldMessengerState messenger, String message) {
    showByMessenger(
      messenger: messenger,
      message: message,
      backgroundColor: Colors.red[600],
      icon: Icons.error_outline,
      duration: const Duration(milliseconds: 3000),
    );
  }

  /// Показывает информационное уведомление через заранее кэшированный [ScaffoldMessengerState].
  ///
  /// [messenger] — ссылка на кэшированный messenger (полученный до await).
  /// [message] — текст информационного сообщения.
  static void showInfoByMessenger(
      ScaffoldMessengerState messenger, String message) {
    showByMessenger(
      messenger: messenger,
      message: message,
      backgroundColor: Colors.blue[600],
      icon: Icons.info_outline,
    );
  }

  /// Показывает предупреждение через заранее кэшированный [ScaffoldMessengerState].
  ///
  /// [messenger] — ссылка на кэшированный messenger (полученный до await).
  /// [message] — текст предупреждения.
  static void showWarningByMessenger(
      ScaffoldMessengerState messenger, String message) {
    showByMessenger(
      messenger: messenger,
      message: message,
      backgroundColor: Colors.orange[600],
      icon: Icons.warning_outlined,
    );
  }

  /// Показывает ошибку поверх всех модальных окон.
  ///
  /// Использует корневой Overlay для отображения поверх модальных окон.
  /// [context] — BuildContext для получения доступа к корневому Overlay.
  /// [message] — текст уведомления.
  static void showErrorOverlay(BuildContext context, String message) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = _createOverlayEntry(
      message: message,
      backgroundColor: Colors.red[600],
      icon: Icons.error_outline,
      context: context,
      duration: const Duration(milliseconds: 3000),
    );

    overlay.insert(overlayEntry);

    // Автоматически удаляем через 3 секунды для ошибок
    Future.delayed(const Duration(milliseconds: 3000), () {
      overlayEntry.remove();
    });
  }

  /// Показывает успешное уведомление поверх всех модальных окон.
  ///
  /// Использует корневой Overlay для отображения поверх модальных окон.
  /// [context] — BuildContext для получения доступа к корневому Overlay.
  /// [message] — текст уведомления.
  static void showSuccessOverlay(BuildContext context, String message) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = _createOverlayEntry(
      message: message,
      backgroundColor: Colors.green[600],
      icon: Icons.check_circle_outline,
      context: context,
    );

    overlay.insert(overlayEntry);

    // Автоматически удаляем через 2 секунды
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry.remove();
    });
  }

  /// Преобразует техническое сообщение об ошибке аутентификации в человеко-читаемое.
  ///
  /// [error] — строка с ошибкой от backend/Supabase.
  /// Возвращает локализованное сообщение для пользователя.
  static String getAuthErrorMessage(String error) {
    if (error.contains('invalid_credentials') ||
        error.contains('Invalid login credentials')) {
      return 'Неверный email или пароль';
    } else if (error.contains('email address is already registered')) {
      return 'Этот email уже зарегистрирован';
    } else if (error.contains('password should be at least')) {
      return 'Пароль должен содержать не менее 6 символов';
    } else if (error.contains('network')) {
      return 'Ошибка сети. Проверьте подключение к интернету';
    }
    return error;
  }

  /// Базовый метод для показа SnackBar с современным стилем.
  ///
  /// Автоматически адаптируется под размер экрана:
  /// - Большие экраны (>600px): фиксированная ширина 400px
  /// - Мобильные экраны: полная ширина с отступами
  static void _showSnackBar({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2000),
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Для больших экранов используем width, для мобильных - margin
    final isLargeScreen = screenWidth > 600;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        duration: duration,
        width: isLargeScreen ? 400.0 : null,
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: isLargeScreen
            ? null
            : const EdgeInsets.only(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
              ),
        action: action,
      ),
    );
  }

  /// Создает OverlayEntry для отображения поверх всех виджетов.
  ///
  /// Создает кастомный SnackBar как OverlayEntry, который точно отображается
  /// поверх всех модальных окон.
  static OverlayEntry _createOverlayEntry({
    required String message,
    required BuildContext context,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return OverlayEntry(
      builder: (context) => Positioned(
        bottom: 16.0,
        left: isLargeScreen ? (screenWidth - 400) / 2 : 16.0,
        right: isLargeScreen ? (screenWidth - 400) / 2 : 16.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: isLargeScreen ? 400.0 : null,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

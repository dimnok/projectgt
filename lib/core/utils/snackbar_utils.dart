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
} 
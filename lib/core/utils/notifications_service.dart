import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';
import 'package:synchronized/synchronized.dart';
import 'package:logger/logger.dart';

/// Сервис для отображения уведомлений в приложении.
///
/// Позволяет показывать success, error и info уведомления с анимацией, очередью и авто-скрытием.
/// Использует Overlay, поддерживает одновременное отображение только одного уведомления.
/// Все методы статические, сервис не требует инициализации.
///
/// Пример использования:
/// ```dart
/// NotificationsService.showSuccessNotification(context, 'Данные сохранены');
/// NotificationsService.showErrorNotification(context, 'Ошибка сохранения');
/// NotificationsService.showInfoNotification(context, 'Информация');
/// ```
class NotificationsService {
  static OverlayEntry? _overlayEntry;
  static final Lock _lock = Lock();
  static final Queue<_NotificationData> _queue = Queue();
  static const int _maxQueueSize = 10;
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _displayDuration = Duration(seconds: 3);
  
  static bool _isVisible = false;
  static bool _isDismissing = false;
  static bool _isShowingNotification = false;
  static Timer? _hideTimer;
  static WeakReference<BuildContext>? _weakContext;
  
  static Future<void> _processNextNotification() async {
    await _lock.synchronized(() async {
      if (_queue.isEmpty || _isShowingNotification) return;
      
      _isShowingNotification = true;
      final notification = _queue.removeFirst();
      
      // Проверяем валидность контекста
      if (!notification.context.mounted) {
        _resetState();
        _processNextNotification();
        return;
      }
      
      await _safelyShowOverlay(notification.context, notification.child);
    });
  }
  
  static void _resetState() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
    _isDismissing = false;
    _isShowingNotification = false;
    _weakContext = null;
  }
  
  static Future<void> _removeOverlay({bool immediate = false}) async {
    await _lock.synchronized(() async {
      if (_overlayEntry == null || _isDismissing) return;
      
      _isDismissing = true;
      _hideTimer?.cancel();
      _hideTimer = null;
      
      if (immediate) {
        _finalizeRemoval();
      } else {
        _isVisible = false;
        _overlayEntry?.markNeedsBuild();
        
        Timer(const Duration(milliseconds: 150), () {
          _finalizeRemoval();
        });
      }
    });
  }
  
  static void _finalizeRemoval() {
    _resetState();
    
    // Обрабатываем следующее уведомление в очереди
    Timer(const Duration(milliseconds: 200), () {
      _processNextNotification();
    });
  }

  static Future<void> _safelyShowOverlay(BuildContext context, Widget child) async {
    try {
      if (!context.mounted) return;
      
      final overlay = Overlay.of(context);
      
      _weakContext = WeakReference(context);
      
      if (_overlayEntry != null) {
        await _removeOverlay(immediate: true);
      }
      
      if (!context.mounted) {
        _resetState();
        _processNextNotification();
        return;
      }
      
      _overlayEntry = OverlayEntry(
        builder: (context) => _NotificationOverlay(
          child: child,
        ),
      );
      
      _isVisible = true;
      _isDismissing = false;
      
      overlay.insert(_overlayEntry!);
      
      _setupHideTimer();
      
    } catch (e) {
      Logger().e('Error showing notification: $e');
      _resetState();
    }
  }
  
  static void _setupHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_displayDuration, () {
      final context = _weakContext?.target;
      if (context?.mounted == true) {
        _removeOverlay();
      } else {
        _removeOverlay(immediate: true);
      }
    });
  }
  
  static Future<void> _addToQueue(BuildContext context, Widget notification) async {
    await _lock.synchronized(() {
      if (_queue.length >= _maxQueueSize) {
        _queue.removeFirst();
      }
      _queue.add(_NotificationData(context: context, child: notification));
      _processNextNotification();
    });
  }

  /// Показывает уведомление об ошибке (красное).
  ///
  /// [context] — BuildContext для Overlay.
  /// [message] — текст уведомления.
  /// Уведомление автоматически исчезает через несколько секунд или по нажатию.
  static void showErrorNotification(BuildContext context, String message) {
    _addToQueue(
      context,
      _NotificationWidget(
        message: message,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  /// Показывает уведомление об успехе (зелёное).
  ///
  /// [context] — BuildContext для Overlay.
  /// [message] — текст уведомления.
  /// Уведомление автоматически исчезает через несколько секунд или по нажатию.
  static void showSuccessNotification(BuildContext context, String message) {
    _addToQueue(
      context,
      _NotificationWidget(
        message: message,
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green.shade800,
      ),
    );
  }

  /// Показывает информационное уведомление (синее).
  ///
  /// [context] — BuildContext для Overlay.
  /// [message] — текст уведомления.
  /// Уведомление автоматически исчезает через несколько секунд или по нажатию.
  static void showInfoNotification(BuildContext context, String message) {
    _addToQueue(
      context,
      _NotificationWidget(
        message: message,
        icon: Icons.info_outline,
        backgroundColor: Colors.amber.shade800,
      ),
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
  
  /// Очищает очередь уведомлений и мгновенно скрывает текущее уведомление.
  ///
  /// Используйте для сброса состояния уведомлений, например, при выходе из аккаунта или смене экрана.
  static Future<void> clearAll() async {
    await _lock.synchronized(() {
      _queue.clear();
      _removeOverlay(immediate: true);
    });
  }
}

class _NotificationData {
  final BuildContext context;
  final Widget child;
  
  _NotificationData({
    required this.context,
    required this.child,
  });
}

class _NotificationOverlay extends StatelessWidget {
  final Widget child;

  const _NotificationOverlay({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!,
          child: AnimatedOpacity(
            opacity: NotificationsService._isVisible ? 1.0 : 0.0,
            duration: NotificationsService._animationDuration,
            curve: Curves.easeInOut,
            child: AnimatedSlide(
              offset: NotificationsService._isVisible 
                  ? const Offset(0, 0) 
                  : const Offset(0, 1),
              duration: NotificationsService._animationDuration,
              curve: Curves.easeInOut,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: isMobile
                      ? const EdgeInsets.symmetric(horizontal: 6)
                      : const EdgeInsets.all(16.0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;

  const _NotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    return Container(
      constraints: isMobile
          ? BoxConstraints(
              minWidth: width,
              maxWidth: width,
            )
          : BoxConstraints(
              minWidth: width * 0.45,
              maxWidth: width * 0.45,
            ),
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: isMobile ? BorderRadius.circular(10) : BorderRadius.circular(12),
        boxShadow: [
          if (!isMobile)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => NotificationsService._removeOverlay(),
          borderRadius: isMobile ? BorderRadius.circular(10) : BorderRadius.circular(12),
          child: Padding(
            padding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0)
                : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => NotificationsService._removeOverlay(),
                  splashRadius: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Сервис для управления локальными уведомлениями приложения.
///
/// Предоставляет функциональность для планирования и отмены напоминаний о сменах,
/// инициализации системы уведомлений и управления разрешениями.
class NotificationService {
  /// Создает экземпляр сервиса уведомлений.
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Инициализирует систему локальных уведомлений.
  ///
  /// Настраивает временные зоны, инициализирует плагин уведомлений
  /// и запрашивает необходимые разрешения.
  ///
  /// [onSelect] - callback, вызываемый при нажатии на уведомление.
  /// Передает payload уведомления.
  Future<void> initialize({
    void Function(String? payload)? onSelect,
  }) async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // fallback: оставляем tz.local как есть
    }

    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: initAndroid,
      iOS: initDarwin,
      macOS: initDarwin,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        onSelect?.call(r.payload);
      },
    );

    await _requestPermissionsIfNeeded();

    _initialized = true;
  }

  Future<void> _requestPermissionsIfNeeded() async {
    // Пропускаем запрос разрешений на веб-платформе
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      await macos?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Планирует напоминания о незакрытой смене.
  ///
  /// Создает серию уведомлений в указанное время для напоминания
  /// пользователю о необходимости закрыть смену.
  ///
  /// [shiftId] - идентификатор смены для которой планируются напоминания.
  /// [date] - дата смены.
  /// [slotTimesHHmm] - список времен напоминаний в формате "HH:mm".
  /// Если не указан, используются значения по умолчанию: ['13:00', '15:00', '18:00'].
  Future<void> scheduleShiftReminders({
    required String shiftId,
    required DateTime date,
    List<String>? slotTimesHHmm,
  }) async {
    // Гарантируем инициализацию перед использованием
    if (!_initialized) {
      await initialize();
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      final day = tz.TZDateTime(tz.local, date.year, date.month, date.day);

      final List<String> slots =
          (slotTimesHHmm == null || slotTimesHHmm.isEmpty)
              ? const ['13:00', '15:00', '18:00']
              : slotTimesHHmm;

      final List<tz.TZDateTime> targets = slots
          .map((s) {
            final parts = s.split(':');
            final int hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
            final int minute =
                parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
            return tz.TZDateTime(
                tz.local, day.year, day.month, day.day, hour, minute);
          })
          .where((t) => t.isAfter(now))
          .toList();

      const androidDetails = AndroidNotificationDetails(
        'shift_reminders',
        'Напоминания о сменах',
        channelDescription: 'Локальные напоминания о незакрытых сменах',
        importance: Importance.max,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final baseId = shiftId.hashCode & 0x7fffffff;

      for (int i = 0; i < targets.length; i++) {
        await _plugin.zonedSchedule(
          baseId + i,
          'Смена не закрыта',
          'Не забудьте добавить работы и закрыть смену',
          targets[i],
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: shiftId,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling shift reminders: $e');
    }
  }

  // showForeground удалён вместе с FCM

  /// Отменяет все запланированные напоминания для смены.
  ///
  /// Удаляет все уведомления, связанные с указанной сменой.
  ///
  /// [shiftId] - идентификатор смены, для которой отменяются напоминания.
  Future<void> cancelShiftReminders(String shiftId) async {
    // Гарантируем инициализацию перед использованием
    if (!_initialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('Failed to initialize notifications during cancel: $e');
        return;
      }
    }

    try {
      final baseId = shiftId.hashCode & 0x7fffffff;
      for (int i = 0; i < 3; i++) {
        await _plugin.cancel(baseId + i);
      }
    } catch (e) {
      debugPrint('Error canceling shift reminders: $e');
    }
  }
}

/// Провайдер сервиса уведомлений для Riverpod.
///
/// Предоставляет глобальный доступ к экземпляру [NotificationService]
/// для использования в виджетах и других провайдерах.
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

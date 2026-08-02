import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_notification.freezed.dart';

/// Тип in-app уведомления ТМЦ.
enum TmcNotificationType {
  /// Истекает гарантия.
  @JsonValue('warranty_expiring')
  warrantyExpiring,

  /// Требуется обслуживание.
  @JsonValue('service_due')
  serviceDue,

  /// Подходит срок возврата.
  @JsonValue('return_due')
  returnDue,

  /// Не возвращено в срок.
  @JsonValue('not_returned')
  notReturned,

  /// Требуется ремонт.
  @JsonValue('needs_repair')
  needsRepair,

  /// Замена СИЗ/спецодежды.
  @JsonValue('ppe_replacement')
  ppeReplacement,

  /// Недостача.
  @JsonValue('shortage')
  shortage,

  /// Нет движения.
  @JsonValue('no_movement')
  noMovement,

  /// Прочее.
  @JsonValue('other')
  other,
}

/// Расширения для [TmcNotificationType].
extension TmcNotificationTypeX on TmcNotificationType {
  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcNotificationType.warrantyExpiring => 'Истекает гарантия',
        TmcNotificationType.serviceDue => 'Требуется обслуживание',
        TmcNotificationType.returnDue => 'Подходит срок возврата',
        TmcNotificationType.notReturned => 'Не возвращено в срок',
        TmcNotificationType.needsRepair => 'Требуется ремонт',
        TmcNotificationType.ppeReplacement => 'Замена СИЗ',
        TmcNotificationType.shortage => 'Недостача',
        TmcNotificationType.noMovement => 'Нет движения',
        TmcNotificationType.other => 'Прочее',
      };
}

/// In-app уведомление модуля ТМЦ.
@freezed
abstract class TmcNotification with _$TmcNotification {
  /// Создаёт [TmcNotification].
  const factory TmcNotification({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Получатель (пользователь).
    String? userId,

    /// Тип уведомления.
    required TmcNotificationType notificationType,

    /// Заголовок.
    required String title,

    /// Текст.
    String? body,

    /// Связанная позиция.
    String? itemId,

    /// Связанная единица.
    String? unitId,

    /// Дополнительные данные.
    @Default({}) Map<String, dynamic> payload,

    /// Прочитано.
    @Default(false) bool isRead,

    /// Дата создания.
    DateTime? createdAt,
  }) = _TmcNotification;
}

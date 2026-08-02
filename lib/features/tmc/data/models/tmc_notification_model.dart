import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_notification.dart';

part 'tmc_notification_model.freezed.dart';
part 'tmc_notification_model.g.dart';

/// Модель in-app уведомления ТМЦ для Supabase.
@freezed
abstract class TmcNotificationModel with _$TmcNotificationModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcNotificationModel({
    required String id,
    required String companyId,
    String? userId,
    required TmcNotificationType notificationType,
    required String title,
    String? body,
    String? itemId,
    String? unitId,
    @Default({}) Map<String, dynamic> payload,
    @Default(false) bool isRead,
    DateTime? createdAt,
  }) = _TmcNotificationModel;

  const TmcNotificationModel._();

  /// JSON для записи в БД.
  @override
  Map<String, dynamic> toJson() =>
      _$TmcNotificationModelToJson(this as _TmcNotificationModel);

  /// Из JSON.
  factory TmcNotificationModel.fromJson(Map<String, dynamic> json) =>
      _$TmcNotificationModelFromJson(json);

  /// Из доменной сущности.
  factory TmcNotificationModel.fromDomain(TmcNotification notification) =>
      TmcNotificationModel(
        id: notification.id,
        companyId: notification.companyId,
        userId: notification.userId,
        notificationType: notification.notificationType,
        title: notification.title,
        body: notification.body,
        itemId: notification.itemId,
        unitId: notification.unitId,
        payload: notification.payload,
        isRead: notification.isRead,
        createdAt: notification.createdAt,
      );

  /// В доменную сущность.
  TmcNotification toDomain() => TmcNotification(
        id: id,
        companyId: companyId,
        userId: userId,
        notificationType: notificationType,
        title: title,
        body: body,
        itemId: itemId,
        unitId: unitId,
        payload: payload,
        isRead: isRead,
        createdAt: createdAt,
      );
}

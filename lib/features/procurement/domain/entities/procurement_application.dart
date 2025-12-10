import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/data/models/object_model.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/features/procurement/data/models/bot_user_model.dart';
import 'package:projectgt/features/procurement/domain/entities/procurement_request.dart';

part 'procurement_application.freezed.dart';
part 'procurement_application.g.dart';

@freezed

/// Модель заявки на закупку.
abstract class ProcurementApplication with _$ProcurementApplication {
  /// Создаёт экземпляр заявки на закупку.
  const factory ProcurementApplication({
    /// Уникальный идентификатор заявки.
    required String id,

    /// Читаемый ID заявки.
    @JsonKey(name: 'readable_id') String? readableId,

    /// Дата создания.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Статус заявки.
    @Default('pending_approval') String status,

    // Relations
    /// Объект, к которому относится заявка.
    @JsonKey(
      name: 'object',
      fromJson: _objectFromJson,
      toJson: _objectToJson,
    )
    ObjectEntity? object,

    /// Пользователь, создавший заявку.
    @JsonKey(name: 'requester') BotUserModel? requester,

    /// Список позиций в заявке.
    @JsonKey(name: 'items') @Default([]) List<ProcurementRequest> items,

    /// История изменений заявки.
    @JsonKey(name: 'history') @Default([]) List<ProcurementHistory> history,
  }) = _ProcurementApplication;

  /// Создаёт заявку из JSON.
  factory ProcurementApplication.fromJson(Map<String, dynamic> json) =>
      _$ProcurementApplicationFromJson(json);
}

ObjectEntity? _objectFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return ObjectModel.fromJson(json).toDomain();
}

Map<String, dynamic>? _objectToJson(ObjectEntity? object) {
  if (object == null) return null;
  return ObjectModel.fromDomain(object).toJson();
}

@freezed

/// Модель истории изменений заявки на закупку.
abstract class ProcurementHistory with _$ProcurementHistory {
  /// Создаёт экземпляр записи истории.
  const factory ProcurementHistory({
    /// Уникальный идентификатор записи истории.
    required String id,

    /// Новый статус заявки.
    @JsonKey(name: 'new_status') required String newStatus,

    /// Дата изменения.
    @JsonKey(name: 'changed_at') required DateTime changedAt,

    /// Комментарий к изменению.
    String? comment,

    /// Пользователь, внесший изменение.
    @JsonKey(name: 'actor') BotUserModel? actor,
  }) = _ProcurementHistory;

  /// Создаёт запись истории из JSON.
  factory ProcurementHistory.fromJson(Map<String, dynamic> json) =>
      _$ProcurementHistoryFromJson(json);
}

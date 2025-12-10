import 'package:freezed_annotation/freezed_annotation.dart';

part 'procurement_request.freezed.dart';
part 'procurement_request.g.dart';

@freezed

/// Модель позиции (товара/услуги) в заявке на закупку.
abstract class ProcurementRequest with _$ProcurementRequest {
  /// Создаёт экземпляр позиции заявки на закупку.
  const factory ProcurementRequest({
    /// Уникальный идентификатор позиции.
    required String id,

    /// Наименование товара или услуги.
    @JsonKey(name: 'item_name') required String itemName,

    /// Количество (с единицами измерения в строке).
    required String quantity,

    /// Статус позиции.
    @Default('pending_approval') String status,

    /// Дата создания позиции.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Описание или примечание.
    @JsonKey(name: 'description') String? description,

    /// Telegram ID заявителя (для обратной совместимости или быстрого доступа).
    @JsonKey(name: 'requester_telegram_id') int? requesterTelegramId,
  }) = _ProcurementRequest;

  /// Создаёт позицию из JSON.
  factory ProcurementRequest.fromJson(Map<String, dynamic> json) =>
      _$ProcurementRequestFromJson(json);
}

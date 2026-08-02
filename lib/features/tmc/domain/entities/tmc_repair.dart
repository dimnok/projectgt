import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_repair.freezed.dart';

/// Статус ремонта ТМЦ.
enum TmcRepairStatus {
  /// Открыт.
  @JsonValue('open')
  open,

  /// Завершён.
  @JsonValue('completed')
  completed,

  /// Отменён.
  @JsonValue('cancelled')
  cancelled,
}

/// Расширения для [TmcRepairStatus].
extension TmcRepairStatusX on TmcRepairStatus {
  /// Отображаемое название на русском.
  String get displayName => switch (this) {
        TmcRepairStatus.open => 'В ремонте',
        TmcRepairStatus.completed => 'Завершён',
        TmcRepairStatus.cancelled => 'Отменён',
      };
}

/// Запись о ремонте ТМЦ.
@freezed
abstract class TmcRepair with _$TmcRepair {
  /// Создаёт [TmcRepair].
  const factory TmcRepair({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Позиция каталога.
    required String itemId,

    /// Единица.
    String? unitId,

    /// Дата отправки в ремонт.
    required DateTime sentAt,

    /// Причина.
    String? reason,

    /// Описание неисправности.
    String? faultDescription,

    /// Название ремонтной организации.
    String? repairOrgName,

    /// Ответственный сотрудник.
    String? responsibleEmployeeId,

    /// Ориентировочная стоимость.
    double? estimatedCost,

    /// Фактическая стоимость.
    double? actualCost,

    /// Дата завершения.
    DateTime? completedAt,

    /// Результат ремонта.
    String? result,

    /// Состояние после ремонта.
    String? conditionAfterId,

    /// Гарантия на ремонт до.
    DateTime? repairWarrantyUntil,

    /// Статус ремонта.
    @Default(TmcRepairStatus.open) TmcRepairStatus status,

    /// Операция отправки.
    String? sendOperationId,

    /// Операция возврата.
    String? returnOperationId,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Автор создания.
    String? createdBy,

    /// Наименование позиции (join).
    String? itemName,

    /// Инвентарный номер (join).
    String? inventoryNumber,
  }) = _TmcRepair;
}

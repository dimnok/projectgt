import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';

part 'tmc_operation.freezed.dart';

/// Строка операции ТМЦ.
@freezed
abstract class TmcOperationItem with _$TmcOperationItem {
  /// Создаёт [TmcOperationItem].
  const factory TmcOperationItem({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Операция.
    required String operationId,

    /// Позиция каталога.
    required String itemId,

    /// Единица (индивидуальный учёт).
    String? unitId,

    /// Количество.
    @Default(1) double quantity,

    /// Цена за единицу.
    double? unitPrice,

    /// Состояние.
    String? conditionId,

    /// Примечание о комплектности.
    String? completenessNote,

    /// Комментарий.
    String? comment,

    /// Размер одежды (спецодежда).
    String? clothingSize,

    /// Рост, см (спецодежда).
    double? heightCm,

    /// Сезон (спецодежда).
    String? season,

    /// Срок службы, дней.
    int? serviceLifeDays,

    /// Дата следующей замены.
    DateTime? nextReplacementDate,

    /// Дата создания.
    DateTime? createdAt,

    /// Наименование позиции (join).
    String? itemName,

    /// Инвентарный номер (join).
    String? inventoryNumber,
  }) = _TmcOperationItem;
}

/// Складская операция ТМЦ.
@freezed
abstract class TmcOperation with _$TmcOperation {
  /// Создаёт [TmcOperation].
  const factory TmcOperation({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Тип операции.
    required TmcOperationType operationType,

    /// Дата и время операции.
    required DateTime operatedAt,

    /// Номер документа.
    String? documentNumber,

    /// Основание.
    String? basis,

    /// Комментарий.
    String? comment,

    /// Тип места «откуда».
    TmcLocationType? fromLocationType,

    /// Склад «откуда».
    String? fromWarehouseId,

    /// Объект «откуда».
    String? fromObjectId,

    /// Сотрудник «откуда».
    String? fromEmployeeId,

    /// Примечание к месту «откуда».
    String? fromLocationNote,

    /// Тип места «куда».
    TmcLocationType? toLocationType,

    /// Склад «куда».
    String? toWarehouseId,

    /// Объект «куда».
    String? toObjectId,

    /// Сотрудник «куда».
    String? toEmployeeId,

    /// Примечание к месту «куда».
    String? toLocationNote,

    /// Ответственный сотрудник.
    String? responsibleEmployeeId,

    /// Связанный объект.
    String? objectId,

    /// Сторнируемая операция.
    String? reversesOperationId,

    /// Плановая дата возврата.
    DateTime? plannedReturnDate,

    /// Состояние после операции.
    String? conditionId,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Автор создания.
    String? createdBy,

    /// Строки операции.
    @Default([]) List<TmcOperationItem> items,
  }) = _TmcOperation;
}

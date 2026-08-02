import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';

part 'tmc_unit.freezed.dart';

/// Единица ТМЦ (индивидуальный учёт).
@freezed
abstract class TmcUnit with _$TmcUnit {
  /// Создаёт [TmcUnit].
  const factory TmcUnit({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Позиция каталога.
    required String itemId,

    /// Инвентарный номер.
    required String inventoryNumber,

    /// Серийный номер.
    String? serialNumber,

    /// Штрихкод.
    String? barcode,

    /// Дата покупки.
    DateTime? purchaseDate,

    /// Цена покупки.
    @Default(0) double purchasePrice,

    /// Состояние.
    String? conditionId,

    /// Статус единицы.
    @Default(TmcUnitStatus.inStock) TmcUnitStatus status,

    /// Тип местоположения.
    @Default(TmcLocationType.warehouse) TmcLocationType locationType,

    /// Склад.
    String? warehouseId,

    /// Объект.
    String? objectId,

    /// Сотрудник (держатель).
    String? employeeId,

    /// Примечание к местоположению.
    String? locationNote,

    /// Объект использования.
    String? usageObjectId,

    /// Ответственный сотрудник.
    String? responsibleEmployeeId,

    /// Дата последней выдачи.
    DateTime? lastIssueDate,

    /// Дата следующей проверки.
    DateTime? nextInspectionDate,

    /// Гарантия до.
    DateTime? warrantyUntil,

    /// Комментарий.
    String? comment,

    /// URL фото.
    String? photoUrl,

    /// В архиве.
    @Default(false) bool isArchived,

    /// Дата архивации.
    DateTime? archivedAt,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Автор создания.
    String? createdBy,

    /// Наименование позиции (join).
    String? itemName,

    /// Название состояния (join).
    String? conditionName,

    /// Название склада (join).
    String? warehouseName,

    /// Название объекта (join).
    String? objectName,

    /// ФИО сотрудника (join).
    String? employeeName,
  }) = _TmcUnit;
}

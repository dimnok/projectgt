import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_assignment.freezed.dart';

/// Активная или завершённая выдача ТМЦ сотруднику.
@freezed
abstract class TmcAssignment with _$TmcAssignment {
  /// Создаёт [TmcAssignment].
  const factory TmcAssignment({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Позиция каталога.
    required String itemId,

    /// Единица (индивидуальный учёт).
    String? unitId,

    /// Сотрудник.
    required String employeeId,

    /// Объект.
    String? objectId,

    /// Количество.
    @Default(1) double quantity,

    /// Дата выдачи.
    required DateTime issuedAt,

    /// Плановая дата возврата.
    DateTime? plannedReturnDate,

    /// Состояние при выдаче.
    String? conditionId,

    /// Операция выдачи.
    String? issueOperationId,

    /// Размер одежды.
    String? clothingSize,

    /// Рост, см.
    double? heightCm,

    /// Сезон.
    String? season,

    /// Срок службы, дней.
    int? serviceLifeDays,

    /// Дата следующей замены.
    DateTime? nextReplacementDate,

    /// Комментарий.
    String? comment,

    /// Дата возврата.
    DateTime? returnedAt,

    /// Активна ли выдача.
    @Default(true) bool isActive,

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

    /// ФИО сотрудника (join).
    String? employeeName,

    /// Название объекта (join).
    String? objectName,
  }) = _TmcAssignment;
}

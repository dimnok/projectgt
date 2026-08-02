import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';

part 'tmc_write_off.freezed.dart';

/// Запись о списании ТМЦ.
@freezed
abstract class TmcWriteOff with _$TmcWriteOff {
  /// Создаёт [TmcWriteOff].
  const factory TmcWriteOff({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Позиция каталога.
    required String itemId,

    /// Единица.
    String? unitId,

    /// Дата списания.
    required DateTime writtenOffAt,

    /// Причина списания.
    required TmcWriteOffReason reason,

    /// Количество.
    @Default(1) double quantity,

    /// Состояние.
    String? conditionId,

    /// Балансовая стоимость.
    double? bookValue,

    /// Ответственный сотрудник.
    String? responsibleEmployeeId,

    /// Объект.
    String? objectId,

    /// Номер акта.
    String? actNumber,

    /// Комментарий.
    String? comment,

    /// Связанная операция.
    String? operationId,

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
  }) = _TmcWriteOff;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_warehouse.freezed.dart';

/// Склад ТМЦ.
@freezed
abstract class TmcWarehouse with _$TmcWarehouse {
  /// Создаёт [TmcWarehouse].
  const factory TmcWarehouse({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Наименование склада.
    required String name,

    /// Адрес.
    String? address,

    /// Описание.
    String? description,

    /// В архиве.
    @Default(false) bool isArchived,

    /// Дата архивации.
    DateTime? archivedAt,

    /// Основной склад компании.
    @Default(false) bool isMain,

    /// Системный склад (нельзя удалить/переименовать).
    @Default(false) bool isSystem,

    /// Дата создания.
    DateTime? createdAt,

    /// Дата обновления.
    DateTime? updatedAt,

    /// Автор создания.
    String? createdBy,
  }) = _TmcWarehouse;
}

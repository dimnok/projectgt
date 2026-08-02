import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_condition.freezed.dart';

/// Справочник состояний ТМЦ.
@freezed
abstract class TmcCondition with _$TmcCondition {
  /// Создаёт [TmcCondition].
  const factory TmcCondition({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Код состояния.
    required String code,

    /// Наименование.
    required String name,

    /// Порядок сортировки.
    @Default(0) int sortOrder,

    /// Системное (предустановленное) состояние.
    @Default(false) bool isSystem,

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
  }) = _TmcCondition;
}

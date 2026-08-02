import 'package:freezed_annotation/freezed_annotation.dart';

part 'tmc_category.freezed.dart';

/// Категория каталога ТМЦ.
@freezed
abstract class TmcCategory with _$TmcCategory {
  /// Создаёт [TmcCategory].
  const factory TmcCategory({
    /// Идентификатор записи.
    required String id,

    /// Компания-владелец.
    required String companyId,

    /// Родительская категория.
    String? parentId,

    /// Наименование.
    required String name,

    /// Код категории.
    String? code,

    /// Порядок сортировки.
    @Default(0) int sortOrder,

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
  }) = _TmcCategory;
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_category.dart';

part 'tmc_category_model.freezed.dart';
part 'tmc_category_model.g.dart';

/// Модель категории ТМЦ для Supabase.
@freezed
abstract class TmcCategoryModel with _$TmcCategoryModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcCategoryModel({
    required String id,
    required String companyId,
    String? parentId,
    required String name,
    String? code,
    @Default(0) int sortOrder,
    @Default(false) bool isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _TmcCategoryModel;

  const TmcCategoryModel._();

  /// JSON для записи в БД.
  @override
  Map<String, dynamic> toJson() =>
      _$TmcCategoryModelToJson(this as _TmcCategoryModel);

  /// Из JSON.
  factory TmcCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$TmcCategoryModelFromJson(json);

  /// Из доменной сущности.
  factory TmcCategoryModel.fromDomain(TmcCategory category) => TmcCategoryModel(
        id: category.id,
        companyId: category.companyId,
        parentId: category.parentId,
        name: category.name,
        code: category.code,
        sortOrder: category.sortOrder,
        isArchived: category.isArchived,
        archivedAt: category.archivedAt,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        createdBy: category.createdBy,
      );

  /// В доменную сущность.
  TmcCategory toDomain() => TmcCategory(
        id: id,
        companyId: companyId,
        parentId: parentId,
        name: name,
        code: code,
        sortOrder: sortOrder,
        isArchived: isArchived,
        archivedAt: archivedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
      );

  /// JSON для insert/update.
  Map<String, dynamic> toWriteJson({required bool includeId}) {
    final json = toJson();
    json.remove('created_at');
    json.remove('updated_at');
    if (!includeId || id.isEmpty) {
      json.remove('id');
    }
    return json;
  }
}

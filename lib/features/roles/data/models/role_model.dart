import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart';

part 'role_model.freezed.dart';
part 'role_model.g.dart';

/// Модель роли для работы с API/БД
@freezed
abstract class RoleModel with _$RoleModel {
  /// Конструктор для создания [RoleModel].
  ///
  /// Используется для маппинга данных из БД.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory RoleModel({
    required String id,
    @JsonKey(name: 'role_name') required String name,
    required String description,
    String? companyId,
    @JsonKey(name: 'is_system') @Default(false) bool isSystem,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _RoleModel;

  const RoleModel._();

  /// Создаёт [RoleModel] из JSON.
  factory RoleModel.fromJson(Map<String, dynamic> json) =>
      _$RoleModelFromJson(json);

  /// Преобразование в доменную сущность
  Role toEntity() => Role(
        id: id,
        name: name,
        description: description,
        companyId: companyId,
        isSystem: isSystem,
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// Создание модели из доменной сущности
  factory RoleModel.fromEntity(Role role) => RoleModel(
        id: role.id,
        name: role.name,
        description: role.description,
        companyId: role.companyId,
        isSystem: role.isSystem,
        createdAt: role.createdAt,
        updatedAt: role.updatedAt,
      );
}

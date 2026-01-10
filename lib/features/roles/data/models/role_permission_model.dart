import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_permission_model.freezed.dart';
part 'role_permission_model.g.dart';

/// Модель разрешения роли для работы с API/БД
@freezed
abstract class RolePermissionModel with _$RolePermissionModel {
  /// Конструктор для создания [RolePermissionModel].
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory RolePermissionModel({
    required String id,
    required String roleId,
    String? companyId,
    required String moduleCode,
    required String permissionCode,
    @Default(true) bool isEnabled,
  }) = _RolePermissionModel;

  /// Создаёт [RolePermissionModel] из JSON.
  factory RolePermissionModel.fromJson(Map<String, dynamic> json) =>
      _$RolePermissionModelFromJson(json);
}

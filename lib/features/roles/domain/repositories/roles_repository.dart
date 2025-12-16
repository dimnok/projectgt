import 'package:projectgt/features/roles/domain/entities/role.dart';
import 'package:projectgt/features/roles/domain/entities/module.dart';

/// Абстрактный репозиторий для работы с ролями
abstract class RolesRepository {
  /// Получить все роли
  Future<List<Role>> getAllRoles();

  /// Получить все модули системы
  Future<List<Module>> getAllModules();

  /// Создать новую роль
  Future<Role> createRole({
    required String name,
    required String description,
  });

  /// Обновить роль
  Future<void> updateRole(Role role);

  /// Удалить роль
  Future<void> deleteRole(String id);

  /// Получить права для роли
  /// Возвращает Map: {moduleId: {permissionCode: isEnabled}}
  Future<Map<String, Map<String, bool>>> getRolePermissions(String roleId);

  /// Получить поток прав для роли (Realtime)
  Stream<Map<String, Map<String, bool>>> getRolePermissionsStream(
      String roleId);

  /// Обновить права роли
  /// Принимает Map: {moduleId: {permissionCode: isEnabled}}
  Future<void> updateRolePermissions(
    String roleId,
    Map<String, Map<String, bool>> permissions,
  );
}

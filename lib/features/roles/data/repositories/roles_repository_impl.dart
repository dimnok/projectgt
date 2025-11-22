import 'package:projectgt/features/roles/data/models/module_model.dart';
import 'package:projectgt/features/roles/data/models/role_model.dart';
import 'package:projectgt/features/roles/domain/entities/module.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart';
import 'package:projectgt/features/roles/domain/repositories/roles_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Реализация репозитория для работы с ролями через Supabase.
class RolesRepositoryImpl implements RolesRepository {
  final SupabaseClient _supabase;

  /// Создаёт экземпляр [RolesRepositoryImpl].
  RolesRepositoryImpl(this._supabase);

  @override
  Future<List<Role>> getAllRoles() async {
    try {
      final response = await _supabase
          .from('roles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RoleModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Ошибка при загрузке ролей: $e');
    }
  }

  @override
  Future<List<Module>> getAllModules() async {
    try {
      final response = await _supabase
          .from('app_modules')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => ModuleModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Ошибка при загрузке модулей: $e');
    }
  }

  @override
  Future<Role> createRole({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _supabase
          .from('roles')
          .insert({
            'role_name': name,
            'description': description,
            'is_system': false,
          })
          .select()
          .single();

      return RoleModel.fromJson(response).toEntity();
    } catch (e) {
      if (e.toString().contains('duplicate')) {
        throw Exception('Роль с таким названием уже существует');
      }
      throw Exception('Ошибка при создании роли: $e');
    }
  }

  @override
  Future<void> updateRole(Role role) async {
    try {
      await _supabase.from('roles').update({
        'role_name': role.name,
        'description': role.description,
      }).eq('id', role.id);
    } catch (e) {
      throw Exception('Ошибка при обновлении роли: $e');
    }
  }

  @override
  Future<void> deleteRole(String id) async {
    try {
      // Проверяем, не является ли роль системной
      final role = await _supabase
          .from('roles')
          .select('is_system')
          .eq('id', id)
          .single();

      if (role['is_system'] == true) {
        throw Exception('Системные роли нельзя удалить');
      }

      await _supabase.from('roles').delete().eq('id', id);
    } catch (e) {
      throw Exception('Ошибка при удалении роли: $e');
    }
  }

  /// Преобразует список прав из БД в карту.
  Map<String, Map<String, bool>> _transformPermissions(List<dynamic> data) {
    final permissions = <String, Map<String, bool>>{};

    for (final item in data) {
      final moduleCode = item['module_code'] as String;
      final permissionCode = item['permission_code'] as String;
      final isEnabled = item['is_enabled'] as bool;

      permissions[moduleCode] ??= {};
      permissions[moduleCode]![permissionCode] = isEnabled;
    }

    return permissions;
  }

  @override
  Future<Map<String, Map<String, bool>>> getRolePermissions(
      String roleId) async {
    try {
      final response = await _supabase
          .from('role_permissions')
          .select('module_code, permission_code, is_enabled')
          .eq('role_id', roleId);

      return _transformPermissions(response);
    } catch (e) {
      throw Exception('Ошибка при загрузке прав роли: $e');
    }
  }

  @override
  Stream<Map<String, Map<String, bool>>> getRolePermissionsStream(
      String roleId) {
    return _supabase
        .from('role_permissions')
        .stream(primaryKey: ['id'])
        .eq('role_id', roleId)
        .map((data) => _transformPermissions(data));
  }

  @override
  Future<void> updateRolePermissions(
    String roleId,
    Map<String, Map<String, bool>> permissions,
  ) async {
    try {
      final updates = <Map<String, dynamic>>[];

      permissions.forEach((moduleCode, perms) {
        perms.forEach((permissionCode, isEnabled) {
          updates.add({
            'role_id': roleId,
            'module_code': moduleCode,
            'permission_code': permissionCode,
            'is_enabled': isEnabled,
          });
        });
      });

      if (updates.isEmpty) return;

      await _supabase.from('role_permissions').upsert(
            updates,
            onConflict: 'role_id, module_code, permission_code',
          );
    } catch (e) {
      throw Exception('Ошибка при обновлении прав роли: $e');
    }
  }
}

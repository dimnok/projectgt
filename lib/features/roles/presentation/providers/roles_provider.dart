import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/roles/data/repositories/roles_repository_impl.dart';
import 'package:projectgt/features/roles/domain/entities/module.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart';
import 'package:projectgt/features/roles/domain/repositories/roles_repository.dart';

/// Провайдер репозитория ролей
final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RolesRepositoryImpl(supabase);
});

/// Провайдер списка модулей
final modulesProvider = FutureProvider<List<Module>>((ref) async {
  final repository = ref.watch(rolesRepositoryProvider);
  return repository.getAllModules();
});

/// Провайдер для управления состоянием ролей
final rolesNotifierProvider =
    StateNotifierProvider<RolesNotifier, AsyncValue<List<Role>>>((ref) {
  final repository = ref.watch(rolesRepositoryProvider);
  return RolesNotifier(repository);
});

/// Провайдер для получения роли по ID
final roleByIdProvider = FutureProvider.family<Role?, String>((ref, roleId) async {
  final repository = ref.watch(rolesRepositoryProvider);
  final roles = await repository.getAllRoles();
  try {
    return roles.firstWhere((r) => r.id == roleId);
  } catch (_) {
    return null;
  }
});

/// Провайдер для получения прав конкретной роли
final rolePermissionsProvider =
    FutureProvider.family<Map<String, Map<String, bool>>, String>(
        (ref, roleId) async {
  final repository = ref.watch(rolesRepositoryProvider);
  return repository.getRolePermissions(roleId);
});

/// Контроллер для управления правами (сохранение)
final rolePermissionsControllerProvider = Provider((ref) {
  final repository = ref.watch(rolesRepositoryProvider);
  return RolePermissionsController(repository, ref);
});

/// Контроллер для управления правами
class RolePermissionsController {
  final RolesRepository _repository;
  final Ref _ref;

  /// Создаёт экземпляр [RolePermissionsController].
  RolePermissionsController(this._repository, this._ref);

  /// Обновить права роли
  Future<void> updatePermissions(
    String roleId,
    Map<String, Map<String, bool>> permissions,
  ) async {
    await _repository.updateRolePermissions(roleId, permissions);
    // Инвалидируем кэш прав для этой роли, чтобы обновить UI
    _ref.invalidate(rolePermissionsProvider(roleId));
  }
}

/// StateNotifier для управления ролями
class RolesNotifier extends StateNotifier<AsyncValue<List<Role>>> {
  final RolesRepository _repository;

  /// Создаёт экземпляр [RolesNotifier].
  RolesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRoles();
  }

  /// Загрузить все роли
  Future<void> loadRoles() async {
    state = const AsyncValue.loading();
    try {
      final roles = await _repository.getAllRoles();
      state = AsyncValue.data(roles);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Создать новую роль
  Future<void> createRole({
    required String name,
    required String description,
  }) async {
    try {
      final newRole = await _repository.createRole(
        name: name,
        description: description,
      );
      
      // Обновляем список ролей
      final currentRoles = state.value ?? [];
      state = AsyncValue.data([newRole, ...currentRoles]);
    } catch (e, stack) {
      // Сохраняем текущее состояние и показываем ошибку
      state = AsyncValue.error(e, stack);
      // Перезагружаем список для восстановления состояния
      await loadRoles();
      rethrow; // Пробрасываем ошибку для обработки в UI
    }
  }

  /// Обновить роль
  Future<void> updateRole(Role role) async {
    try {
      await _repository.updateRole(role);
      
      // Обновляем роль в списке
      final currentRoles = state.value ?? [];
      final updatedRoles = currentRoles.map((r) {
        return r.id == role.id ? role : r;
      }).toList();
      
      state = AsyncValue.data(updatedRoles);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      await loadRoles();
      rethrow;
    }
  }

  /// Удалить роль
  Future<void> deleteRole(String id) async {
    try {
      await _repository.deleteRole(id);
      
      // Удаляем роль из списка
      final currentRoles = state.value ?? [];
      final updatedRoles = currentRoles.where((r) => r.id != id).toList();
      
      state = AsyncValue.data(updatedRoles);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      await loadRoles();
      rethrow;
    }
  }
}

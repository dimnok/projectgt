import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Провайдер прав текущего пользователя (Realtime).
/// Загружает права из БД и подписывается на изменения, если у пользователя установлен [roleId].
final userPermissionsProvider =
    StreamProvider<Map<String, Map<String, bool>>>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;

  if (user == null || user.roleId == null) {
    return Stream.value({});
  }

  final repo = ref.watch(rolesRepositoryProvider);
  return repo.getRolePermissionsStream(user.roleId!);
});

/// Сервис для проверки прав доступа.
class PermissionService {
  final Map<String, Map<String, bool>> _permissions;
  final User? _user;
  final bool _isLoading;

  /// Создаёт сервис проверки прав.
  ///
  /// [_permissions] — карта прав текущего пользователя.
  /// [_user] — текущий пользователь.
  /// [_isLoading] — флаг загрузки прав.
  PermissionService(this._permissions, this._user, {bool isLoading = false})
      : _isLoading = isLoading;

  /// Проверяет наличие права на выполнение действия.
  ///
  /// [module] — код модуля (например, 'inventory').
  /// [permission] — код разрешения (например, 'create').
  bool can(String module, String permission) {
    if (_user == null) return false;

    // 0. Владелец имеет полный доступ ко всему (Бог системы)
    if (_user.system_role == 'owner') return true;

    // 1. Новая система (по role_id)
    if (_user.roleId != null) {
      // Если права еще загружаются, считаем что доступа нет (или можно вернуть false, чтобы не блокировать UI, а скрыть элементы)
      // Но лучше безопасно отказать.
      if (_isLoading) return false;

      final modulePerms = _permissions[module];
      if (modulePerms != null) {
        // Проверяем конкретное право
        if (modulePerms[permission] == true) return true;

        // Если запрашивается любое право кроме 'read', но нет 'read', то скорее всего доступа нет вообще.
        // Но здесь мы проверяем атомарно.
      }
      return false;
    }

    // 2. Fallback отключен. Если role_id нет или он не загружен - прав нет.
    return false;
  }
}

/// Провайдер сервиса проверки прав.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  final authState = ref.watch(authProvider);
  final permissionsAsync = ref.watch(userPermissionsProvider);

  return PermissionService(
    permissionsAsync.valueOrNull ?? {},
    authState.user,
    isLoading: permissionsAsync.isLoading,
  );
});

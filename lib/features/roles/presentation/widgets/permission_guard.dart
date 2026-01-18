import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Виджет для ограничения доступа к элементам UI на основе прав пользователя.
///
/// Отображает [child], если у пользователя есть право [permission] в модуле [module].
/// Иначе отображает [fallback] (по умолчанию пустой виджет).
class PermissionGuard extends ConsumerWidget {
  /// Код модуля (например, 'works').
  final String module;

  /// Код разрешения (например, 'create', 'read', 'update', 'delete').
  final String permission;

  /// Виджет, который нужно показать при наличии прав.
  final Widget child;

  /// Виджет, который нужно показать при отсутствии прав.
  final Widget? fallback;

  /// Создаёт виджет защиты доступа.
  ///
  /// [module] — код модуля.
  /// [permission] — код разрешения.
  /// [child] — виджет, который нужно показать при наличии прав.
  /// [fallback] — виджет при отсутствии прав.
  const PermissionGuard({
    super.key,
    required this.module,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);

    if (permissionService.can(module, permission)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_actions.dart';
import 'object_list_shared.dart';

/// Панель детальной информации об объекте для десктопной версии.
class ObjectDetailsPanel extends ConsumerWidget {
  /// Данные объекта для отображения.
  final ObjectEntity object;

  /// Колбэк для перехода в режим редактирования.
  final VoidCallback onEdit;

  /// Колбэк при успешном удалении.
  final VoidCallback onDeleteSuccess;

  /// Создает панель деталей объекта.
  const ObjectDetailsPanel({
    super.key,
    required this.object,
    required this.onEdit,
    required this.onDeleteSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ObjectAvatar(object: object, radius: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            object.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            object.address,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  PermissionGuard(
                    module: 'objects',
                    permission: 'update',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onEdit,
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 22,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'objects',
                    permission: 'delete',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => ObjectActions.delete(
                        context: context,
                        ref: ref,
                        object: object,
                        onSuccess: onDeleteSuccess,
                      ),
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 22,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ObjectDetailsSections(object: object, labelWidth: 200),
          ),
        ),
      ],
    );
  }
}

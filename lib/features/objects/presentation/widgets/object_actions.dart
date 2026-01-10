import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_list_shared.dart';
import 'package:projectgt/features/objects/presentation/widgets/object_form_modal.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Единый контроллер действий над объектом.
/// Устраняет дублирование бизнес-логики редактирования и удаления.
class ObjectActions {
  /// Открывает форму для редактирования объекта.
  static void edit(BuildContext context, ObjectEntity object) {
    ObjectFormModal.show(
      context,
      object: object,
      onSuccess: (_) =>
          SnackBarUtils.showSuccess(context, 'Изменения сохранены'),
    );
  }

  /// Выполняет удаление объекта с подтверждением.
  static Future<void> delete({
    required BuildContext context,
    required WidgetRef ref,
    required ObjectEntity object,
    VoidCallback? onSuccess,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await ObjectDialogs.showConfirmDelete(
      context: context,
      title: 'Удалить объект?',
      message: 'Вы уверены, что хотите удалить объект "${object.name}"?',
    );

    if (confirmed != true) return;

    try {
      await ref.read(objectProvider.notifier).deleteObject(object.id);
      onSuccess?.call();
      SnackBarUtils.showInfoByMessenger(messenger, 'Объект удалён');
    } catch (e) {
      SnackBarUtils.showErrorByMessenger(
        messenger,
        'Ошибка удаления: ${e.toString()}',
      );
    }
  }
}

/// Общий виджет кнопок действий (Редактировать/Удалить) для AppBar.
class ObjectAppBarActions extends ConsumerWidget {
  /// Объект, над которым совершаются действия.
  final ObjectEntity object;

  /// Колбэк при успешном удалении (например, закрыть экран или сбросить выбор).
  final VoidCallback? onDeleteSuccess;

  /// Создаёт виджет кнопок действий.
  const ObjectAppBarActions({
    super.key,
    required this.object,
    this.onDeleteSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PermissionGuard(
          module: 'objects',
          permission: 'update',
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => ObjectActions.edit(context, object),
            child: const Icon(
              CupertinoIcons.pencil,
              color: Colors.amber,
              size: 22,
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
              color: theme.colorScheme.error,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_item.dart';
import '../providers/work_items_provider.dart';
import 'work_item_form_improved.dart';

/// Контекстное меню для работ в смене.
///
/// Предоставляет админу возможность редактировать, удалять и добавлять работы
/// даже в закрытых сменах через долгий таб (long press).
class WorkItemContextMenu {
  /// Показывает контекстное меню для работы.
  ///
  /// Доступно для:
  /// - Владельца открытой смены
  /// - Администратора (на любой смене - открытой или закрытой)
  ///
  /// [context] — BuildContext для показа меню
  /// [item] — работа, по которой нажали долгий таб
  /// [workId] — ID смены
  /// [parentContext] — контекст родительского экрана для модалок
  /// [ref] — Riverpod WidgetRef для доступа к провайдерам
  /// [onDeleteComplete] — callback после успешного удаления (для обновления фильтров)
  static void show({
    required BuildContext context,
    required WorkItem item,
    required String workId,
    required BuildContext parentContext,
    required WidgetRef ref,
    VoidCallback? onDeleteComplete,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(item.name, style: const TextStyle(fontSize: 14)),
        actions: <CupertinoActionSheetAction>[
          // Действие: Редактировать
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              openEditWorkItemForm(
                context: parentContext,
                item: item,
                workId: workId,
                ref: ref,
              );
            },
            child: const Text('Редактировать'),
          ),

          // Действие: Удалить (деструктивное)
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkItem(
                context: parentContext,
                item: item,
                workId: workId,
                ref: ref,
                onComplete: onDeleteComplete,
              );
            },
            child: const Text('Удалить'),
          ),

          // Действие: Добавить новую работу
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              openNewWorkItemForm(
                context: parentContext,
                workId: workId,
              );
            },
            child: const Text('Добавить новую работу'),
          ),
        ],

        // Кнопка Отмена
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  /// Открывает форму редактирования работы.
  ///
  /// Использует существующий компонент [WorkItemFormImproved].
  static void openEditWorkItemForm({
    required BuildContext context,
    required WorkItem item,
    required String workId,
    required WidgetRef ref,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Center(
          child: WorkItemFormImproved(
            workId: workId,
            initial: item,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => WorkItemFormImproved(
          workId: workId,
          initial: item,
        ),
      );
    }
  }

  /// Показывает диалог подтверждения удаления работы.
  ///
  /// После подтверждения удаляет работу из БД и обновляет состояние.
  static void _deleteWorkItem({
    required BuildContext context,
    required WorkItem item,
    required String workId,
    required WidgetRef ref,
    VoidCallback? onComplete,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить работу "${item.name}"?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();

              // Удаляем работу из провайдера
              await ref
                  .read(workItemsProvider(workId).notifier)
                  .deleteOptimistic(item.id);

              // Вызываем callback для обновления фильтров в родительском компоненте
              onComplete?.call();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Открывает форму добавления новой работы в смену.
  ///
  /// Использует существующий компонент [WorkItemFormImproved] без initial значения.
  static void openNewWorkItemForm({
    required BuildContext context,
    required String workId,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Center(
          child: WorkItemFormImproved(workId: workId),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => WorkItemFormImproved(workId: workId),
      );
    }
  }
}

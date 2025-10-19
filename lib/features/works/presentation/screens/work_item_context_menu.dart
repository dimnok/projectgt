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
              _editWorkItem(
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
              _addNewWorkItem(
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
  static void _editWorkItem({
    required BuildContext context,
    required WorkItem item,
    required String workId,
    required WidgetRef ref,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top,
      ),
      builder: (ctx) {        return _buildStylizedModalSheet(
          context,
          WorkItemFormImproved(
            workId: workId,
            initial: item,
          ),
        );
      },
    );
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
  static void _addNewWorkItem({
    required BuildContext context,
    required String workId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
      ),
      builder: (ctx) => _buildStylizedModalSheet(
        context,
        WorkItemFormImproved(workId: workId),
      ),
    );
  }

  /// Строит стилизованное модальное окно (bottom sheet).
  ///
  /// Используется общий стиль для всех модалок с работами.
  static Widget _buildStylizedModalSheet(
    BuildContext context,
    Widget content,
  ) {
    final theme = Theme.of(context);

    final modalContent = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
        // Если это WorkItemFormImproved без scrollController, добавляем его
        Widget finalContent = content;
        if (content is WorkItemFormImproved && content.scrollController == null) {
          finalContent = WorkItemFormImproved(
            workId: content.workId,
            initial: content.initial,
            scrollController: scrollController,
          );
        }
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: finalContent,
        );
      },
      ),
    );

    // Проверяем есть ли ResponsiveUtils
    try {
      final isDesktop = ResponsiveUtils.isDesktop(context);
      if (isDesktop) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Для десктопа - ограничиваем ширину 50%
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: screenWidth * 0.5,
            child: modalContent,
          ),
        );
      }
    } catch (_) {
      // ResponsiveUtils может быть недоступен, используем fallback
    }
    
    return modalContent;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:projectgt/features/works/presentation/screens/work_form_screen.dart';
import 'package:projectgt/features/works/presentation/screens/work_hour_form_modal.dart';
import 'package:projectgt/features/works/presentation/screens/new_material_modal.dart';
import 'package:projectgt/features/export/presentation/widgets/export_work_item_edit_modal.dart';
import 'package:projectgt/features/export/domain/entities/work_search_result.dart';
import 'package:projectgt/features/works/domain/entities/work_hour.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Утилитарный класс для работы с модальными окнами.
///
/// Содержит методы для отображения различных типов модальных окон в приложении.
class ModalUtils {
  /// Создает компактный заголовок для модальных окон с кнопкой закрытия.
  ///
  /// [title] - текст заголовка.
  /// [onClose] - callback для закрытия модального окна.
  /// [theme] - тема приложения для стилизации.
  static Widget buildModalHeader({
    required String title,
    required VoidCallback onClose,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onClose,
            minimumSize: const Size(40, 40),
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 28,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// Создает адаптивный контейнер для содержимого модальных форм.
  ///
  /// [child] - содержимое контейнера.
  /// [context] - контекст для определения размеров экрана.
  /// [maxWidthMobile] - максимальная ширина для мобильных устройств.
  /// [useFullWidthDesktop] - использовать полную ширину на десктопе.
  static Widget buildAdaptiveFormContainer({
    required Widget child,
    required BuildContext context,
    double? maxWidthMobile,
    bool useFullWidthDesktop = true,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop && useFullWidthDesktop) {
      // На десктопе используем всю доступную ширину
      return child;
    } else {
      // На мобильном или если указано ограничение
      final maxWidth = maxWidthMobile ?? 700.0;
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      );
    }
  }

  /// Создает плавающие кнопки для модальных окон.
  ///
  /// [onSave] - callback для кнопки сохранения.
  /// [onCancel] - callback для кнопки отмены.
  /// [isLoading] - флаг загрузки.
  /// [saveText] - текст на кнопке сохранения.
  /// [cancelText] - текст на кнопке отмены.
  /// [leftOffset] - отступ слева (по умолчанию 24).
  /// [rightOffset] - отступ справа (по умолчанию 24).
  /// [bottomOffset] - отступ снизу (по умолчанию 24).
  static Widget buildFloatingButtons({
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required bool isLoading,
    required String saveText,
    String cancelText = 'Отмена',
    double leftOffset = 24,
    double rightOffset = 24,
    double bottomOffset = 24,
  }) {
    return Positioned(
      left: leftOffset,
      right: rightOffset,
      bottom: bottomOffset,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: _FloatingFormButtons(
            onSave: onSave,
            onCancel: onCancel,
            isLoading: isLoading,
            saveText: saveText,
            cancelText: cancelText,
          ),
        ),
      ),
    );
  }

  /// Показывает модальное окно с формой редактирования/создания сотрудника.
  ///
  /// [context] - контекст для отображения модального окна.
  /// [employeeId] - ID сотрудника для редактирования (null для создания нового).
  static Future<void> showEmployeeFormModal(BuildContext context,
      {String? employeeId}) {
    return _showFormModal(
      context: context,
      formBuilder: (scrollController) => EmployeeFormScreen(
        employeeId: employeeId,
        scrollController: scrollController,
      ),
    );
  }

  /// Показывает модальное окно с формой создания смены.
  ///
  /// [context] - контекст для отображения модального окна.
  static Future<void> showWorkFormModal(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => const Center(
          child: WorkFormScreen(),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const WorkFormScreen(),
      );
    }
  }

  /// Показывает модальное окно с формой добавления сотрудника в смену.
  ///
  /// [context] - контекст для отображения модального окна.
  /// [workId] - ID смены для добавления сотрудника.
  /// [initial] - начальные данные для редактирования (null для создания нового).
  static Future<void> showWorkHourFormModal(
    BuildContext context, {
    required String workId,
    WorkHour? initial,
  }) {
    return _showFormModal(
      context: context,
      formBuilder: (scrollController) => WorkHourFormModal(
        workId: workId,
        initial: initial,
        scrollController: scrollController,
      ),
    );
  }

  /// Показывает модалку "Новый материал" в общем каркасе модалок.
  /// Возвращает результат Navigator.pop (например, Map c полями нового материала).
  static Future<dynamic> showNewMaterialModal(
    BuildContext context, {
    required String objectId,
    required String system,
    required String subsystem,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Center(
          child: NewMaterialModal(
            objectId: objectId,
            system: system,
            subsystem: subsystem,
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isDismissible: false, // Запрет закрытия по тапу вне
      enableDrag: false, // Запрет закрытия свайпом вниз
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top,
      ),
      builder: (sheetContext) => NewMaterialModal(
        objectId: objectId,
        system: system,
        subsystem: subsystem,
      ),
    );
  }

  /// Показывает меню действий для работы из результатов поиска.
  ///
  /// [context] - контекст для отображения меню (должен быть контекстом ячейки).
  /// [initialData] - данные работы.
  /// [onEdit] - callback для редактирования (если null, пункт скрыт).
  /// [onNavigateToWork] - callback для перехода к смене.
  static Future<void> showExportWorkItemActionDialog(
    BuildContext context, {
    required WorkSearchResult initialData,
    VoidCallback? onEdit,
    required VoidCallback onNavigateToWork,
  }) {
    final theme = Theme.of(context);

    // Получаем RenderBox ячейки через контекст
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return Future.value();
    }

    // Получаем Overlay для правильного позиционирования
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) {
      return Future.value();
    }

    // Вычисляем глобальную позицию ячейки относительно overlay
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    // Позиционируем меню под ячейкой
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + renderBox.size.height + 4, // Небольшой отступ снизу
      offset.dx + renderBox.size.width,
      offset.dy + renderBox.size.height + 4,
    );

    final items = <PopupMenuEntry>[];

    if (onEdit != null) {
      items.add(
        PopupMenuItem(
          onTap: onEdit,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                'Редактировать',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    items.add(
      PopupMenuItem(
        onTap: onNavigateToWork,
        child: Row(
          children: [
            Icon(
              Icons.open_in_new_outlined,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Text(
              'К смене',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );

    return showMenu(
      context: context,
      position: position,
      elevation: 8,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      items: items,
    );
  }

  /// Показывает модальное окно для редактирования работы из результатов поиска.
  ///
  /// [context] - контекст для отображения модального окна.
  /// [initialData] - начальные данные для редактирования.
  static Future<void> showExportWorkItemEditModal(
    BuildContext context, {
    required WorkSearchResult initialData,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            kToolbarHeight,
      ),
      builder: (ctx) => ExportWorkItemEditModal(
        initialData: initialData,
      ),
    );
  }

  /// Универсальный метод для отображения модальных окон с формами.
  ///
  /// [context] - контекст для отображения модального окна.
  /// [formBuilder] - функция для создания виджета формы с контроллером прокрутки.
  /// [useDraggable] - использовать DraggableScrollableSheet (true) или обычный BottomSheet (false).
  static Future<void> _showFormModal({
    required BuildContext context,
    required Widget Function(ScrollController scrollController) formBuilder,
    bool useDraggable = true,
  }) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    Widget buildContent(BuildContext context, ScrollController? controller) {
      return Container(
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
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: formBuilder(controller ?? ScrollController()),
        ),
      );
    }

    Widget modalContent;

    if (useDraggable) {
      modalContent = DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) =>
            buildContent(context, scrollController),
      );
    } else {
      modalContent = buildContent(context, null);
    }

    // Для десктопов ограничиваем ширину, но сохраняем привязку к низу
    if (isDesktop) {
      modalContent = Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: modalContent,
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isDismissible: false, // Запрет закрытия по тапу вне
      enableDrag: false, // Запрет закрытия свайпом вниз
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top,
      ),
      builder: (context) => modalContent,
    );
  }
}

/// Внутренний виджет плавающих кнопок для модальных окон.
class _FloatingFormButtons extends StatelessWidget {
  /// Обработчик нажатия на кнопку сохранения.
  final VoidCallback onSave;

  /// Обработчик нажатия на кнопку отмены.
  final VoidCallback onCancel;

  /// Флаг загрузки.
  final bool isLoading;

  /// Текст на кнопке сохранения.
  final String saveText;

  /// Текст на кнопке отмены.
  final String cancelText;

  /// Создает плавающие кнопки формы.
  const _FloatingFormButtons({
    required this.onSave,
    required this.onCancel,
    required this.isLoading,
    required this.saveText,
    required this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    const buttonHeight = 44.0; // Стандартный размер для touch targets

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(buttonHeight),
              shape: const StadiumBorder(),
              elevation: isMobile ? 2 : 0,
              shadowColor:
                  isMobile ? Colors.black.withValues(alpha: 0.2) : null,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: Text(cancelText),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onSave,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(buttonHeight),
              shape: const StadiumBorder(),
              elevation: isMobile ? 4 : 1,
              shadowColor:
                  isMobile ? Colors.black.withValues(alpha: 0.3) : null,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CupertinoActivityIndicator(),
                  )
                : Text(saveText),
          ),
        ),
      ],
    );
  }
}

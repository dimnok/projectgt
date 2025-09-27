import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:projectgt/features/works/presentation/screens/work_form_screen.dart';
import 'package:projectgt/features/works/presentation/screens/work_hour_form_modal.dart';
import 'package:projectgt/features/works/presentation/screens/new_material_modal.dart';
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

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
  /// [scrollController] - контроллер прокрутки для отслеживания скрытия/показа.
  /// [leftOffset] - отступ слева (по умолчанию 24).
  /// [rightOffset] - отступ справа (по умолчанию 24).
  /// [bottomOffset] - отступ снизу (по умолчанию 24).
  static Widget buildFloatingButtons({
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required bool isLoading,
    required String saveText,
    String cancelText = 'Отмена',
    ScrollController? scrollController,
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
            scrollController: scrollController,
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
    return _showFormModal(
      context: context,
      formBuilder: (scrollController) => WorkFormScreen(
        scrollController: scrollController,
        parentContext: context,
      ),
    );
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
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final scrollController = ScrollController();

    Widget modalContent = Container(
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
        child: Wrap(
          children: [
            NewMaterialModal(
              objectId: objectId,
              system: system,
              subsystem: subsystem,
              scrollController: scrollController,
            ),
          ],
        ),
      ),
    );

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top,
      ),
      builder: (context) => modalContent,
    );
  }

  /// Универсальный метод для отображения модальных окон с формами.
  ///
  /// [context] - контекст для отображения модального окна.
  /// [formBuilder] - функция для создания виджета формы с контроллером прокрутки.
  static Future<void> _showFormModal({
    required BuildContext context,
    required Widget Function(ScrollController scrollController) formBuilder,
  }) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget modalContent = Container(
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
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: formBuilder(scrollController),
        ),
      ),
    );

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top,
      ),
      builder: (context) => modalContent,
    );
  }
}

/// Внутренний виджет плавающих кнопок для модальных окон.
class _FloatingFormButtons extends StatefulWidget {
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

  /// Контроллер прокрутки для отслеживания.
  final ScrollController? scrollController;

  /// Создает плавающие кнопки формы.
  const _FloatingFormButtons({
    required this.onSave,
    required this.onCancel,
    required this.isLoading,
    required this.saveText,
    required this.cancelText,
    this.scrollController,
  });

  @override
  State<_FloatingFormButtons> createState() => _FloatingFormButtonsState();
}

class _FloatingFormButtonsState extends State<_FloatingFormButtons> {
  bool _showButtons = true;
  Timer? _hideTimer;
  double _lastScrollPosition = 0.0;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (widget.scrollController != null) {
      final currentPosition = widget.scrollController!.position.pixels;

      // Если позиция изменилась, значит идет прокрутка
      if (currentPosition != _lastScrollPosition) {
        _lastScrollPosition = currentPosition;

        // Скрываем кнопки при прокрутке
        if (_showButtons) {
          setState(() {
            _showButtons = false;
          });
        }

        // Отменяем предыдущий таймер
        _hideTimer?.cancel();

        // Запускаем новый таймер на показ кнопок (только если клавиатура скрыта)
        _hideTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted && !_keyboardVisible) {
            setState(() {
              _showButtons = true;
            });
          }
        });
      }
    }
  }

  void _updateKeyboardVisibility() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    if (_keyboardVisible != isKeyboardVisible) {
      setState(() {
        _keyboardVisible = isKeyboardVisible;
        if (_keyboardVisible) {
          // Скрываем кнопки когда появляется клавиатура
          _showButtons = false;
          _hideTimer?.cancel();
        } else {
          // Показываем кнопки когда клавиатура скрывается
          _hideTimer?.cancel();
          _hideTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _showButtons = true;
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Отслеживаем состояние клавиатуры
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardVisibility();
    });

    final isMobile = ResponsiveUtils.isMobile(context);
    final buttonHeight = isMobile ? 26.0 : 44.0;

    return AnimatedScale(
      scale: _showButtons ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: _showButtons ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(buttonHeight),
                  shape: const StadiumBorder(),
                  elevation: isMobile ? 2 : 0,
                  shadowColor:
                      isMobile ? Colors.black.withValues(alpha: 0.2) : null,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: Text(widget.cancelText),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onSave,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(buttonHeight),
                  shape: const StadiumBorder(),
                  elevation: isMobile ? 4 : 1,
                  shadowColor:
                      isMobile ? Colors.black.withValues(alpha: 0.3) : null,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CupertinoActivityIndicator(),
                      )
                    : Text(widget.saveText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

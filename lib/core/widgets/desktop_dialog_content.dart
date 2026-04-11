import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// Виджет для содержимого модального окна (Dialog) на десктопе.
///
/// Используется для отображения форм и информационных окон через [showDialog].
///
/// Особенности:
/// - Фиксированная или ограниченная ширина
/// - Кнопка закрытия (крестик) в заголовке
/// - Скроллящийся контент
/// - Адаптивность к высоте экрана
///
/// Пример использования:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => Dialog(
///     backgroundColor: Colors.transparent,
///     insetPadding: const EdgeInsets.all(24),
///     child: DesktopDialogContent(
///       title: 'Заголовок',
///       child: Text('Контент...'),
///       footer: Row(
///         mainAxisAlignment: MainAxisAlignment.end,
///         children: [
///           GTSecondaryButton(text: 'Отмена', onPressed: () => Navigator.pop(context)),
///           const SizedBox(width: 16),
///           GTPrimaryButton(text: 'Сохранить', onPressed: () {}),
///         ],
///       ),
///       width: 500,
///     ),
///   ),
/// );
/// ```
class DesktopDialogContent extends StatelessWidget {
  /// Заголовок диалогового окна.
  final String title;

  /// Основное содержимое окна.
  final Widget child;

  /// Виджет подвала (например, кнопки действий).
  final Widget? footer;

  /// Ширина диалогового окна.
  /// По умолчанию 750.
  final double width;

  /// Высота диалогового окна.
  /// Если не указана, подстраивается под контент, но не больше 80% высоты экрана.
  final double? height;

  /// Внутренние отступы контента.
  final EdgeInsetsGeometry padding;

  /// Обработчик закрытия окна.
  /// Если не передан, используется Navigator.of(context).pop().
  final VoidCallback? onClose;

  /// Если задан, видимость кнопки закрытия в заголовке: `true` — показать крестик.
  ///
  /// Используется, когда дочерний виджет должен временно скрыть закрытие диалога
  /// (например, во время редактирования формы с отменой/сохранением внутри контента).
  final ValueListenable<bool>? closeButtonVisibility;

  /// Определяет, должен ли контент быть обернут в скролл.
  /// По умолчанию true. Если false, скролл должен быть реализован внутри child.
  final bool scrollable;

  /// Определяет, показывать ли разделители между заголовком, контентом и подвалом.
  /// По умолчанию true.
  final bool showDividers;

  /// Создаёт содержимое диалогового окна для десктопа.
  const DesktopDialogContent({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.width = 750,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.onClose,
    this.closeButtonVisibility,
    this.scrollable = true,
    this.showDividers = true,
  });

  /// Отображает диалоговое окно с плавной анимацией появления.
  ///
  /// Использует [showGeneralDialog] для реализации кастомной анимации (fade + scale).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? footer,
    double width = 750,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    bool scrollable = true,
    bool showDividers = true,
    bool barrierDismissible = true,
    VoidCallback? onClose,
    ValueListenable<bool>? closeButtonVisibility,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: DesktopDialogContent(
              title: title,
              footer: footer,
              width: width,
              height: height,
              padding: padding,
              scrollable: scrollable,
              showDividers: showDividers,
              onClose: onClose,
              closeButtonVisibility: closeButtonVisibility,
              child: child,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutCubic.transform(animation.value);
        return FadeTransition(
          opacity: animation,
          child: Transform.scale(
            scale: 0.95 + (0.05 * curvedValue),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        height: height,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок с кнопкой закрытия
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _DesktopDialogCloseButton(
                        theme: theme,
                        onClose: onClose ?? () => Navigator.of(context).pop(),
                        visibility: closeButtonVisibility,
                      ),
                    ],
                  ),
                ),

                if (showDividers) const Divider(height: 1),

                // Скроллящийся контент
                Flexible(
                  fit: FlexFit.loose,
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [child],
                          ),
                        )
                      : Padding(padding: padding, child: child),
                ),

                if (footer != null) ...[
                  if (showDividers) const Divider(height: 1),
                  Padding(padding: const EdgeInsets.all(24), child: footer!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopDialogCloseButton extends StatelessWidget {
  const _DesktopDialogCloseButton({
    required this.theme,
    required this.onClose,
    required this.visibility,
  });

  final ThemeData theme;
  final VoidCallback onClose;
  final ValueListenable<bool>? visibility;

  @override
  Widget build(BuildContext context) {
    if (visibility == null) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClose,
        tooltip: 'Закрыть',
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return ListenableBuilder(
      listenable: visibility!,
      builder: (context, _) {
        if (!visibility!.value) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
          tooltip: 'Закрыть',
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

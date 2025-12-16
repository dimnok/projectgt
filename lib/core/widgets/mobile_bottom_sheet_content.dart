import 'package:flutter/material.dart';

/// Виджет для содержимого модального окна (Bottom Sheet) в мобильном стиле.
///
/// Используется для отображения форм и информационных экранов в [showModalBottomSheet].
///
/// Особенности:
/// - Фиксированный заголовок (не скроллится)
/// - Скроллящийся контент
/// - Безопасная зона (SafeArea)
/// - Обработка клавиатуры
///
/// Важно: При вызове [showModalBottomSheet] обязательно используйте `useSafeArea: true`
/// для корректного отображения под системным статус-баром.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true, // Обязательно
///   useSafeArea: true, // Обязательно
///   constraints: const BoxConstraints(maxWidth: 640),
///   shape: const RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
///   ),
///   builder: (context) => MobileBottomSheetContent(
///     title: 'Заголовок',
///     child: Text('Контент...'),
///     footer: ElevatedButton(onPressed: () {}, child: Text('Сохранить')),
///   ),
/// );
/// ```
class MobileBottomSheetContent extends StatelessWidget {
  /// Заголовок модального окна.
  final String title;

  /// Основное содержимое окна.
  final Widget child;

  /// Виджет подвала (например, кнопки действий).
  /// Скроллится вместе с контентом.
  final Widget? footer;

  /// Внутренние отступы контента.
  /// По умолчанию: горизонтальные и вертикальные 20.
  final EdgeInsetsGeometry padding;

  /// Контроллер прокрутки.
  /// Если используется внутри [DraggableScrollableSheet], передайте сюда контроллер.
  final ScrollController? scrollController;

  /// Определяет, должен ли контент быть обернут в скролл.
  /// По умолчанию true. Если false, скролл должен быть реализован внутри child.
  final bool scrollable;

  /// Создаёт содержимое модального окна.
  const MobileBottomSheetContent({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    this.scrollController,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Фиксированный заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Скроллящийся контент
              Flexible(
                child: scrollable
                    ? SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: bottomInset,
                          ),
                          child: Padding(
                            padding: padding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                child,
                                if (footer != null) ...[
                                  const SizedBox(height: 24),
                                  footer!,
                                ],
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.only(bottom: bottomInset),
                        child: Padding(
                          padding: padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: child),
                              if (footer != null) ...[
                                const SizedBox(height: 24),
                                footer!,
                              ],
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ));
  }
}

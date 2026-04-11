import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Виджет для содержимого модального окна (Bottom Sheet) в мобильном стиле.
///
/// Используется для отображения форм и информационных экранов в [showModalBottomSheet].
///
/// Особенности:
/// - Заголовок и контент в одном вертикальном скролле (заголовок уезжает вместе с контентом);
///   по нажатию на заголовок снимается фокус с полей.
/// - Высота листа по контенту до [maxHeightFactor] экрана; длинный контент прокручивается
///   (паттерн `CustomScrollView` + `shrinkWrap`, см. обсуждения к `isScrollControlled`).
/// - [AnimatedPadding] по [MediaQuery.viewInsets] поднимает лист вместе с клавиатурой.
/// - Высота листа ограничивается также «свободной» высотой над клавиатурой
///   (`size.height - viewInsets.bottom`), чтобы контент не уходил под клавиатуру.
/// - У [CustomScrollView] при отсутствии своего [scrollController] включается
///   [ScrollView.primary], чтобы [TextField.scrollPadding] / `ensureVisible` находили скролл.
/// - [ScrollViewKeyboardDismissBehavior.onDrag] — смахивание скролла скрывает клавиатуру.
/// - [sheetBackdrop] — опциональная подложка внутри скругления (прозрачный фон листа).
///
/// Важно: При вызове [showModalBottomSheet] используйте `isScrollControlled: true`
/// и при необходимости `useSafeArea: true`.
///
/// Пример использования:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   useSafeArea: true,
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

  /// Максимальная высота листа как доля от [MediaQuery.size.height] (без учёта клавиатуры).
  final double maxHeightFactor;

  /// Подложка под заголовок, контент и футер (внутри скругления листа).
  ///
  /// Если не null, фон листа по умолчанию становится прозрачным, чтобы была видна
  /// подложка (например атмосфера экрана сотрудников).
  final Widget? sheetBackdrop;

  /// Создаёт содержимое модального окна.
  const MobileBottomSheetContent({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    this.scrollController,
    this.scrollable = true,
    this.maxHeightFactor = 0.92,
    this.sheetBackdrop,
  });

  static void _unfocusKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final keyboardBottom = media.viewInsets.bottom;
    final viewHeight = media.size.height;
    // Не даём листу быть выше области над клавиатурой (иначе нижние поля окажутся под IME).
    final maxSheetHeight = math.min(
      viewHeight * maxHeightFactor,
      math.max(0.0, viewHeight - keyboardBottom),
    );

    final titleWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _unfocusKeyboard,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    const sheetRadius = BorderRadius.vertical(top: Radius.circular(20));
    final sheetSurfaceColor = sheetBackdrop == null
        ? theme.colorScheme.surface
        : Colors.transparent;
    final sheetDecoration = BoxDecoration(
      color: sheetSurfaceColor,
      borderRadius: sheetRadius,
    );

    // Оболочка по ширине листа + [Wrap], чтобы `showModalBottomSheet` с
    // `isScrollControlled: true` не растягивал высоту на весь экран без нужды.
    Widget widthSizedSheet(Widget body) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final sheetBody = sheetBackdrop == null
              ? SafeArea(child: body)
              : Stack(
                  fit: StackFit.loose,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: sheetBackdrop!),
                    SafeArea(child: body),
                  ],
                );
          return Wrap(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: sheetDecoration,
                  child: sheetBody,
                ),
              ),
            ],
          );
        },
      );
    }

    if (scrollable) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardBottom),
        child: widthSizedSheet(
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: CustomScrollView(
              controller: scrollController,
              primary: scrollController == null,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: titleWidget),
                SliverPadding(
                  padding: padding,
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
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
                // Запас прокрутки внизу, чтобы при IME можно было сдвинуть фокусное поле выше.
                if (keyboardBottom > 0)
                  SliverToBoxAdapter(child: SizedBox(height: keyboardBottom)),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: widthSizedSheet(
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleWidget,
              Flexible(
                fit: FlexFit.loose,
                child: Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
      ),
    );
  }
}

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
/// - При [scrollable] == false область «padding + child + footer» в [ListView] с
///   [ListView.shrinkWrap] — высота листа по контенту до [maxHeightFactor], при
///   переполнении прокрутка внутри области между заголовком и низом листа.
/// - [sheetBackdrop] — опциональная подложка внутри скругления (прозрачный фон листа).
/// - [fixedFooter]: заголовок листа и [footer] закреплены; высота листа по контенту
///   (до [maxHeightFactor]), область [child] ограничена по остатку высоты — для
///   [CustomScrollView] задайте [ScrollView.shrinkWrap] = true, чтобы короткий контент
///   не растягивал лист на весь экран. Параметр [scrollable] при [fixedFooter] == true не
///   используется.
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

  /// Закрепить [footer] снизу листа; [child] — скролл между заголовком и футером.
  ///
  /// Высота листа подстраивается под контент (в пределах [maxHeightFactor]). При `true`
  /// ветка [scrollable] не применяется — скролл только внутри [child].
  final bool fixedFooter;

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
    this.fixedFooter = false,
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

    final resolvedPadding = padding.resolve(Directionality.of(context));

    if (fixedFooter) {
      final footerPadded = footer == null
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(
                resolvedPadding.left,
                16,
                resolvedPadding.right,
                8 + resolvedPadding.bottom,
              ),
              child: footer!,
            );
      return AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardBottom),
        child: widthSizedSheet(
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: _FixedFooterSheetLayout(
              maxSheetHeight: maxSheetHeight,
              titleWidget: titleWidget,
              scrollPadding: padding,
              footer: footerPadded,
              child: child,
            ),
          ),
        ),
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                child: ListView(
                  shrinkWrap: true,
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: padding,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Лист с фиксированным футером: высота по контенту, скролл только в середине.
class _FixedFooterSheetLayout extends StatefulWidget {
  /// Создаёт раскладку «заголовок — скролл — футер».
  const _FixedFooterSheetLayout({
    required this.maxSheetHeight,
    required this.titleWidget,
    required this.scrollPadding,
    required this.child,
    this.footer,
  });

  final double maxSheetHeight;
  final Widget titleWidget;
  final EdgeInsetsGeometry scrollPadding;
  final Widget child;
  final Widget? footer;

  @override
  State<_FixedFooterSheetLayout> createState() => _FixedFooterSheetLayoutState();
}

class _FixedFooterSheetLayoutState extends State<_FixedFooterSheetLayout> {
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();

  /// Сумма высот заголовка, футера и вертикальных отступов вокруг скролла.
  double _chromeHeight = 192;

  static const double _minScrollExtent = 120;

  void _measureChrome() {
    if (!mounted) return;
    final titleBox =
        _titleKey.currentContext?.findRenderObject() as RenderBox?;
    final footerBox =
        _footerKey.currentContext?.findRenderObject() as RenderBox?;
    final pad = widget.scrollPadding.resolve(Directionality.of(context));
    var sum = pad.top + pad.bottom;
    if (titleBox != null && titleBox.hasSize) {
      sum += titleBox.size.height;
    }
    if (footerBox != null && footerBox.hasSize) {
      sum += footerBox.size.height;
    }
    if (sum > 0 && (sum - _chromeHeight).abs() > 0.5) {
      setState(() => _chromeHeight = sum);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChrome());

    final maxBody = math.max(
      _minScrollExtent,
      widget.maxSheetHeight - _chromeHeight,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(key: _titleKey, child: widget.titleWidget),
        Padding(
          padding: widget.scrollPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBody),
            child: widget.child,
          ),
        ),
        if (widget.footer != null)
          KeyedSubtree(key: _footerKey, child: widget.footer!),
      ],
    );
  }
}

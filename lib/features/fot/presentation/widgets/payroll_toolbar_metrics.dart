import 'package:flutter/material.dart';

/// Общая геометрия и стили панели фильтров ФОТ (как у вкладки «ФОТ»).
abstract final class PayrollToolbarMetrics {
  /// Высота всех контролов в одной строке панели.
  static const double height = 34;

  /// Радиус внешней «капсулы».
  static const double radius = 18;

  /// Внутренний отступ трека сегментов.
  static const double trackPadding = 2;

  /// Высота сегмента внутри трека.
  static const double segmentHeight = height - trackPadding * 2;

  /// Радиус сегмента.
  static const double segmentRadius = radius - 3;

  /// Горизонтальный отступ подписи сегмента.
  static const double segmentHorizontalPadding = 10;

  /// Размер шрифта сегментов.
  static const double segmentFontSize = 11.5;

  /// Межстрочный интервал подписи сегмента.
  static const double segmentLineHeight = 1.1;

  /// Цвет рамки трека.
  static Color trackBorder(ColorScheme scheme) =>
      scheme.outline.withValues(alpha: 0.38);

  /// Заливка трека.
  static Color trackFill(ColorScheme scheme) =>
      scheme.surfaceContainerHighest.withValues(alpha: 0.45);

  /// Заливка выбранного сегмента.
  static Color selectedFill(ColorScheme scheme) => scheme.surface;

  /// Рамка выбранного сегмента.
  static Color selectedBorder(ColorScheme scheme) =>
      scheme.outline.withValues(alpha: 0.22);

  /// Текст сегмента.
  static TextStyle segmentTextStyle(
    ThemeData theme, {
    required bool selected,
  }) {
    final scheme = theme.colorScheme;
    final base = theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!;
    return base.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: segmentFontSize,
      height: segmentLineHeight,
      color: selected
          ? scheme.onSurface
          : scheme.onSurface.withValues(alpha: 0.52),
    );
  }

  /// Декорация внешнего трека сегментов.
  static BoxDecoration trackDecoration(ColorScheme scheme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: trackBorder(scheme)),
      color: trackFill(scheme),
    );
  }
}

/// Один сегмент внутри [PayrollToolbarSegmentTrack].
class PayrollToolbarSegmentChip extends StatelessWidget {
  /// Создаёт сегмент панели.
  const PayrollToolbarSegmentChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Подпись сегмента.
  final String label;

  /// Выбран ли сегмент.
  final bool selected;

  /// Обработчик нажатия.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(PayrollToolbarMetrics.segmentRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: PayrollToolbarMetrics.segmentHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: PayrollToolbarMetrics.segmentHorizontalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              PayrollToolbarMetrics.segmentRadius,
            ),
            color: selected
                ? PayrollToolbarMetrics.selectedFill(scheme)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? PayrollToolbarMetrics.selectedBorder(scheme)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: PayrollToolbarMetrics.segmentTextStyle(
              theme,
              selected: selected,
            ),
          ),
        ),
      ),
    );
  }
}

/// Общая оболочка сегментированного контрола панели ФОТ.
class PayrollToolbarSegmentTrack extends StatelessWidget {
  /// Создаёт трек сегментов.
  const PayrollToolbarSegmentTrack({
    super.key,
    required this.semanticsLabel,
    required this.children,
  });

  /// Подпись для доступности.
  final String semanticsLabel;

  /// Сегменты внутри трека.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: PayrollToolbarMetrics.height,
        child: DecoratedBox(
          decoration: PayrollToolbarMetrics.trackDecoration(scheme),
          child: Padding(
            padding: const EdgeInsets.all(PayrollToolbarMetrics.trackPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Компактная текстовая кнопка высотой панели ФОТ.
class PayrollToolbarTextButton extends StatelessWidget {
  /// Создаёт кнопку действия панели.
  const PayrollToolbarTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  /// Подпись кнопки.
  final String text;

  /// Обработчик нажатия.
  final VoidCallback? onPressed;

  /// Иконка слева от текста.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = PayrollToolbarMetrics.segmentTextStyle(
      theme,
      selected: true,
    );

    return SizedBox(
      height: PayrollToolbarMetrics.height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PayrollToolbarMetrics.radius),
            side: BorderSide(color: PayrollToolbarMetrics.trackBorder(scheme)),
          ),
          backgroundColor: PayrollToolbarMetrics.trackFill(scheme),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(text, style: textStyle.copyWith(color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}

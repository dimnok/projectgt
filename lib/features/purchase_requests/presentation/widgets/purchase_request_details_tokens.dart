import 'package:flutter/material.dart';

/// Единые отступы, радиусы и оформление карточки заявки.
abstract final class PurchaseRequestDetailsTokens {
  /// Горизонтальный отступ контента.
  static const double pagePadding = 20;

  /// Отступ между секциями.
  static const double sectionGap = 20;

  /// Отступ между заголовком секции и содержимым.
  static const double sectionTitleGap = 10;

  /// Радиус карточек и блоков.
  static const double cardRadius = 12;

  /// Зазор между KPI-карточками.
  static const double kpiGap = 10;

  /// Минимальная ширина для горизонтального ряда KPI.
  static const double kpiRowBreakpoint = 520;

  /// Фон страницы панели.
  static Color pageBackground(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : const Color(0xFFF8FAFC);
  }

  /// Фон карточек и шапки/подвала.
  static Color cardBackground(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFFFFFFF);
  }

  /// Фон заголовка таблицы и зебры.
  static Color tableHeaderBackground(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHigh
        : const Color(0xFFF8FAFC);
  }

  /// Фон чётных строк таблицы.
  static Color tableZebraBackground(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : const Color(0xFFFAFBFC);
  }

  /// Цвет разделителей и обводок.
  static Color borderColor(ThemeData theme) {
    return theme.colorScheme.outline.withValues(alpha: 0.1);
  }

  /// Приглушённый текст.
  static Color mutedText(ThemeData theme) {
    return theme.colorScheme.onSurface.withValues(alpha: 0.5);
  }

  /// Тень карточки (только светлая тема).
  static List<BoxShadow> cardShadow(ThemeData theme) {
    if (theme.brightness == Brightness.dark) return const [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Оформление карточки с содержимым.
  static BoxDecoration cardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: cardBackground(theme),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: borderColor(theme)),
      boxShadow: cardShadow(theme),
    );
  }

  /// Оформление шапки панели.
  static BoxDecoration headerDecoration(ThemeData theme) {
    return BoxDecoration(
      color: cardBackground(theme),
      border: Border(bottom: BorderSide(color: borderColor(theme))),
    );
  }

  /// Оформление подвала с действиями.
  static BoxDecoration footerDecoration(ThemeData theme) {
    return BoxDecoration(
      color: cardBackground(theme),
      border: Border(top: BorderSide(color: borderColor(theme))),
    );
  }
}

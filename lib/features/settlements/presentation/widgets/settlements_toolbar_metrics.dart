import 'package:flutter/material.dart';

/// Общая геометрия и стили панели фильтров взаиморасчётов (как у «Табель» / ФОТ).
abstract final class SettlementsToolbarMetrics {
  /// Высота элементов панели.
  static const double height = 34;

  /// Радиус капсул.
  static const double radius = 18;

  /// Размер шрифта контролов.
  static const double fontSize = 14;

  /// Размер иконок.
  static const double iconSize = 18;

  /// Максимальная высота прокручиваемого меню.
  static const double menuMaxHeight = 220;

  /// Ширина меню сущностей (контрагент, объект, договор).
  static const double entityMenuWidth = 220;

  /// Ширина меню дополнительных фильтров (тип, оплата).
  static const double extraMenuWidth = 248;

  /// Цвет рамки триггера.
  static Color trackBorder(ColorScheme scheme) =>
      scheme.outline.withValues(alpha: 0.38);

  /// Заливка триггера.
  static Color trackFill(ColorScheme scheme) =>
      scheme.surfaceContainerHighest.withValues(alpha: 0.45);

  /// Рамка активного триггера.
  static Color activeBorder(ColorScheme scheme) =>
      scheme.primary.withValues(alpha: 0.62);

  /// Заливка активного триггера.
  static Color activeFill(ColorScheme scheme) =>
      scheme.primary.withValues(alpha: 0.1);
}

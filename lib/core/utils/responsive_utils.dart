import 'package:flutter/material.dart';

/// Утилитарный класс для работы с адаптивным дизайном.
///
/// Содержит методы для определения типа устройства и константы
/// для различных пороговых значений, связанных с адаптивной версткой.
class ResponsiveUtils {
  /// Минимальная ширина для планшетов (в пикселях).
  static const double tabletBreakpoint = 600;

  /// Минимальная ширина для десктопов (в пикселях).
  static const double desktopBreakpoint = 900;

  /// Стандартный отступ для мобильных устройств.
  static const double paddingMobile = 16.0;

  /// Стандартный отступ для планшетов.
  static const double paddingTablet = 24.0;

  /// Стандартный отступ для десктопов.
  static const double paddingDesktop = 32.0;

  /// Малый радиус скругления (например, для кнопок).
  static const double borderRadiusSmall = 8.0;

  /// Средний радиус скругления (например, для карточек).
  static const double borderRadiusMedium = 12.0;

  /// Крупный радиус скругления (например, для модальных окон).
  static const double borderRadiusLarge = 16.0;

  /// Определяет, является ли устройство мобильным.
  ///
  /// [context] — контекст для получения размера экрана.
  /// Возвращает true, если ширина экрана меньше [tabletBreakpoint].
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Определяет, является ли устройство планшетом.
  ///
  /// [context] — контекст для получения размера экрана.
  /// Возвращает true, если ширина экрана от [tabletBreakpoint] до [desktopBreakpoint).
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Определяет, является ли устройство десктопом.
  ///
  /// [context] — контекст для получения размера экрана.
  /// Возвращает true, если ширина экрана больше либо равна [desktopBreakpoint].
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Возвращает значение в зависимости от типа устройства.
  ///
  /// [context] — контекст для получения размера экрана.
  /// [mobile] — значение для мобильных устройств.
  /// [tablet] — значение для планшетов (опционально, по умолчанию равно desktop).
  /// [desktop] — значение для десктопов.
  ///
  /// Пример:
  /// ```dart
  /// final padding = ResponsiveUtils.adaptiveValue(
  ///   context: context,
  ///   mobile: 8.0,
  ///   desktop: 24.0,
  /// );
  /// ```
  static T adaptiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
  }

  /// Возвращает стандартный отступ в зависимости от размера экрана.
  ///
  /// [context] — контекст для получения размера экрана.
  /// Возвращает одно из значений: [paddingMobile], [paddingTablet], [paddingDesktop].
  static double getAdaptivePadding(BuildContext context) {
    return adaptiveValue(
      context: context,
      mobile: paddingMobile,
      tablet: paddingTablet,
      desktop: paddingDesktop,
    );
  }

  /// Возвращает адаптивный отступ в зависимости от размера экрана и положения.
  ///
  /// [context] — контекст для получения размера экрана.
  /// Возвращает [EdgeInsets.all] с адаптивным значением отступа.
  static EdgeInsets getAdaptiveInsets(BuildContext context) {
    final padding = getAdaptivePadding(context);
    return EdgeInsets.all(padding);
  }

  /// Возвращает адаптивное скругление в зависимости от размера экрана.
  ///
  /// [context] — контекст для получения размера экрана.
  /// Возвращает [BorderRadius.circular] с адаптивным радиусом.
  static BorderRadius getAdaptiveBorderRadius(BuildContext context) {
    final radius = adaptiveValue(
      context: context,
      mobile: borderRadiusMedium,
      desktop: borderRadiusLarge,
    );
    return BorderRadius.circular(radius);
  }
}

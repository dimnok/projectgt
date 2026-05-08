import 'package:flutter/material.dart';

import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';

/// Стили заливки, обводки и тени карточки в «атмосферных» мобильных списках.
///
/// Общий для модулей (сотрудники, смены и т.д.): градиент, рамка, верхняя
/// подсветка и тени совпадают с мобильной карточкой строки в списке сотрудников.
@immutable
class MobileAtmosphereCardStyle {
  /// Создаёт набор стилей карточки.
  const MobileAtmosphereCardStyle({
    required this.scheme,
    required this.cardTop,
    required this.cardBottom,
    required this.cardBorder,
    required this.cardHighlight,
    required this.cardShadows,
  });

  /// Стили из текущей [MobileAtmosphereAppearance] (тот же источник, что у фона).
  factory MobileAtmosphereCardStyle.fromAppearance(
    MobileAtmosphereAppearance appearance,
  ) {
    return MobileAtmosphereCardStyle(
      scheme: appearance.scheme,
      cardTop: appearance.cardTop,
      cardBottom: appearance.cardBottom,
      cardBorder: appearance.cardBorder,
      cardHighlight: appearance.cardHighlight,
      cardShadows: appearance.cardShadows,
    );
  }

  /// Цветовая схема темы (текст, иконки).
  final ColorScheme scheme;

  /// Верхний цвет градиента заливки карточки.
  final Color cardTop;

  /// Нижний цвет градиента заливки карточки.
  final Color cardBottom;

  /// Цвет рамки карточки.
  final Color cardBorder;

  /// Цвет верхней «подсветки» (1 px).
  final Color cardHighlight;

  /// Тени под карточкой.
  final List<BoxShadow> cardShadows;
}

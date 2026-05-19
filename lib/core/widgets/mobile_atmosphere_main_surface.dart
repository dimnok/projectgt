import 'package:flutter/material.dart';

import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';

/// Основная карточка контента в визуальном языке [MobileAtmosphereCardStyle].
///
/// Используется на экранах с [MobileAtmosphereBackdrop] (табель, ФОТ и др.).
class MobileAtmosphereMainSurface extends StatelessWidget {
  /// Создаёт обёртку контента с градиентом, обводкой и внутренним отступом.
  const MobileAtmosphereMainSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  /// Содержимое внутри карточки.
  final Widget child;

  /// Внутренний отступ; по умолчанию 16, как у табеля.
  final EdgeInsetsGeometry padding;

  static const double _outerRadius = 16;
  static const double _clipRadius = 15;

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final cardStyle = MobileAtmosphereCardStyle.fromAppearance(appearance);
    final hi = cardStyle.cardHighlight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardStyle.cardTop, cardStyle.cardBottom],
        ),
        boxShadow: cardStyle.cardShadows,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
        border: Border.fromBorderSide(
          BorderSide(
            color: cardStyle.cardBorder,
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_clipRadius),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      hi.withValues(alpha: 0),
                      hi.withValues(alpha: 0.65),
                      hi.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

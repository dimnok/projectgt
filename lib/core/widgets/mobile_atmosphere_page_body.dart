import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';

/// Тело мобильного экрана с атмосферным фоном на весь экран, включая зону status bar.
///
/// Контент [child] должен сам отступать сверху через [WebSafeArea.topOf] или
/// [MobileAtmosphereScreenHeader] — без обёртки [SafeArea] с `top: true`.
class MobileAtmospherePageBody extends StatelessWidget {
  /// Создаёт подложку с [MobileAtmosphereBackdrop] и [child] поверх.
  const MobileAtmospherePageBody({
    super.key,
    required this.child,
  });

  /// Контент экрана (список, колонка и т.д.).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const MobileAtmosphereBackdrop(),
        child,
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Общая визуальная тема «атмосферы» мобильных экранов (списки, сложные шапки):
/// базовый фон, цвета радиальных подложек, хрома (кнопок/полей), карточек и теней.
///
/// Независима от бизнес-домена — подходит для любого модуля. Специализированные
/// классы (например, `EmployeesMobileAppearance`) могут использовать её как основу
/// и добавлять доменные методы.
@immutable
class MobileAtmosphereAppearance {
  const MobileAtmosphereAppearance._({
    required this.isDark,
    required this.scheme,
  });

  /// Создаёт оформление для текущего [BuildContext].
  factory MobileAtmosphereAppearance.of(BuildContext context) {
    final theme = Theme.of(context);
    return MobileAtmosphereAppearance._(
      isDark: theme.colorScheme.brightness == Brightness.dark,
      scheme: theme.colorScheme,
    );
  }

  /// Тёмная тема активна.
  final bool isDark;

  /// Цветовая схема темы приложения.
  final ColorScheme scheme;

  /// Фон статус-бара / низа и нижний слой атмосферы.
  Color get atmosphereBase {
    if (isDark) return const Color(0xFF0E0E10);
    return scheme.surface;
  }

  /// Цвета центрального радиального «света» фона.
  List<Color> get radialSpotlightColors {
    if (isDark) {
      return const [
        Color(0xFF141416),
        Color(0xFF101012),
        Color(0xFF0B0B0D),
        Color(0xFF080809),
      ];
    }
    return [
      scheme.surface,
      scheme.surfaceContainerLowest,
      scheme.surfaceContainerLow,
      scheme.surfaceContainer,
    ];
  }

  /// Цвета виньетки по краям.
  List<Color> get vignetteRadialColors {
    if (isDark) {
      return [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.14),
        Colors.black.withValues(alpha: 0.3),
      ];
    }
    return [
      Colors.transparent,
      scheme.shadow.withValues(alpha: 0.02),
      scheme.shadow.withValues(alpha: 0.05),
    ];
  }

  /// Цвета вертикального «вомыва» (верх→низ).
  List<Color> get verticalWashColors {
    if (isDark) {
      return [
        Colors.black.withValues(alpha: 0.045),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.075),
      ];
    }
    return [
      scheme.shadow.withValues(alpha: 0.02),
      Colors.transparent,
      scheme.shadow.withValues(alpha: 0.04),
    ];
  }

  /// Заливка «хрома» (поиск, панели, круглые кнопки в шапке).
  Color get chromeFill => isDark
      ? const Color(0x14FFFFFF)
      : scheme.onSurface.withValues(alpha: 0.04);

  /// Обводка хрома.
  Color get chromeBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : scheme.outline.withValues(alpha: 0.15);

  /// Верхний цвет градиента карточки.
  Color get cardTop =>
      isDark ? const Color(0xFF000000) : scheme.surface;

  /// Нижний цвет градиента карточки.
  Color get cardBottom =>
      isDark ? const Color(0xFF000000) : scheme.surfaceContainerLowest;

  /// Цвет рамки карточки.
  Color get cardBorder =>
      isDark ? const Color(0x24FFFFFF) : scheme.outline.withValues(alpha: 0.12);

  /// Подсветка границы карточки.
  Color get cardHighlight => isDark
      ? const Color(0x2EFFFFFF)
      : scheme.onSurface.withValues(alpha: 0.14);

  /// Тени под карточкой.
  List<BoxShadow> get cardShadows {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.65),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.12),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: -6,
      ),
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.06),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

/// Многослойный фон для мобильных экранов: база, радиальные градиенты,
/// плёночное зерно. Используется как подложка (`Stack.fit = expand`) под контент
/// или как `sheetBackdrop` в `MobileBottomSheetContent`.
class MobileAtmosphereBackdrop extends StatelessWidget {
  /// Создаёт подложку по текущей теме.
  const MobileAtmosphereBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: appearance.atmosphereBase),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.04, -0.26),
              radius: 1.18,
              colors: appearance.radialSpotlightColors,
              stops: const [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: appearance.vignetteRadialColors,
              stops: const [0.32, 0.72, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: appearance.verticalWashColors,
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        const Positioned.fill(
          child: RepaintBoundary(child: _MobileFilmGrainTileOverlay()),
        ),
      ],
    );
  }
}

/// Плёночное зерно через тайлинг PNG ([ImageRepeat.repeat]).
class _MobileFilmGrainTileOverlay extends StatelessWidget {
  const _MobileFilmGrainTileOverlay();

  static const String _assetPath = 'assets/images/film_grain_tile.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    const grain = DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_assetPath),
          repeat: ImageRepeat.repeat,
          fit: BoxFit.none,
          filterQuality: FilterQuality.low,
          isAntiAlias: false,
        ),
      ),
    );

    return IgnorePointer(
      child: Opacity(
        opacity: isDark ? 0.14 : 0.05,
        child: isDark
            ? grain
            : const ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.overlay),
                child: grain,
              ),
      ),
    );
  }
}

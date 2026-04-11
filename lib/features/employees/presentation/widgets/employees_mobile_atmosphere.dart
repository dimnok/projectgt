import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/employee.dart';

/// Внешний вид мобильного списка сотрудников: светлая и тёмная тема на базе [ColorScheme].
///
/// Используется для карточек, хрома и многослойного фона [EmployeesMobileAtmosphereBackdrop].
@immutable
class EmployeesMobileAppearance {
  const EmployeesMobileAppearance._({
    required this.isDark,
    required this.scheme,
  });

  /// Параметры оформления для текущего [BuildContext].
  factory EmployeesMobileAppearance.of(BuildContext context) {
    final theme = Theme.of(context);
    return EmployeesMobileAppearance._(
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
    return scheme.surfaceContainerLowest;
  }

  List<Color> get _radialSpotlightColors {
    if (isDark) {
      return const [
        Color(0xFF141416),
        Color(0xFF101012),
        Color(0xFF0B0B0D),
        Color(0xFF080809),
      ];
    }
    return [
      Color.lerp(scheme.surfaceContainerHigh, scheme.surface, 0.25)!,
      scheme.surface,
      scheme.surfaceContainerLow,
      Color.lerp(scheme.surfaceContainerLow, scheme.shadow, 0.12)!,
    ];
  }

  List<Color> get _vignetteRadialColors {
    if (isDark) {
      return [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.14),
        Colors.black.withValues(alpha: 0.3),
      ];
    }
    return [
      Colors.transparent,
      scheme.shadow.withValues(alpha: 0.06),
      scheme.shadow.withValues(alpha: 0.14),
    ];
  }

  List<Color> get _verticalWashColors {
    if (isDark) {
      return [
        Colors.black.withValues(alpha: 0.045),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.075),
      ];
    }
    return [
      scheme.shadow.withValues(alpha: 0.04),
      Colors.transparent,
      scheme.shadow.withValues(alpha: 0.06),
    ];
  }

  /// Заливка «хрома» (поиск, панели).
  Color get chromeFill => isDark
      ? const Color(0x14FFFFFF)
      : scheme.onSurface.withValues(alpha: 0.06);

  /// Обводка хрома.
  Color get chromeBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : scheme.outline.withValues(alpha: 0.28);

  /// Верхний цвет градиента карточки.
  Color get cardTop =>
      isDark ? const Color(0xFF000000) : scheme.surfaceContainerHighest;

  /// Нижний цвет градиента карточки.
  Color get cardBottom =>
      isDark ? const Color(0xFF000000) : scheme.surfaceContainerHigh;

  /// Цвет рамки карточки.
  Color get cardBorder =>
      isDark ? const Color(0x24FFFFFF) : scheme.outline.withValues(alpha: 0.22);

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

  /// Подпись и цвет для статуса сотрудника в фильтрах/легенде.
  (String, Color) statusPresentation(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.working:
        return ('Работает', scheme.primary);
      case EmployeeStatus.vacation:
        return ('Отпуск', scheme.onSurfaceVariant);
      case EmployeeStatus.sickLeave:
        return (
          'Больничный',
          Color.lerp(scheme.primary, scheme.onSurfaceVariant, 0.4)!,
        );
      case EmployeeStatus.unpaidLeave:
        return ('Без содержания', scheme.onSurfaceVariant);
      case EmployeeStatus.fired:
        return (
          'Уволен',
          Color.lerp(scheme.onSurfaceVariant, scheme.outline, 0.35)!,
        );
    }
  }
}

/// Многослойный фон как на мобильном экране сотрудников: база, градиенты, плёночное зерно.
///
/// Передаётся в [MobileBottomSheetContent.sheetBackdrop] для листов редактирования.
class EmployeesMobileAtmosphereBackdrop extends StatelessWidget {
  /// Создаёт подложку по текущей теме.
  const EmployeesMobileAtmosphereBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = EmployeesMobileAppearance.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: appearance.atmosphereBase),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.04, -0.26),
              radius: 1.18,
              colors: appearance._radialSpotlightColors,
              stops: const [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: appearance._vignetteRadialColors,
              stops: const [0.32, 0.72, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: appearance._verticalWashColors,
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
        opacity: isDark ? 0.14 : 0.065,
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

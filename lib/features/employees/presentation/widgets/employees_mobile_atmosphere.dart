import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/domain/entities/employee.dart';

/// Внешний вид мобильного списка сотрудников: тонкая обёртка над общей
/// [MobileAtmosphereAppearance], добавляющая доменные методы модуля сотрудников
/// (подписи/цвета статусов).
///
/// Используется для карточек, хрома и многослойного фона [EmployeesMobileAtmosphereBackdrop].
@immutable
class EmployeesMobileAppearance {
  const EmployeesMobileAppearance._(this._base);

  /// Параметры оформления для текущего [BuildContext].
  factory EmployeesMobileAppearance.of(BuildContext context) {
    return EmployeesMobileAppearance._(MobileAtmosphereAppearance.of(context));
  }

  final MobileAtmosphereAppearance _base;

  /// Тёмная тема активна.
  bool get isDark => _base.isDark;

  /// Цветовая схема темы приложения.
  ColorScheme get scheme => _base.scheme;

  /// Фон статус-бара / низа и нижний слой атмосферы.
  Color get atmosphereBase => _base.atmosphereBase;

  /// Заливка «хрома» (поиск, панели).
  Color get chromeFill => _base.chromeFill;

  /// Обводка хрома.
  Color get chromeBorder => _base.chromeBorder;

  /// Верхний цвет градиента карточки.
  Color get cardTop => _base.cardTop;

  /// Нижний цвет градиента карточки.
  Color get cardBottom => _base.cardBottom;

  /// Цвет рамки карточки.
  Color get cardBorder => _base.cardBorder;

  /// Подсветка границы карточки.
  Color get cardHighlight => _base.cardHighlight;

  /// Тени под карточкой.
  List<BoxShadow> get cardShadows => _base.cardShadows;

  /// Стили карточки списка (градиент, рамка, подсветка, тень).
  MobileAtmosphereCardStyle get cardStyle =>
      MobileAtmosphereCardStyle.fromAppearance(_base);

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

/// Многослойный фон для мобильного модуля сотрудников.
///
/// Тонкая обёртка над общим [MobileAtmosphereBackdrop] — сохранена для
/// обратной совместимости с существующими вызовами в модуле сотрудников.
class EmployeesMobileAtmosphereBackdrop extends StatelessWidget {
  /// Создаёт подложку по текущей теме.
  const EmployeesMobileAtmosphereBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const MobileAtmosphereBackdrop();
}

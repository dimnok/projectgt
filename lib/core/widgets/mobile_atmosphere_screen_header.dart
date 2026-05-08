import 'package:flutter/material.dart';

import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';

/// Круглая кнопка в стиле «хрома» мобильной атмосферы (44×44).
///
/// Используется в шапках экранов рядом с заголовком: меню, назад, действия.
class MobileAtmosphereChromeCircleButton extends StatelessWidget {
  /// Создаёт круглую кнопку с иконкой в стиле атмосферы.
  const MobileAtmosphereChromeCircleButton({
    super.key,
    required this.appearance,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.iconSize = 22,
  });

  /// Параметры оформления атмосферы.
  final MobileAtmosphereAppearance appearance;

  /// Иконка внутри кнопки.
  final IconData icon;

  /// Обработчик нажатия.
  final VoidCallback onTap;

  /// Подсказка для [Tooltip]; если `null`, [Tooltip] не строится.
  final String? tooltip;

  /// Цвет иконки; по умолчанию [ColorScheme.onSurface].
  final Color? iconColor;

  /// Размер иконки (по умолчанию 22; для крупного «+» в списке работ — 26).
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = appearance.scheme;
    final effectiveIconColor = iconColor ?? scheme.onSurface;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: appearance.chromeFill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: appearance.chromeBorder),
          ),
          child: Icon(icon, size: iconSize, color: effectiveIconColor),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Строка заголовка мобильного экрана в стиле списка «Смены» модуля работ.
///
/// Слева — произвольный [leading] (обычно [MobileAtmosphereChromeCircleButton]),
/// по центру слева от края — [title], справа — опциональный [trailing].
class MobileAtmosphereScreenHeader extends StatelessWidget {
  /// Создаёт шапку с заголовком и слотами слева/справа.
  const MobileAtmosphereScreenHeader({
    super.key,
    required this.appearance,
    required this.title,
    required this.leading,
    this.trailing,
  });

  /// Параметры оформления атмосферы.
  final MobileAtmosphereAppearance appearance;

  /// Текст заголовка (одна строка, с многоточием при переполнении).
  final String title;

  /// Виджет слева (кнопка меню, назад и т.п.).
  final Widget leading;

  /// Необязательный виджет справа (например, действие «+» или удаление).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = appearance.scheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

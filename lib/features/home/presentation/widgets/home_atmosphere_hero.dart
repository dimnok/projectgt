import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/features/home/presentation/providers/daily_tip_provider.dart';

/// Минималистичный герой-блок, объединяющий приветствие и совет дня.
///
/// Дизайн сфокусирован на чистоте и отсутствии лишних элементов («винегрета»).
class HomeAtmosphereHero extends ConsumerWidget {
  /// Заголовок приветствия (например, "Добрый день, Дмитрий").
  final String title;

  /// Текущий час для определения атмосферы (иконки и цвета).
  final int hour;

  /// Виджет слева (например, кнопка меню).
  final Widget? leading;

  /// Виджет справа (например, переключатель темы).
  final Widget? trailing;

  /// Заголовок страницы (например, "Главная").
  final String? pageTitle;

  /// Флаг десктопного режима.
  final bool isDesktop;

  /// Прогресс сворачивания (0.0 - полностью развернут, 1.0 - свернут).
  /// Используется для анимации исчезновения элементов при скролле.
  final double scrollProgress;

  /// Создаёт герой-блок для главной страницы.
  const HomeAtmosphereHero({
    super.key,
    required this.title,
    required this.hour,
    this.leading,
    this.trailing,
    this.pageTitle,
    this.isDesktop = false,
    this.scrollProgress = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;
    final tipAsync = ref.watch(dailyTipProvider);

    final now = DateTime.now();
    final weekDay = _getWeekDay(now.weekday);
    final month = _getMonth(now.month);
    final dateString = '$weekDay, ${now.day} $month';

    final (iconData, baseColor) = _getAtmosphereData(hour);

    // Вычисляем прозрачность для элементов, которые должны исчезать
    final contentOpacity = (1.0 - (scrollProgress * 2.0)).clamp(0.0, 1.0);
    // Вычисляем прозрачность фона для "прилипшей" части
    final stickyBackgroundOpacity = scrollProgress.clamp(0.0, 1.0);

    // Фиксированные отступы и скругление: без расширения карточки и «разъезда»
    // кнопок при сворачивании (раньше горизонтальный margin уходил в 0).
    const horizontalMargin = 16.0;
    const topMargin = 12.0;
    const borderRadius = 24.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        horizontalMargin,
        topMargin,
        horizontalMargin,
        0,
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: isDesktop ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(
            alpha: (isDark ? 0.15 : 0.45) * contentOpacity +
                (isDark ? 0.85 : 0.98) * stickyBackgroundOpacity,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(
              alpha: ((isDark ? 0.12 : 0.08) * contentOpacity) +
                  (0.12 * stickyBackgroundOpacity),
            ),
            width: 1.0,
          ),
          boxShadow: stickyBackgroundOpacity > 0.1
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08 * stickyBackgroundOpacity),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Верхняя строка: Заголовок страницы и кнопки (всегда видны)
            if (pageTitle != null || leading != null || trailing != null) ...[
              // Высота совпадает с [MobileAtmosphereChromeCircleButton] (44),
              // иначе [titleLarge] может чуть вытолкнуть строку за доступную высоту.
              SizedBox(
                height: 44,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    if (pageTitle != null)
                      Expanded(
                        child: Text(
                          pageTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              ),
              if (contentOpacity > 0) SizedBox(height: 20 * contentOpacity),
            ],

            // Исчезающий контент (Приветствие, Дата, Совет)
            if (contentOpacity > 0)
              Expanded(
                child: Opacity(
                  opacity: contentOpacity,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Строка: Приветствие и Дата
                        Row(
                          children: [
                            Icon(
                              iconData,
                              size: isDesktop ? 18 : 16,
                              color: baseColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: title,
                                      style: (isDesktop
                                              ? theme.textTheme.titleMedium
                                              : theme.textTheme.titleSmall)
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' · $dateString',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Нижняя строка: Совет дня
                        tipAsync.when(
                          data: (tip) => _buildTipLine(context, theme, tip, isDesktop),
                          loading: () => const SizedBox(height: 20),
                          error: (err, stack) => _buildTipLine(
                            context,
                            theme,
                            const DailyTip(
                              title: 'Безопасность',
                              content:
                                  'Всегда проверяйте отсутствие напряжения перед началом работ.',
                              category: 'Общее',
                            ),
                            isDesktop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipLine(
    BuildContext context,
    ThemeData theme,
    DailyTip tip,
    bool isDesktop,
  ) {
    const tipColor = Color(0xFFFACC15); // Amber

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            CupertinoIcons.lightbulb,
            size: 12,
            color: tipColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Совет: ${tip.content}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  (IconData, Color) _getAtmosphereData(int hour) {
    if (hour >= 5 && hour < 12) {
      return (CupertinoIcons.sunrise_fill, const Color(0xFFFF9A8B));
    } else if (hour >= 12 && hour < 18) {
      return (CupertinoIcons.sun_max_fill, const Color(0xFF0D9488));
    } else if (hour >= 18 && hour < 23) {
      return (CupertinoIcons.sunset_fill, const Color(0xFFF97316));
    } else {
      return (CupertinoIcons.moon_stars_fill, const Color(0xFF1E3A8A));
    }
  }

  String _getWeekDay(int day) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return days[day - 1];
  }

  String _getMonth(int month) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return months[month - 1];
  }
}

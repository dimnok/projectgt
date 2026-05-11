import 'package:flutter/material.dart';
import 'package:projectgt/features/home/presentation/widgets/home_atmosphere_hero.dart';

/// Делегат для создания прилипающей шапки с анимацией исчезновения элементов.
class HomeSliverHeroDelegate extends SliverPersistentHeaderDelegate {
  /// Основной заголовок в hero-секции (передаётся в [HomeAtmosphereHero]).
  final String title;

  /// Час суток (0–23) для выбора фона/атмосферы в [HomeAtmosphereHero].
  final int hour;

  /// Виджет слева от заголовка (например, кнопка «назад»).
  final Widget? leading;

  /// Виджет справа в шапке (действия, меню).
  final Widget? trailing;

  /// Дополнительный подзаголовок страницы; если null, блок не показывается.
  final String? pageTitle;

  /// Если true — используются высоты и отступы для desktop-раскладки.
  final bool isDesktop;

  /// Создаёт делегат с данными для [HomeAtmosphereHero].
  ///
  /// [title] и [hour] обязательны; [leading], [trailing], [pageTitle] опциональны.
  /// [isDesktop] влияет на [maxExtent], [minExtent] и верстку hero.
  HomeSliverHeroDelegate({
    required this.title,
    required this.hour,
    this.leading,
    this.trailing,
    this.pageTitle,
    this.isDesktop = false,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Вычисляем прогресс сворачивания (0.0 - развернут, 1.0 - свернут)
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return SizedBox.expand(
      child: HomeAtmosphereHero(
        title: title,
        hour: hour,
        leading: leading,
        trailing: trailing,
        pageTitle: pageTitle,
        isDesktop: isDesktop,
        scrollProgress: progress,
      ),
    );
  }

  @override
  double get maxExtent => isDesktop ? 200 : 250; // Увеличиваем для десктопа тоже

  /// Высота в свернутом виде: строка с кнопками 44px + внешний отступ 12 +
  /// вертикальный padding контейнера (моб. 32, десктоп 40) — иначе [Column]
  /// в [HomeAtmosphereHero] не помещается и даёт overflow на доли пикселя.
  @override
  double get minExtent => isDesktop ? 96 : 92;

  @override
  bool shouldRebuild(covariant HomeSliverHeroDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.hour != hour ||
        oldDelegate.isDesktop != isDesktop ||
        oldDelegate.leading != leading ||
        oldDelegate.trailing != trailing ||
        oldDelegate.pageTitle != pageTitle;
  }
}

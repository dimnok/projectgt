import 'package:flutter/material.dart';
import 'package:projectgt/features/home/presentation/widgets/home_atmosphere_hero.dart';

/// Делегат для создания прилипающей шапки с анимацией исчезновения элементов.
class HomeSliverHeroDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final int hour;
  final Widget? leading;
  final Widget? trailing;
  final String? pageTitle;
  final bool isDesktop;

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

  @override
  double get minExtent => isDesktop ? 90 : 84; // Высота в свернутом виде

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

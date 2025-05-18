import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/theme/theme_provider.dart';

/// Кастомный AppBar для приложения с поддержкой смены темы и адаптивными действиями.
class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  /// Заголовок AppBar.
  final String title;
  /// Список виджетов для отображения в actions.
  final List<Widget>? actions;
  /// Кастомный leading-виджет (например, кнопка меню).
  final Widget? leading;
  /// Показывать ли переключатель темы.
  final bool showThemeSwitch;
  /// Центрировать ли заголовок.
  final bool centerTitle;
  
  /// Создаёт кастомный AppBar с заголовком, действиями и опциональным переключателем темы.
  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showThemeSwitch = true,
    this.centerTitle = false,
  });
  
  @override
  /// Строит AppBar с заголовком, actions и переключателем темы.
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading ?? Builder(
        builder: (context) => IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.green,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      actions: [
        ...?actions,
        if (showThemeSwitch)
          IconButton(
            icon: Icon(
              themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeNotifierProvider.notifier).toggleTheme();
            },
            tooltip: 'Сменить тему',
          ),
      ],
    );
  }
  
  @override
  /// Размер AppBar по умолчанию (kToolbarHeight).
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
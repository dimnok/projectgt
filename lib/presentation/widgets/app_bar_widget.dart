import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/theme/theme_provider.dart';

/// Кастомный плавающий AppBar для приложения с поддержкой смены темы и адаптивными действиями.
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

  /// Показывать ли поле поиска.
  final bool showSearchField;

  /// Контроллер для поля поиска.
  final TextEditingController? searchController;

  /// Callback для изменения поискового запроса.
  final ValueChanged<String>? onSearchChanged;

  /// Placeholder текст для поля поиска.
  final String? searchHint;

  /// Создаёт кастомный плавающий AppBar с заголовком, действиями и опциональным переключателем темы.
  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showThemeSwitch = true,
    this.centerTitle = true,
    this.showSearchField = false,
    this.searchController,
    this.onSearchChanged,
    this.searchHint,
  });

  @override

  /// Строит плавающий AppBar с заголовком, actions и переключателем темы.
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);

    return PreferredSize(
      preferredSize: preferredSize,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: themeState.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: themeState.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 2),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            bottom: showSearchField
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: _buildSearchField(theme),
                  )
                : const PreferredSize(
                    preferredSize: Size.zero,
                    child: SizedBox.shrink(),
                  ),
            title: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: centerTitle,
            leading: leading ??
                Builder(
                  builder: (context) => CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
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
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onPressed: () {
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит поле поиска для расширенного AppBar.
  Widget _buildSearchField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: searchHint ?? 'Поиск...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          suffixIcon: searchController?.text.isNotEmpty == true
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    searchController?.clear();
                    onSearchChanged?.call('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.green,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + 24 + (showSearchField ? 60 : 0),
      );
}

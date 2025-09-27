import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scaffold с поддержкой edge-to-edge режима.
///
/// Этот виджет обеспечивает отображение контента под статус баром
/// и navigation bar, создавая единое визуальное полотно.
class EdgeToEdgeScaffold extends StatelessWidget {
  /// Создает [EdgeToEdgeScaffold] с заданными параметрами.
  const EdgeToEdgeScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = true,
    this.resizeToAvoidBottomInset,
  });

  /// Виджет приложения (app bar).
  final PreferredSizeWidget? appBar;

  /// Основное содержимое scaffold.
  final Widget? body;

  /// Плавающая кнопка действия.
  final Widget? floatingActionButton;

  /// Расположение плавающей кнопки действия.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Боковое меню слева.
  final Widget? drawer;

  /// Боковое меню справа.
  final Widget? endDrawer;

  /// Нижняя панель навигации.
  final Widget? bottomNavigationBar;

  /// Цвет фона scaffold.
  final Color? backgroundColor;

  /// Расширяет body за пределы нижней панели.
  final bool extendBody;

  /// Расширяет body за пределы app bar.
  final bool extendBodyBehindAppBar;

  /// Изменяет размер для избежания нижней вставки.
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Определяем цвет фона на основе темы
    final bgColor = backgroundColor ?? theme.colorScheme.surface;

    // Устанавливаем SystemUiOverlayStyle на основе темы
    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: bgColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: bgColor,
        child: SafeArea(
          top: false, // Позволяем контенту заходить под статус бар
          bottom: extendBody ? false : true,
          child: Scaffold(
            backgroundColor: Colors.transparent, // Прозрачный фон для Scaffold
            extendBody: extendBody,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            appBar: appBar != null
                ? _EdgeToEdgeAppBar(
                    appBar: appBar!,
                    backgroundColor: bgColor,
                  )
                : null,
            body: body != null
                ? _EdgeToEdgeBody(
                    hasAppBar: appBar != null,
                    topPadding: mediaQuery.padding.top,
                    child: body!,
                  )
                : null,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            drawer: drawer,
            endDrawer: endDrawer,
            bottomNavigationBar: bottomNavigationBar,
          ),
        ),
      ),
    );
  }
}

/// Обертка для AppBar с поддержкой edge-to-edge.
class _EdgeToEdgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Создает [_EdgeToEdgeAppBar] с заданными параметрами.
  const _EdgeToEdgeAppBar({
    required this.appBar,
    required this.backgroundColor,
  });

  /// Оригинальный app bar.
  final PreferredSizeWidget appBar;

  /// Цвет фона app bar.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(top: statusBarHeight),
      child: appBar,
    );
  }

  @override
  Size get preferredSize {
    // Получаем высоту статус бара из текущего view
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final statusBarHeight = view.padding.top / view.devicePixelRatio;

    return Size.fromHeight(appBar.preferredSize.height + statusBarHeight);
  }
}

/// Обертка для body с поддержкой edge-to-edge.
class _EdgeToEdgeBody extends StatelessWidget {
  /// Создает [_EdgeToEdgeBody] с заданными параметрами.
  const _EdgeToEdgeBody({
    required this.child,
    required this.hasAppBar,
    required this.topPadding,
  });

  /// Дочерний виджет.
  final Widget child;

  /// Есть ли app bar в scaffold.
  final bool hasAppBar;

  /// Верхний отступ для статус-бара.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: hasAppBar ? EdgeInsets.zero : EdgeInsets.only(top: topPadding),
      child: child,
    );
  }
}

/// Утилита для создания edge-to-edge Scaffold с учетом текущей темы.
class EdgeToEdgeHelper {
  /// Создает Scaffold с автоматической настройкой edge-to-edge режима.
  static Widget scaffold({
    Key? key,
    PreferredSizeWidget? appBar,
    Widget? body,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    Widget? drawer,
    Widget? endDrawer,
    Widget? bottomNavigationBar,
    bool extendBody = false,
    bool? resizeToAvoidBottomInset,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return EdgeToEdgeScaffold(
          key: key,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar,
          backgroundColor: theme.colorScheme.surface,
          extendBody: extendBody,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        );
      },
    );
  }

  /// Создает виджет с отступом от статус бара.
  static Widget withStatusBarPadding({
    required Widget child,
    Color? backgroundColor,
  }) {
    return Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final theme = Theme.of(context);
        final bgColor = backgroundColor ?? theme.colorScheme.surface;

        return Container(
          color: bgColor,
          padding: EdgeInsets.only(top: mediaQuery.padding.top),
          child: child,
        );
      },
    );
  }
}

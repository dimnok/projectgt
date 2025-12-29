import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Класс для централизованного управления темами приложения (светлая и тёмная)
/// с использованием библиотеки flex_color_scheme.
class AppTheme {
  // Основные цвета для светлой темы (Black & White)
  static const FlexSchemeColor _lightScheme = FlexSchemeColor(
    primary: Colors.black,
    primaryContainer: Color(0xFF303030),
    secondary: Color(0xFF424242),
    secondaryContainer: Color(0xFFBDBDBD),
    tertiary: Color(0xFF616161),
    tertiaryContainer: Color(0xFFEEEEEE),
    appBarColor: Colors.white,
    error: Color(0xFFB00020),
  );

  // Основные цвета для тёмной темы (White & Black)
  static const FlexSchemeColor _darkScheme = FlexSchemeColor(
    primary: Colors.white,
    primaryContainer: Color(0xFFE0E0E0),
    secondary: Color(0xFFEEEEEE),
    secondaryContainer: Color(0xFF616161),
    tertiary: Color(0xFF9E9E9E),
    tertiaryContainer: Color(0xFF212121),
    appBarColor: Colors.black,
    error: Color(0xFFCF6679),
  );

  /// Возвращает светлую тему приложения в стиле Material 3.
  static ThemeData lightTheme({FlexScheme? scheme}) {
    return FlexThemeData.light(
      colors: scheme == null ? _lightScheme : null,
      scheme: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 8.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8.0,
        inputDecoratorUnfocusedBorderIsColored: false,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
      ),
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      fontFamily: 'Inter',
      // Настройка AppBar и статус бара
      appBarElevation: 0.5,
      appBarStyle: FlexAppBarStyle.scaffoldBackground,
    ).copyWith(
      // Дополнительные ручные переопределения для точного соответствия дизайну
      dialogTheme: const DialogThemeData(
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 0.5,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
    );
  }

  /// Возвращает тёмную тему приложения в стиле Material 3.
  static ThemeData darkTheme({FlexScheme? scheme}) {
    return FlexThemeData.dark(
      colors: scheme == null ? _darkScheme : null,
      scheme: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 8.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 8.0,
        inputDecoratorUnfocusedBorderIsColored: false,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
      ),
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      fontFamily: 'Inter',
      // Настройка AppBar и статус бара
      appBarElevation: 0.5,
      appBarStyle: FlexAppBarStyle.scaffoldBackground,
    ).copyWith(
      // Дополнительные ручные переопределения для точного соответствия дизайну
      dialogTheme: const DialogThemeData(
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.white,
            width: 0.5,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      // Специфичные цвета для темной темы
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    );
  }
}

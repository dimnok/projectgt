import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

/// Модель настроек внешнего вида приложения.
class ThemeSettings {
  /// Режим темы (светлая/тёмная/системная).
  final ThemeMode themeMode;

  /// Название шрифта (например, 'Inter', 'Roboto').
  final String fontFamily;

  /// Коэффициент масштабирования текста (1.0 = нормальный).
  final double textScale;

  /// Выбранная цветовая схема.
  /// Если null, используется стандартная монохромная тема (ProjectGT default).
  final FlexScheme? scheme;

  /// Создает настройки темы.
  ///
  /// [themeMode] - Режим темы (светлая/тёмная/системная).
  /// [fontFamily] - Название шрифта.
  /// [textScale] - Коэффициент масштабирования текста.
  /// [scheme] - Цветовая схема (null для монохромной).
  const ThemeSettings({
    required this.themeMode,
    required this.fontFamily,
    required this.textScale,
    this.scheme,
  });

  /// Создает настройки по умолчанию.
  factory ThemeSettings.defaultSettings() {
    return const ThemeSettings(
      themeMode: ThemeMode.system,
      fontFamily: 'Inter', // Стандартный шрифт приложения
      textScale: 1.0,
      scheme: null, // null = Монохром
    );
  }

  /// Создает копию настроек с измененными полями.
  ///
  /// Если передан [clearScheme] = true, то [scheme] будет сброшен в null,
  /// даже если передан аргумент [scheme].
  ThemeSettings copyWith({
    ThemeMode? themeMode,
    String? fontFamily,
    double? textScale,
    FlexScheme? scheme,
    bool clearScheme = false,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      textScale: textScale ?? this.textScale,
      scheme: clearScheme ? null : (scheme ?? this.scheme),
    );
  }
}

/// Провайдер для управления настройками темы.
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier();
});

/// StateNotifier для управления состоянием настроек темы.
///
/// Отвечает за загрузку, сохранение и обновление настроек в SharedPreferences.
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  static const _themeModeKey = 'theme_mode';
  static const _fontFamilyKey = 'font_family';
  static const _textScaleKey = 'text_scale';
  static const _schemeKey = 'color_scheme';

  /// Инициализирует notifier и загружает настройки.
  ThemeSettingsNotifier() : super(ThemeSettings.defaultSettings()) {
    _loadSettings();
  }

  /// Загружает сохраненные настройки.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_themeModeKey);
    final fontFamily = prefs.getString(_fontFamilyKey);
    final textScale = prefs.getDouble(_textScaleKey);
    final schemeIndex = prefs.getInt(_schemeKey);

    ThemeMode mode = ThemeMode.system;
    if (themeModeIndex != null) {
      mode = ThemeMode.values[themeModeIndex];
    }

    FlexScheme? scheme;
    if (schemeIndex != null &&
        schemeIndex >= 0 &&
        schemeIndex < FlexScheme.values.length) {
      scheme = FlexScheme.values[schemeIndex];
    }

    state = ThemeSettings(
      themeMode: mode,
      fontFamily: fontFamily ?? 'Inter',
      textScale: textScale ?? 1.0,
      scheme: scheme,
    );
  }

  /// Устанавливает режим темы.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  /// Устанавливает шрифт приложения.
  Future<void> setFontFamily(String fontFamily) async {
    state = state.copyWith(fontFamily: fontFamily);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, fontFamily);
  }

  /// Устанавливает масштаб текста.
  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
  }

  /// Устанавливает цветовую схему.
  /// Передайте null для сброса к стандартной (монохромной).
  Future<void> setScheme(FlexScheme? scheme) async {
    state = state.copyWith(scheme: scheme, clearScheme: scheme == null);
    final prefs = await SharedPreferences.getInstance();
    if (scheme == null) {
      await prefs.remove(_schemeKey);
    } else {
      await prefs.setInt(_schemeKey, scheme.index);
    }
  }
}

/// Утилита для получения текстовой темы Google Fonts по названию.
TextTheme getGoogleFontTextTheme(String fontFamily, TextTheme baseTextTheme) {
  switch (fontFamily) {
    case 'Roboto':
      return GoogleFonts.robotoTextTheme(baseTextTheme);
    case 'Open Sans':
      return GoogleFonts.openSansTextTheme(baseTextTheme);
    case 'Lato':
      return GoogleFonts.latoTextTheme(baseTextTheme);
    case 'Montserrat':
      return GoogleFonts.montserratTextTheme(baseTextTheme);
    case 'Oswald':
      return GoogleFonts.oswaldTextTheme(baseTextTheme);
    case 'Merriweather':
      return GoogleFonts.merriweatherTextTheme(baseTextTheme);
    case 'Inter':
    default:
      return GoogleFonts.interTextTheme(baseTextTheme);
  }
}

/// Список доступных шрифтов для выбора в настройках.
const List<String> kAvailableFonts = [
  'Inter',
  'Roboto',
  'Open Sans',
  'Lato',
  'Montserrat',
  'Oswald',
  'Merriweather',
];

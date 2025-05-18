import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Состояние темы приложения (светлая/тёмная/системная).
class ThemeState {
  /// Текущий режим темы.
  final ThemeMode themeMode;

  /// Создаёт состояние темы с указанным режимом.
  ThemeState({required this.themeMode});

  /// Возвращает копию состояния с новым режимом темы.
  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  /// Возвращает true, если активен тёмный режим.
  bool get isDarkMode => themeMode == ThemeMode.dark;
}

/// StateNotifier для управления состоянием темы приложения.
class ThemeNotifier extends StateNotifier<ThemeState> {
  /// Создаёт ThemeNotifier с системной темой по умолчанию.
  ThemeNotifier() : super(ThemeState(themeMode: ThemeMode.system));

  /// Переключает тему между светлой и тёмной.
  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  /// Устанавливает светлый режим темы.
  void setLightMode() {
    state = state.copyWith(themeMode: ThemeMode.light);
  }

  /// Устанавливает тёмный режим темы.
  void setDarkMode() {
    state = state.copyWith(themeMode: ThemeMode.dark);
  }
}

/// Провайдер состояния темы приложения для Riverpod.
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
}); 
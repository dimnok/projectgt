import 'dart:io';
import 'package:flutter/foundation.dart';

/// Конфигурация приложения ProjectGT.
///
/// Управляет настройками Supabase, режимами работы и другими параметрами приложения.
/// Использует хардкод значения для web и переменные окружения для нативных платформ.
///
/// АРХИТЕКТУРНОЕ РЕШЕНИЕ:
/// - Web: полностью хардкод значения, никаких внешних зависимостей
/// - Native: Platform.environment как единственный источник конфигурации
/// - Отсутствие flutter_dotenv для предотвращения ошибок при web-компиляции
class AppConfig {
  // Dart-define overrides (compile-time)

  /// Инициализация конфигурации
  static Future<void> initialize() async {
    // init

    // Для web никаких дополнительных действий не требуется
    // Для native используем только Platform.environment
    if (!kIsWeb) {
      // native env
    }
  }

  /// Безопасное получение переменной окружения только для нативных платформ
  static String? _getEnvValue(String key) {
    if (kIsWeb) {
      // Для web всегда возвращаем null - используем хардкод значения
      return null;
    } else {
      // Для нативных платформ используем только Platform.environment
      try {
        return Platform.environment[key];
      } catch (e) {
        return null;
      }
    }
  }

  /// URL Supabase проекта
  static String get supabaseUrl {
    if (kIsWeb) {
      // Хардкод для web - гарантированно рабочее значение
      return 'https://hzcawspbkvkrsmsklyuj.supabase.co';
    }

    // Для нативных платформ проверяем переменные окружения
    final envUrl = _getEnvValue('SUPABASE_URL');
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Fallback на рабочее значение
    return 'https://hzcawspbkvkrsmsklyuj.supabase.co';
  }

  /// Анонимный ключ Supabase
  static String get supabaseAnonKey {
    if (kIsWeb) {
      // Хардкод для web - гарантированно рабочее значение
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6Y2F3c3Bia3ZrcnNtc2tseXVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0NzkyODEsImV4cCI6MjA2MDA1NTI4MX0.VOeRvuFE9mVGXXEs8ylEeVyebB1DAqH-9r-73awQQ4k';
    }

    // Для нативных платформ проверяем переменные окружения
    final envKey = _getEnvValue('SUPABASE_ANON_KEY');
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // Fallback на рабочее значение
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6Y2F3c3Bia3ZrcnNtc2tseXVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0NzkyODEsImV4cCI6MjA2MDA1NTI4MX0.VOeRvuFE9mVGXXEs8ylEeVyebB1DAqH-9r-73awQQ4k';
  }

  /// Режим отладки
  static bool get debugMode {
    if (kIsWeb) {
      // Для web используем Flutter debug режим
      return kDebugMode;
    }

    // Для нативных платформ проверяем переменные окружения
    final envDebug = _getEnvValue('DEBUG_MODE');
    if (envDebug != null) {
      return envDebug.toLowerCase() == 'true';
    }

    // Fallback на Flutter debug режим
    return kDebugMode;
  }

  /// Использование заглушки данных
  static bool get useMockData {
    if (kIsWeb) {
      // Для web отключаем mock data
      return false;
    }

    // Для нативных платформ проверяем переменные окружения
    final envMock = _getEnvValue('USE_MOCK_DATA');
    if (envMock != null) {
      return envMock.toLowerCase() == 'true';
    }

    // По умолчанию отключено
    return false;
  }

  /// Окружение приложения
  static String get environment {
    if (kIsWeb) {
      // Для web устанавливаем production
      return 'production';
    }

    // Для нативных платформ проверяем переменные окружения
    final envEnv = _getEnvValue('ENV');
    if (envEnv != null && envEnv.isNotEmpty) {
      return envEnv;
    }

    // Fallback на development
    return 'development';
  }

  /// Название приложения
  static String get appName {
    return 'ProjectGT';
  }

  /// Версия приложения
  static String get appVersion {
    return '1.0.0';
  }

  // Telegram конфигурация удалена

  /// Печать текущей конфигурации для отладки
  static void printConfig() {
    // silent
  }
}

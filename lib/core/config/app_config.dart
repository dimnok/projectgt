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
    // 1. Сначала проверяем compile-time константы (--dart-define)
    String? value;
    if (key == 'SUPABASE_URL') {
      value = const String.fromEnvironment('SUPABASE_URL');
    } else if (key == 'SUPABASE_ANON_KEY') {
      value = const String.fromEnvironment('SUPABASE_ANON_KEY');
    } else if (key == 'ENV') {
      value = const String.fromEnvironment('ENV');
    } else if (key == 'DEBUG_MODE') {
      value = const String.fromEnvironment('DEBUG_MODE');
    } else if (key == 'USE_MOCK_DATA') {
      value = const String.fromEnvironment('USE_MOCK_DATA');
    }

    if (value != null && value.isNotEmpty) return value;

    if (kIsWeb) {
      // Для web всегда возвращаем null - используем хардкод значения
      return null;
    } else {
      // 2. Затем проверяем runtime переменные (только для native)
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
      // SELF-HOSTED: api.progt.ru
      return 'https://api.progt.ru';
    }

    // Для нативных платформ проверяем переменные окружения
    final envUrl = _getEnvValue('SUPABASE_URL');
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Fallback на Self-hosted сервер
    return 'https://api.progt.ru';
  }

  /// Анонимный ключ Supabase
  static String get supabaseAnonKey {
    if (kIsWeb) {
      // SELF-HOSTED: api.progt.ru
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzczODYwMDU3LCJleHAiOjIwODg5MTQ0NTB9.7y8Hpqmi2eB-IV2gVyjGk45Sz_R-IKevZ_W97C2rMOg';
    }

    // Для нативных платформ проверяем переменные окружения
    final envKey = _getEnvValue('SUPABASE_ANON_KEY');
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    // Fallback на Self-hosted ключ
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzczODYwMDU3LCJleHAiOjIwODg5MTQ0NTB9.7y8Hpqmi2eB-IV2gVyjGk45Sz_R-IKevZ_W97C2rMOg';
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
    return '1.0.22';
  }

  // Telegram конфигурация удалена

  /// Печать текущей конфигурации для отладки
  static void printConfig() {
    // silent
  }
}

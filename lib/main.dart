import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/common/app_router.dart';
import 'package:projectgt/presentation/theme/app_theme.dart';
import 'package:projectgt/presentation/theme/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Точка входа в приложение ProjectGT.
///
/// Выполняет инициализацию Supabase, загрузку переменных окружения и запуск приложения с поддержкой Riverpod.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Загрузка переменных окружения
  await dotenv.load();
  
  // Инициализация форматирования дат для русской локализации
  await initializeDateFormatting('ru', null);
  
  try {
    // Инициализация Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      debug: false, // Отключаем отладочные логи
    );
    
    // Уменьшаем логи
    // debugPrint('Supabase initialized successfully');
  } catch (e) {
    // В случае ошибки, выводим сообщение, но продолжаем запуск приложения
    // Это поможет в тестировании UI без настроенного Supabase
    debugPrint('Supabase initialization error: $e');
  }
  
  // Настройка системных каналов для плавности анимаций
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Корневой виджет приложения ProjectGT.
///
/// Настраивает темы, маршрутизацию и глобальные провайдеры состояния.
class MyApp extends ConsumerWidget {
  /// Создаёт экземпляр [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeNotifierProvider);
    
    return MaterialApp.router(
      title: 'ProjectGT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeState.themeMode,
      routerConfig: router,
      locale: const Locale('ru', 'RU'),
    );
  }
}

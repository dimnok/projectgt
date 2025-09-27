import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:projectgt/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/common/app_router.dart';
import 'package:projectgt/core/config/app_config.dart';
import 'package:projectgt/core/utils/web_status_bar.dart';
import 'package:projectgt/presentation/theme/app_theme.dart';
import 'package:projectgt/presentation/theme/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:projectgt/core/notifications/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:projectgt/data/services/fcm_token_service.dart';

/// Обработчик фоновых сообщений Firebase Cloud Messaging.
///
/// Вызывается когда приложение получает push-уведомление в фоновом режиме.
/// Инициализирует Firebase и обрабатывает входящее сообщение.
///
/// [message] - полученное push-сообщение.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Инициализируем Firebase в изоляте фонового обработчика перед использованием
  await Firebase.initializeApp();
}

/// Точка входа в приложение ProjectGT.
///
/// Выполняет инициализацию Supabase, конфигурации приложения и запуск приложения с поддержкой Riverpod.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase с опциями для текущей платформы
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Регистрация фонового обработчика сообщений FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Показ уведомлений в форграунде на iOS/macOS
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Инициализация конфигурации приложения (загрузка .env файла)
  await AppConfig.initialize();

  // Инициализация форматирования дат для русской локализации
  await initializeDateFormatting('ru', null);

  // Инициализация таймзон для локальных уведомлений
  tz.initializeTimeZones();

  // Печать конфигурации для отладки
  AppConfig.printConfig();

  // Инициализация Supabase только если не используется режим заглушки
  if (!AppConfig.useMockData) {
    try {
      // Инициализация Supabase
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: AppConfig.debugMode,
      );

      debugPrint('Supabase initialized successfully');
    } catch (e) {
      // В случае ошибки, выводим сообщение, но продолжаем запуск приложения
      debugPrint('Supabase initialization error: $e');
      debugPrint('Приложение будет работать в демо-режиме');
    }
  } else {
    debugPrint('Приложение запускается в демо-режиме (useMockData = true)');
    debugPrint(
        'Для подключения к Supabase обновите настройки в lib/core/config/app_config.dart');
  }

  // Настройка edge-to-edge режима для всех платформ
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Настройка системного UI для единого дизайна
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Инициализация веб статус бара для единого дизайна
  if (kIsWeb) {
    WebStatusBar.initialize();
  }

  runApp(
    const ProviderScope(
      observers: [],
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

  // FCM отключён: удалены инициализация и апсерты токена

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Инициализация локальных уведомлений и обработка тапа
    ref.read(notificationServiceProvider).initialize(onSelect: (payload) async {
      if (payload == null || payload.isEmpty) return;
      final router = ref.read(routerProvider);
      // Предполагаем, что есть роут на детали смены по id
      await router.push('/works/$payload');
    });

    // Инициализация сервиса FCM-токена (запрос прав, sync token, onTokenRefresh)
    ref.read(fcmTokenServiceProvider).initialize();

    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeNotifierProvider);
    final lightTheme = AppTheme.lightTheme();
    final darkTheme = AppTheme.darkTheme();

    // Синхронизируем статус бар с текущей темой на веб
    if (kIsWeb) {
      final currentTheme = themeState.themeMode == ThemeMode.dark
          ? darkTheme
          : themeState.themeMode == ThemeMode.light
              ? lightTheme
              : (MediaQuery.platformBrightnessOf(context) == Brightness.dark
                  ? darkTheme
                  : lightTheme);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        WebStatusBar.syncWithTheme(currentTheme);
      });
    }

    return MaterialApp.router(
      title: 'ProjectGT',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeState.themeMode,
      routerConfig: router,
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
    );
  }
}

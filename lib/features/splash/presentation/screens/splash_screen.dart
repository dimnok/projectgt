import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Для kIsWeb
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../controllers/splash_controller.dart';

/// Экран заставки (Splash Screen).
///
/// Отображает логотип приложения и состояние инициализации.
/// Используется для плавной загрузки ресурсов перед переходом на основной экран.
class SplashScreen extends ConsumerStatefulWidget {
  /// Создаёт экран заставки.
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startInit();
  }

  Future<void> _startInit() async {
    // Даем движку немного времени на стабилизацию
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // ВАЖНО: На Web ручной вызов remove() часто приводит к крашу движка
    if (!kIsWeb) {
      try {
        FlutterNativeSplash.remove();
      } catch (e) {
        debugPrint('Splash remove error: $e');
      }
    }

    // Запускаем процесс инициализации
    ref.read(splashControllerProvider.notifier).initApp((route) {
      if (mounted) {
        context.go(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusText = ref.watch(splashControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип
            Image.asset(
              'assets/images/logo.png',
              width: 120, // Подбери размер как на нативе
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  duration: 2.seconds,
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05), // Легкое "дыхание"
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 40),

            // Индикатор загрузки (минималистичный)
            CupertinoActivityIndicator(
              radius: 12,
              color: isDark ? Colors.white : Colors.black,
            ),

            const SizedBox(height: 16),

            // Текст статуса
            Text(
              statusText,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter', // Твой шрифт
              ),
            ).animate(target: 1).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

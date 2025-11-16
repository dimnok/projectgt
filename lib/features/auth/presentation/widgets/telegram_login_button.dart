import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/web/web_adapter.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Кнопка входа через Telegram Mini App.
///
/// Получает `initData` от TelegramWebApp JS API и вызывает аутентификацию.
/// Доступна только на веб-версии (проверяет `kIsWeb`).
class TelegramLoginButton extends ConsumerWidget {
  /// Создаёт [TelegramLoginButton].
  const TelegramLoginButton({super.key});

  /// Получает initData от Telegram WebApp или из URL query параметров.
  ///
  /// Telegram передаёт initData двумя способами:
  /// 1. Через window.Telegram?.WebApp?.initData (JS API)
  /// 2. Через URL query параметр ?tgWebAppData=... (при открытии Mini App)
  ///
  /// На мобильных устройствах Telegram SDK загружается асинхронно,
  /// поэтому делаем несколько попыток с задержкой.
  ///
  /// Возвращает null если:
  /// - Приложение не веб версия
  /// - Приложение не открыто из Telegram
  /// - initData не найдена ни в JS API, ни в URL
  Future<String?> _getTelegramInitData() async {
    if (!kIsWeb) {
      debugPrint('[TelegramLoginButton] Not a web app, skipping Telegram auth');
      return null;
    }

    try {
      // На мобильных устройствах нужно больше времени для инициализации
      // Пытаемся несколько раз с увеличивающимися задержками
      for (int attempt = 1; attempt <= 5; attempt++) {
        // 1️⃣ Сначала проверяем глобальную переменную (установлена в web/index.html)
        final globalInitData =
            await evaluateJavaScript('window.__flutterTelegramInitData');
        if (globalInitData != null && globalInitData.toString().isNotEmpty) {
          debugPrint(
              '[TelegramLoginButton] Got initData from global variable (attempt $attempt)');
          return globalInitData.toString();
        }

        // 2️⃣ Пытаемся получить initData от Telegram WebApp JS API
        final initData =
            await evaluateJavaScript('window.Telegram?.WebApp?.initData');
        if (initData != null && initData.toString().isNotEmpty) {
          debugPrint(
              '[TelegramLoginButton] Got initData from JS API (attempt $attempt)');
          return initData.toString();
        }

        // 3️⃣ Если не найдена в JS API - ищем в URL query параметрах
        final initDataFromUrl = await _extractInitDataFromUrl();
        if (initDataFromUrl != null && initDataFromUrl.isNotEmpty) {
          debugPrint(
              '[TelegramLoginButton] Got initData from URL query (attempt $attempt)');
          return initDataFromUrl;
        }

        // Если это не последняя попытка - ждём и пробуем снова
        // Увеличиваем задержку с каждой попыткой для мобильных устройств
        if (attempt < 5) {
          final delayMs = 300 + (attempt * 200); // 500ms, 700ms, 900ms, 1100ms
          debugPrint(
              '[TelegramLoginButton] initData not found on attempt $attempt, retrying in ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }

      debugPrint(
          '[TelegramLoginButton] initData not found after 5 attempts - not in Telegram');
      return null;
    } catch (e) {
      debugPrint('[TelegramLoginButton] Error getting initData: $e');
      return null;
    }
  }

  /// Извлекает initData из URL query параметра `tgWebAppData`.
  ///
  /// Telegram Mini App передаёт данные как query параметр при открытии:
  /// https://example.com?tgWebAppData=query_id%3D...&user%3D...
  Future<String?> _extractInitDataFromUrl() async {
    try {
      // Получаем текущий URL
      final url = await evaluateJavaScript('window.location.search');
      if (url == null || url.toString().isEmpty) {
        return null;
      }

      final searchParams = url.toString();
      // Ищем параметр tgWebAppData
      final regex = RegExp(r'[?&]tgWebAppData=([^&]*)');
      final match = regex.firstMatch(searchParams);

      if (match != null && match.group(1) != null) {
        // URL decode параметр
        String initData = Uri.decodeComponent(match.group(1)!);
        debugPrint(
            '[TelegramLoginButton] Extracted initData from URL: ${initData.substring(0, 50)}...');
        return initData;
      }

      return null;
    } catch (e) {
      debugPrint(
          '[TelegramLoginButton] Error extracting initData from URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () async {
              try {
                // Получаем initData от Telegram
                final initData = await _getTelegramInitData();

                if (!context.mounted) return;

                if (initData == null || initData.isEmpty) {
                  // Показываем snackbar если не в Telegram
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Приложение должно быть открыто из Telegram',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                // Вызываем аутентификацию через Telegram
                await ref
                    .read(authProvider.notifier)
                    .loginWithTelegram(initData);

                if (!context.mounted) return;

                // Успешный вход — переход на главный экран обрабатывает AuthGate
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Ошибка входа через Telegram: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
      icon: const Icon(Icons.send),
      label: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Вход через Telegram'),
    );
  }
}

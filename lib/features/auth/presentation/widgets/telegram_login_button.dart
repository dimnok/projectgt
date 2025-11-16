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

  /// Получает initData от Telegram WebApp.
  ///
  /// Возвращает null если:
  /// - Приложение не веб версия
  /// - Приложение не открыто из Telegram
  /// - Telegram WebApp API недоступен
  Future<String?> _getTelegramInitData() async {
    if (!kIsWeb) {
      debugPrint('[TelegramLoginButton] Not a web app, skipping Telegram auth');
      return null;
    }

    try {
      // Получаем initData от Telegram WebApp JS API
      final initData =
          await evaluateJavaScript('window.Telegram?.WebApp?.initData');

      if (initData == null || initData.toString().isEmpty) {
        debugPrint(
            '[TelegramLoginButton] initData is null or empty - not in Telegram');
        return null;
      }

      debugPrint('[TelegramLoginButton] Got initData: ${initData.toString()}');
      return initData.toString();
    } catch (e) {
      debugPrint(
          '[TelegramLoginButton] Error getting initData: $e');
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
                      backgroundColor:
                          Theme.of(context).colorScheme.error,
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
                    content: Text('Ошибка входа через Telegram: ${e.toString()}'),
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


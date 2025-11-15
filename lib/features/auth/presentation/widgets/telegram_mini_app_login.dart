import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Экран авторизации через Telegram Mini App.
class TelegramMiniAppLogin extends ConsumerStatefulWidget {
  /// Конструктор [TelegramMiniAppLogin].
  const TelegramMiniAppLogin({super.key});

  @override
  ConsumerState<TelegramMiniAppLogin> createState() =>
      _TelegramMiniAppLoginState();
}

/// Состояние для [TelegramMiniAppLogin].
class _TelegramMiniAppLoginState extends ConsumerState<TelegramMiniAppLogin> {
  @override
  void initState() {
    super.initState();
    _verifyTelegram();
  }

  /// Проверяет Telegram Mini App.
  Future<void> _verifyTelegram() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await ref.read(authProvider.notifier).verifyTelegramMiniApp();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.initial) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Авторизация...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (authState.status == AuthStatus.error) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка авторизации',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  authState.errorMessage ?? 'Неизвестная ошибка',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifyTelegram,
                  child: const Text('Попробовать снова'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Если статус authenticated/pendingApproval/disabled — роутер сам перенаправит
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

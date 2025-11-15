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
  final List<String> debugLogs = [];
  bool showDebug = true; // Показываем логи по умолчанию

  void _addLog(String message) {
    setState(() {
      debugLogs.add('[${DateTime.now().toIso8601String()}] $message');
      if (debugLogs.length > 50) {
        debugLogs.removeAt(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _addLog('🟢 Экран инициализирован');
    _verifyTelegram();
  }

  /// Проверяет Telegram Mini App.
  Future<void> _verifyTelegram() async {
    _addLog('⏳ Ожидание 500ms перед проверкой...');
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _addLog('🔄 Начинаем верификацию Telegram...');
    await ref.read(authProvider.notifier).verifyTelegramMiniApp();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Основной контент
    Widget mainContent;

    if (authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.initial) {
      mainContent = Center(
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
      );
    } else if (authState.status == AuthStatus.error) {
      mainContent = Center(
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
      );
    } else {
      mainContent = const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Debug панель
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(child: mainContent),
          // Debug логи внизу экрана
          if (showDebug)
            Container(
              color: Colors.black87,
              height: 150,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🔧 Debug Logs',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => showDebug = false),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: debugLogs
                          .map((log) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  log,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

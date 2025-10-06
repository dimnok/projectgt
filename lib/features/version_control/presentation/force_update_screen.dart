import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/version_control/providers/version_providers.dart';
import 'package:projectgt/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Экран принудительного обновления приложения.
///
/// Отображается когда текущая версия приложения не поддерживается.
/// Блокирует доступ к приложению до обновления.
class ForceUpdateScreen extends ConsumerWidget {
  /// Создаёт экземпляр [ForceUpdateScreen].
  const ForceUpdateScreen({super.key});

  /// Открывает магазин приложений для обновления (только для Web).
  Future<void> _reloadWeb() async {
    if (kIsWeb) {
      // Для web перезагружаем страницу
      final storeUrl = Uri.parse(Uri.base.toString());
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(
          storeUrl,
          mode: LaunchMode.platformDefault,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionInfoAsync = ref.watch(currentVersionInfoProvider);
    final theme = Theme.of(context);
    final platform = AppConstants.appPlatform;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 24.0 : 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Анимированная иконка
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.8, end: 1.0),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: isSmallScreen ? 120 : 160,
                          height: isSmallScreen ? 120 : 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.system_update_alt_rounded,
                            size: isSmallScreen ? 60 : 80,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // Заголовок
                  Text(
                    'Требуется обновление',
                    style: (isSmallScreen
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.headlineLarge)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Описание
                  versionInfoAsync.when(
                    data: (versionInfo) {
                      final message = versionInfo?.updateMessage ??
                          'Ваша версия приложения устарела. '
                              'Пожалуйста, обновите приложение до версии ${versionInfo?.minimumVersion ?? "последней"} или новее.';

                      return Column(
                        children: [
                          // Контейнер с сообщением
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isSmallScreen ? 400 : 600,
                            ),
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  message,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                // Информация о версиях
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildVersionBadge(
                                      context,
                                      'Текущая',
                                      AppConstants.appVersion,
                                      theme.colorScheme.error,
                                      isSmallScreen,
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildVersionBadge(
                                      context,
                                      'Требуется',
                                      versionInfo?.minimumVersion ?? '—',
                                      theme.colorScheme.primary,
                                      isSmallScreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Ваша версия приложения устарела. '
                        'Пожалуйста, обновите приложение до последней версии.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 48),

                  // Кнопка обновления (только для Web)
                  if (platform == 'web')
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? 280 : 320,
                      ),
                      height: isSmallScreen ? 50 : 56,
                      child: ElevatedButton(
                        onPressed: _reloadWeb,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: isSmallScreen ? 20 : 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Перезагрузить страницу',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Инструкция для iOS/Android (без кнопки)
                  if (platform != 'web') ...[
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? 400 : 500,
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            platform == 'ios'
                                ? Icons.apple_rounded
                                : Icons.android_rounded,
                            size: isSmallScreen ? 36 : 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Обновите приложение через ${platform == 'ios' ? 'App Store' : 'Google Play'}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // Информационное сообщение
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen ? 400 : 500,
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.error,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Доступ к приложению будет восстановлен после обновления',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Создаёт бейдж с версией.
  Widget _buildVersionBadge(
    BuildContext context,
    String label,
    String version,
    Color color,
    bool isSmallScreen,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isSmallScreen ? 11 : 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            version,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }
}

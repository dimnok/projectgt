import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/constants/app_constants.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';

/// Экран перевода пользователя на новую (веб) версию приложения.
///
/// Блокирует работу в Flutter, пока в профиле включён `prefer_web_app`.
class PreferWebAppScreen extends ConsumerStatefulWidget {
  /// Создаёт экран перевода на веб-приложение.
  const PreferWebAppScreen({super.key});

  @override
  ConsumerState<PreferWebAppScreen> createState() => _PreferWebAppScreenState();
}

class _PreferWebAppScreenState extends ConsumerState<PreferWebAppScreen> {
  bool _opening = false;
  bool _copied = false;

  Future<void> _openWebApp() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final uri = Uri.parse(AppConstants.webAppUrl);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        await _copyLink();
      }
    } catch (_) {
      if (mounted) {
        await _copyLink();
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(const ClipboardData(text: AppConstants.webAppUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 28 : 40,
                vertical: 24,
              ),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: isPhone ? 88 : 104,
                    height: isPhone ? 88 : 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: onSurface,
                    ),
                    child: Icon(
                      Icons.north_east_rounded,
                      size: isPhone ? 36 : 42,
                      color: theme.colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: isPhone ? 28 : 36),
                  Text(
                    'Новая версия',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Работайте в обновлённой версии приложения. '
                    'Эта версия для вас закрыта.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      color: onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: onSurface.withValues(alpha: 0.08),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppConstants.webAppHostLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPhone
                              ? 'Откройте сайт и добавьте его на экран «Домой» — так удобнее работать с телефона.'
                              : 'Откройте сайт в браузере. На компьютере можно работать сразу, без установки.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: GTPrimaryButton(
                      text: 'Открыть новую версию',
                      icon: Icons.arrow_outward_rounded,
                      isLoading: _opening,
                      onPressed: _openWebApp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: GTSecondaryButton(
                      text: _copied ? 'Ссылка скопирована' : 'Скопировать ссылку',
                      onPressed: _copyLink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GTTextButton(
                    text: 'Выйти',
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

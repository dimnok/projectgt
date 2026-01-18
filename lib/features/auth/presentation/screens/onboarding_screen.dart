import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/auth/presentation/widgets/onboarding/onboarding_desktop_view.dart';
import 'package:projectgt/features/auth/presentation/widgets/onboarding/onboarding_mobile_view.dart';
import 'package:projectgt/features/company/presentation/widgets/company_create_dialog.dart';
import 'package:projectgt/features/company/presentation/widgets/company_join_dialog.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран онбординга (выбора пути) после первой авторизации или при отсутствии активной компании.
///
/// Этот экран предоставляет пользователю два основных пути:
/// 1. Создание новой организации (становясь её владельцем).
/// 2. Вступление в существующую организацию по коду приглашения.
///
/// Экран является адаптивным и переключается между [OnboardingDesktopView] и [OnboardingMobileView]
/// в зависимости от ширины экрана.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Определяет, нужно ли отображать кнопку выхода из аккаунта.
  ///
  /// По умолчанию [true]. Устанавливается в [false], если экран используется
  /// как часть диалога добавления компании внутри приложения, а не как основной экран входа.
  final bool showLogout;

  /// Создает экземпляр [OnboardingScreen].
  ///
  /// Принимает необязательный параметр [showLogout] для управления видимостью кнопки логаута.
  const OnboardingScreen({super.key, this.showLogout = true});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final contentWidth = isDesktop ? 750.0 : double.infinity;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: !widget.showLogout
          ? const AppBarWidget(
              title: 'Добавить компанию',
              showThemeSwitch: true,
              leading: BackButton(),
            )
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Логотип
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 150,
                          height: 150,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Для начала работы необходимо создать новую организацию или вступить в существующую',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Выбор пути
                      if (isDesktop)
                        OnboardingDesktopView(
                          onCreateCompany: _showCreateCompanyDialog,
                          onJoinCompany: _showJoinCompanyDialog,
                          isLoading: _isLoading,
                        )
                      else
                        OnboardingMobileView(
                          onCreateCompany: _showCreateCompanyDialog,
                          onJoinCompany: _showJoinCompanyDialog,
                          isLoading: _isLoading,
                        ),

                      if (widget.showLogout) ...[
                        const SizedBox(height: 48),
                        Center(
                          child: GTTextButton(
                            text: 'Выйти из аккаунта',
                            onPressed: () =>
                                ref.read(authProvider.notifier).logout(),
                            color: theme.colorScheme.error,
                            icon: Icons.logout_rounded,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showCreateCompanyDialog() {
    CompanyCreateDialog.show(
      context,
      onSuccess: () =>
          ref.read(authProvider.notifier).checkAuthStatus(force: true),
    );
  }

  void _showJoinCompanyDialog() {
    CompanyJoinDialog.show(
      context,
      onSuccess: () =>
          ref.read(authProvider.notifier).checkAuthStatus(force: true),
    );
  }
}

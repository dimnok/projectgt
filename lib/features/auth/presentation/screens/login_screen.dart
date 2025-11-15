import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_validator/email_validator.dart';

import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/core/services/telegram_mini_app_service.dart';
import '../widgets/otp_input_bottom_sheet.dart';
import '../widgets/telegram_mini_app_login.dart';

/// Экран входа пользователя в систему.
class LoginScreen extends ConsumerStatefulWidget {
  /// Конструктор [LoginScreen].
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Состояние для экрана [LoginScreen].
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Валидация email.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите электронную почту';
    }
    if (!EmailValidator.validate(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  /// Отправка кода на email.
  Future<void> _handleRequestCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    FocusScope.of(context).unfocus();

    try {
      await ref.read(authProvider.notifier).requestEmailOtp(email);
      if (!mounted) return;

      await OtpInputBottomSheet.show(context, email);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки кода: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final contentWidth = isDesktop ? 450.0 : double.infinity;
    final isMobile = size.width < 600;
    final isTelegram = TelegramMiniAppService.isTelegramMiniApp();

    // Если это Telegram Mini App на мобильном — показываем другой экран
    if (isTelegram && isMobile) {
      return const TelegramMiniAppLogin();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: contentWidth,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDesktop)
                      // Для десктопной версии: объединяем логотип и форму в один контейнер
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .shadow
                                  .withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Логотип
                            Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Добро пожаловать',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            // Форма входа
                            _buildLoginForm(context),
                          ],
                        ),
                      )
                    else
                      // Для мобильной версии: логотип отдельно, форма отдельно
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Логотип и приветствие
                          Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              children: [
                                // Логотип
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 200,
                                  height: 200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Добро пожаловать',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // Форма входа
                          _buildLoginForm(context),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Построение формы входа.
  Widget _buildLoginForm(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            validator: _validateEmail,
            decoration: const InputDecoration(
              labelText: 'Электронная почта',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _handleRequestCode,
            child: const Text('Получить код на почту'),
          ),
        ],
      ),
    );
  }
}

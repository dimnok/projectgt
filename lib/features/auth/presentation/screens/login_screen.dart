import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import '../widgets/otp_input_bottom_sheet.dart';

/// Экран входа пользователя в систему через номер телефона.
class LoginScreen extends ConsumerStatefulWidget {
  /// Конструктор [LoginScreen].
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Состояние для экрана [LoginScreen].
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '+7 ');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Валидация номера телефона.
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty || value == '+7 ') {
      return 'Введите номер телефона';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) {
      return 'Введите корректный номер телефона';
    }
    return null;
  }

  /// Обработка запроса кода.
  Future<void> _handleRequestCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final input = _phoneController.text.trim();
    FocusScope.of(context).unfocus();

    try {
      // Убираем лишние символы для отправки (оставляем только цифры)
      final cleanPhone = input.replaceAll(RegExp(r'\D'), '');
      await ref.read(authProvider.notifier).requestPhoneOtp(cleanPhone);
      if (!mounted) return;
      await OtpInputBottomSheet.showPhone(context, input);
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
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Добро пожаловать',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            _buildLoginForm(context),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 200,
                                  height: 200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Добро пожаловать',
                                  style: Theme.of(context).textTheme.titleLarge
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
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Авторизация по номеру телефона',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _phoneController,
            validator: _validatePhone,
            inputFormatters: [GtFormatters.phoneFormatter()],
            decoration: const InputDecoration(
              labelText: 'Номер телефона',
              hintText: '+7 (XXX) XXX XXXX',
              prefixIcon: Icon(Icons.phone_android_rounded),
            ),
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
            onFieldSubmitted: (_) => _handleRequestCode(),
          ),
          const SizedBox(height: 24),
          GTPrimaryButton(
                text: 'Получить код в Telegram',
                onPressed: _handleRequestCode,
                isLoading: isLoading,
                icon: Icons.send_rounded,
              )
              .animate()
              .fade(duration: 300.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 16),
          Text(
            'Код подтверждения будет отправлен в чат Telegram.\nУбедитесь, что у вас установлен мессенджер.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

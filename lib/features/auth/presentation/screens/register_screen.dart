import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

/// Экран регистрации нового пользователя.
class RegisterScreen extends ConsumerStatefulWidget {
  /// Конструктор [RegisterScreen].
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

/// Состояние для экрана [RegisterScreen].
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Валидация имени пользователя.
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя';
    }
    return null;
  }

  /// Валидация email.
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите электронную почту';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  /// Валидация пароля.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }

  /// Валидация подтверждения пароля.
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }
    if (value != _passwordController.text) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  /// Обработка регистрации пользователя.
  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );
    } else {
      // Показываем уведомление о неверных данных формы
      SnackBarUtils.showError(
        context, 
        'Пожалуйста, проверьте правильность введенных данных',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;
    final contentWidth = isDesktop ? 450.0 : double.infinity;
    
    // Слушаем состояние аутентификации
    final authState = ref.watch(authProvider);
    final hasError = authState.status == AuthStatus.error;
    
    // Показываем уведомление при ошибке
    if (hasError && authState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackBarUtils.showError(
          context, 
          SnackBarUtils.getAuthErrorMessage(authState.errorMessage!),
        );
      });
    }
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Логотип
                            Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 200,
                                height: 200,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Регистрация',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            // Форма регистрации
                            _buildRegisterForm(),
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
                                Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 200,
                                    height: 200,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Регистрация',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          // Форма регистрации
                          _buildRegisterForm(),
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
  
  /// Построение формы регистрации.
  Widget _buildRegisterForm() {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            validator: _validateName,
            decoration: const InputDecoration(
              labelText: 'Имя',
              prefixIcon: Icon(Icons.person_outline),
            ),
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
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
          TextFormField(
            controller: _passwordController,
            validator: _validatePassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Пароль',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            validator: _validateConfirmPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Подтверждение пароля',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            enabled: !isLoading,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать аккаунт'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: isLoading 
                ? null 
                : () {
                    ref.read(authProvider.notifier).resetError();
                    context.goNamed('login');
                  },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
} 
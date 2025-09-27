import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

/// Форма для завершения заполнения профиля пользователя.
///
/// Позволяет ввести ФИО и номер телефона при первой авторизации.
/// После успешного заполнения перенаправляет пользователя на следующий экран.
class ProfileCompletionForm extends ConsumerStatefulWidget {
  /// Конструктор [ProfileCompletionForm].
  const ProfileCompletionForm({super.key});

  @override
  ConsumerState<ProfileCompletionForm> createState() =>
      _ProfileCompletionFormState();
}

/// Состояние для [ProfileCompletionForm].
class _ProfileCompletionFormState extends ConsumerState<ProfileCompletionForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Настраиваем анимации
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Запускаем анимацию
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Валидация ФИО.
  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Пожалуйста, введите ФИО';
    }
    if (value.trim().length < 2) {
      return 'ФИО должно содержать минимум 2 символа';
    }
    // Проверяем, что есть хотя бы одно имя и фамилия
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return 'Введите имя и фамилию';
    }
    return null;
  }

  /// Валидация номера телефона.
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите номер телефона';
    }

    // Убираем все нецифровые символы для проверки
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

    // Проверяем длину (для российского номера: 11 цифр)
    if (cleanPhone.length != 11) {
      return 'Номер телефона должен содержать 11 цифр';
    }

    // Проверяем, что начинается с 7 или 8
    if (!cleanPhone.startsWith('7') && !cleanPhone.startsWith('8')) {
      return 'Номер должен начинаться с 7 или 8';
    }

    return null;
  }

  /// Форматирует номер телефона в читаемый вид.
  String _formatPhoneNumber(String value) {
    // Убираем все нецифровые символы
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return '';

    // Форматируем по маске +7-(XXX)-XXX-XX-XX
    if (digits.startsWith('7') || digits.startsWith('8')) {
      final formatted = StringBuffer();
      formatted.write('+7-');

      if (digits.length > 1) {
        formatted.write('(');
        formatted.write(digits.substring(1, min(4, digits.length)));
        if (digits.length > 4) {
          formatted.write(')-');
          formatted.write(digits.substring(4, min(7, digits.length)));
          if (digits.length > 7) {
            formatted.write('-');
            formatted.write(digits.substring(7, min(9, digits.length)));
            if (digits.length > 9) {
              formatted.write('-');
              formatted.write(digits.substring(9, min(11, digits.length)));
            }
          }
        }
      }

      return formatted.toString();
    }

    return value;
  }

  /// Обрабатывает изменение текста в поле телефона.
  void _onPhoneChanged(String value) {
    final formatted = _formatPhoneNumber(value);
    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  /// Обрабатывает изменение текста в поле ФИО.
  void _onFullNameChanged(String value) {
    final capitalized = _capitalizeWords(value);
    if (capitalized != value) {
      _fullNameController.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
  }

  /// Капитализирует каждое слово в строке (делает первую букву заглавной).
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Завершает заполнение профиля.
  Future<void> _completeProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Капитализируем ФИО перед сохранением
      final fullName = _capitalizeWords(_fullNameController.text.trim());
      final phone = _phoneController.text.trim();

      // Вызываем use case для обновления профиля
      await ref.read(completeUserProfileUseCaseProvider).execute(
            fullName: fullName,
            phone: phone,
          );

      // Обновляем локальное состояние профиля
      final currentProfile = ref.read(currentUserProfileProvider).profile;
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          fullName: fullName,
          phone: phone,
          updatedAt: DateTime.now(),
        );

        await ref
            .read(currentUserProfileProvider.notifier)
            .updateCurrentUserProfile(updatedProfile);
      }

      if (mounted) {
        // Показываем успех
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Профиль успешно заполнен!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        // Небольшая задержка перед переходом
        await Future.delayed(const Duration(milliseconds: 500));

        // Переходим к следующему экрану
        if (!mounted) return;
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Text(
                  'Завершите настройку профиля',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Описание
                Text(
                  'Для продолжения работы необходимо заполнить основные данные. '
                  'Эта информация поможет нам лучше обслуживать вас.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Поле ФИО
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'ФИО *',
                    hintText: 'Иванов Иван Иванович',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: _validateFullName,
                  textCapitalization: TextCapitalization.words,
                  onChanged: _onFullNameChanged,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),

                // Поле телефона
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Номер телефона *',
                    hintText: '+7-(XXX)-XXX-XX-XX',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  onChanged: _onPhoneChanged,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\(\)\s]')),
                    LengthLimitingTextInputFormatter(18), // Ограничение длины
                  ],
                ),
                const SizedBox(height: 12),

                // Подсказка по телефону
                Text(
                  '* Номер телефона используется для связи и уведомлений',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _completeProfile,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Завершить настройку',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                // Дополнительное пространство для клавиатуры
                SizedBox(
                    height:
                        MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Вспомогательная функция для определения минимума.
int min(int a, int b) => a < b ? a : b;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'dart:async';
import 'package:flutter/services.dart';

/// Экран входа пользователя в систему через номер телефона.
class LoginScreen extends ConsumerStatefulWidget {
  /// Конструктор [LoginScreen].
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Состояние для экрана [LoginScreen].
class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // Состояние шага авторизации
  bool _isOtpStep = false;

  // Поля для ввода телефона
  final _phoneController = TextEditingController(text: '+7 ');
  final _formKey = GlobalKey<FormState>();

  /// Получает очищенный номер телефона (только цифры).
  String get _cleanPhone => _phoneController.text.replaceAll(RegExp(r'\D'), '');

  // Поля для ввода OTP
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;
  final ValueNotifier<int> _timeLeft = ValueNotifier(30);
  Timer? _timer;
  Timer? _errorHideTimer;
  bool _isVerifying = false;
  bool _isCodeValid = false;
  String? _errorMessage;
  String? _lastErrorText; // Сохраняем текст для плавного затухания
  bool _isCodeVisible = true; // Управляет плавным исчезновением цифр

  // Контроллер для анимации ошибки (Glow Pulse)
  late AnimationController _errorAnimController;
  late Animation<double> _errorAnimation;

  // Контроллер для анимации успеха (Elastic Expand Pulse)
  late AnimationController _successAnimController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    // Инициализация OTP полей
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();

    // Слушаем изменение фокуса для перерисовки ячеек
    _otpFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    // Инициализация анимации ошибки (Glow Pulse)
    _errorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 600,
      ), // Увеличено для более плавной пульсации
    );

    // Создаем кривую для свечения: линейное нарастание
    _errorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _errorAnimController, curve: Curves.easeOut),
    );

    // Инициализация анимации успеха (Elastic Expand Pulse)
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successAnimController, curve: Curves.elasticOut),
    );

    // Слушаем конец анимации ошибки
    _errorAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Если мы достигли пика, запускаем затухание (обратный ход)
        if (mounted) {
          _errorAnimController.reverse();
        }
      } else if (status == AnimationStatus.dismissed) {
        // Когда анимация полностью прошла туда-обратно и вернулась в 0,
        // очищаем поля
        if (mounted && _errorMessage != null) {
          _clearCode();
        }
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    _errorHideTimer?.cancel();
    _errorAnimController.dispose();
    _successAnimController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  /// Запускает таймер обратного отсчета.
  void _startTimer() {
    _timer?.cancel();
    _timeLeft.value = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.value > 0) {
        _timeLeft.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// Форматирует время в виде MM:SS.
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Получает полный код из всех полей.
  String get _fullCode => _otpController.text;

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

    FocusScope.of(context).unfocus();

    try {
      await ref.read(authProvider.notifier).requestPhoneOtp(_cleanPhone);

      if (!mounted) return;

      setState(() {
        _isOtpStep = true;
        _errorMessage = null;
        _isCodeValid = false;
      });
      _startTimer();
      // Фокусируемся на поле ввода после перехода
      Future.delayed(300.ms, () {
        if (mounted) _otpFocusNode.requestFocus();
      });
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

  /// Маппинг ошибок сервера на дружелюбные сообщения.
  String _mapErrorToFriendlyMessage(String? error) {
    if (error == null) return 'Код неверный';
    final errorStr = error.toLowerCase();
    if (errorStr.contains('invalid or expired code')) {
      return 'Неверный или просроченный код';
    }
    if (errorStr.contains('otp_expired')) {
      return 'Срок действия кода истек';
    }
    if (errorStr.contains('otp_incorrect')) {
      return 'Введен неверный код';
    }
    return error;
  }

  /// Проверка OTP кода.
  Future<void> _verifyCode() async {
    final code = _fullCode;
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _isCodeValid = false;
    });

    try {
      await ref.read(authProvider.notifier).verifyPhoneOtp(_cleanPhone, code);

      if (!mounted) return;

      final currentState = ref.read(authProvider);

      // Успехом считаем либо переход в финальный статус, либо появление пользователя в стейте
      if (currentState.status == AuthStatus.authenticated ||
          currentState.status == AuthStatus.pendingApproval ||
          currentState.status == AuthStatus.onboarding ||
          currentState.user != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isCodeValid = true;
          _isVerifying = false;
        });
        _successAnimController.forward(from: 0.0);
      } else {
        await _handleVerifyError(currentState.errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      await _handleVerifyError(e.toString());
    }
  }

  Future<void> _handleVerifyError(String? error) async {
    HapticFeedback.heavyImpact();
    if (mounted) {
      final message = _mapErrorToFriendlyMessage(error);
      setState(() {
        _errorMessage = message;
        _lastErrorText = message; // Запоминаем текст
        _isVerifying = false;
        _isCodeValid = false;
        _isCodeVisible = true; // Возвращаем видимость полей для новой попытки
      });

      // Сбрасываем контроллер перед запуском, чтобы заново сыграть анимацию
      _errorAnimController.reset();
      _errorAnimController.forward();
    }
  }

  void _clearCode() {
    setState(() {
      // 1. Запускаем плавное исчезновение цифр и текста
      _isCodeVisible = false;
      _errorMessage = null;
    });

    // 2. Очищаем физически только после того, как всё растворилось (400мс)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _otpController.clear();
          _isCodeVisible = true; // Возвращаем видимость для нового ввода
        });

        // 3. Возвращаем фокус на поле ввода
        _otpFocusNode.requestFocus();
      }
    });

    _errorHideTimer?.cancel();
  }

  Future<void> _resendCode() async {
    try {
      await ref.read(authProvider.notifier).requestPhoneOtp(_cleanPhone);
      _startTimer();
      setState(() {
        _errorMessage = null;
        _isCodeValid = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка отправки кода';
      });
    }
  }

  void _onOtpChanged(String value) {
    if (_isVerifying) return;

    // Очистка сообщения об ошибке при начале нового ввода
    if (value.isNotEmpty && (_errorMessage != null || _isCodeValid)) {
      setState(() {
        _errorMessage = null;
        _isCodeValid = false;
      });
    }

    if (value.length == 6) {
      _otpFocusNode.unfocus();
      _verifyCode();
    }

    setState(() {}); // Обновляем визуальные ячейки
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
                child: isDesktop
                    ? _buildDesktopLayout(context)
                    : _buildMobileLayout(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogoAndHeader(context),
          const SizedBox(height: 32),
          _buildAnimatedContent(context),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 32),
          child: _buildLogoAndHeader(context),
        ),
        _buildAnimatedContent(context),
      ],
    );
  }

  Widget _buildLogoAndHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.asset('assets/images/logo.png', width: 200, height: 200),
        const SizedBox(height: 16),
        Text(
          'Добро пожаловать',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnimatedContent(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 320),
      child: AnimatedSwitcher(
        duration: 500.ms,
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isOtpStep ? _buildOtpForm(context) : _buildPhoneForm(context),
      ),
    );
  }

  /// Построение формы ввода телефона.
  Widget _buildPhoneForm(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('phone_form'),
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
          GTTextField(
            controller: _phoneController,
            validator: _validatePhone,
            inputFormatters: [GtFormatters.phoneFormatter()],
            labelText: 'Номер телефона',
            hintText: '+7 (XXX) XXX XXXX',
            prefixIcon: CupertinoIcons.device_phone_portrait,
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
            onSubmitted: (_) => _handleRequestCode(),
          ),
          const SizedBox(height: 24),
          GTPrimaryButton(
            text: 'Получить код в Telegram',
            onPressed: _handleRequestCode,
            isLoading: isLoading,
            icon: CupertinoIcons.paperplane,
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

  /// Построение формы ввода OTP.
  Widget _buildOtpForm(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      key: const ValueKey('otp_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.chevron_left),
              onPressed: () {
                setState(() {
                  _isOtpStep = false;
                });
              },
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.5),
            Expanded(
              child: Text(
                'Введите код',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms).moveY(begin: -10),
            ),
            const SizedBox(width: 48), // Для баланса с иконкой назад
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Код отправлен на ${_phoneController.text}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 24),
        // Группа полей ввода с анимацией ошибки или успеха
        AnimatedBuilder(
          animation: Listenable.merge([_errorAnimation, _successAnimation]),
          builder: (context, child) {
            final errorVal = _errorAnimation.value;
            final successVal = _successAnimation.value;

            double scale = 1.0;
            List<BoxShadow> boxShadow = [];

            if (_isCodeValid) {
              // Эффект успеха (Elastic Expand Pulse)
              scale = 1.0 + (successVal * 0.05);
              const successColor = Colors.green;
              // Свечение максимально в середине/конце упругой анимации
              final glowOpacity = (successVal * 0.5).clamp(0.0, 0.5);

              if (glowOpacity > 0.01) {
                boxShadow = [
                  BoxShadow(
                    color: successColor.withValues(alpha: glowOpacity),
                    blurRadius: 15 + (successVal * 10),
                    spreadRadius: 1 + (successVal * 4),
                  ),
                ];
              }
            } else if (_errorMessage != null) {
              // Эффект ошибки (Glow Pulse + Squeeze)
              scale = 1.0 - (errorVal * 0.02);
              final errorColor = theme.colorScheme.error;
              final glowOpacity = errorVal * 0.6;

              if (glowOpacity > 0.01) {
                boxShadow = [
                  BoxShadow(
                    color: errorColor.withValues(alpha: glowOpacity),
                    blurRadius: 20 + (errorVal * 10),
                    spreadRadius: 2 + (errorVal * 5),
                  ),
                ];
              }
            }

            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: boxShadow,
                ),
                child: child,
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Скрытое поле ввода (Capture focus & input)
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 300,
                  height: 48,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    onChanged: _onOtpChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    enableInteractiveSelection: false,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              // Визуальные ячейки
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_otpFocusNode.hasFocus) {
                    _otpFocusNode.requestFocus();
                  }
                },
                child: Row(
                  key: const ValueKey('otp_row_base'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (index) => _buildCodeInput(index)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Контейнер для ошибки фиксированной высоты, чтобы избежать прыжков UI
        SizedBox(
          height: 20,
          child: AnimatedOpacity(
            opacity: _errorMessage != null ? 1.0 : 0.0,
            duration: 400.ms, // Увеличено для синхронизации
            curve: Curves.easeIn,
            child: Text(
              _errorMessage ?? _lastErrorText ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<int>(
          valueListenable: _timeLeft,
          builder: (context, timeLeft, _) {
            if (timeLeft > 0) {
              return Column(
                children: [
                  Text(
                    'Повторная отправка через ${_formatTime(timeLeft)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isVerifying) ...[
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              );
            } else {
              return GTPrimaryButton(
                onPressed: _resendCode,
                text: 'Отправить код повторно',
                icon: CupertinoIcons.refresh,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildCodeInput(int index) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final bool hasError = _errorMessage != null;
    final bool isFilled = _otpController.text.length > index;
    // Фокус показываем на текущей пустой ячейке или на последней если все заполнены
    final bool hasFocus =
        _otpFocusNode.hasFocus &&
        (_otpController.text.length == index ||
            (_otpController.text.length == 6 && index == 5));

    final String char = isFilled ? _otpController.text[index] : '';

    Color borderColor;
    double borderWidth = 1.5;

    if (_isCodeValid) {
      borderColor = Colors.green;
      borderWidth = 2.0;
    } else if (hasError) {
      borderColor = theme.colorScheme.error;
    } else if (hasFocus) {
      borderColor = theme.colorScheme.primary;
    } else if (isFilled) {
      borderColor = onSurface.withValues(alpha: 0.6);
    } else {
      borderColor = onSurface.withValues(alpha: 0.2);
    }

    return Container(
      key: ValueKey('otp_box_$index'),
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: _isCodeVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
          child: Text(
            char,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

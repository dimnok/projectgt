import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:projectgt/presentation/state/auth_state.dart';

/// Модальное окно для ввода OTP кода.
class OtpInputBottomSheet extends ConsumerStatefulWidget {
  /// Email адрес для отправки кода.
  final String email;

  /// Конструктор [OtpInputBottomSheet].
  const OtpInputBottomSheet({
    required this.email,
    super.key,
  });

  @override
  ConsumerState<OtpInputBottomSheet> createState() =>
      _OtpInputBottomSheetState();

  /// Показывает модальное окно для ввода OTP.
  static Future<void> show(BuildContext context, String email) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => OtpInputBottomSheet(email: email),
    );
  }
}

class _OtpInputBottomSheetState extends ConsumerState<OtpInputBottomSheet> {
  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _focusNodes;
  late final ValueNotifier<int> _timeLeft;
  Timer? _timer;
  Timer? _errorHideTimer;
  bool _isVerifying = false;
  bool _isCodeValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Инициализируем контроллеры и фокусы для 6 полей
    _codeControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    // Добавляем слушатели фокуса для перерисовки
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (mounted) setState(() {});
      });
    }

    // Инициализируем таймер (30 секунд)
    _timeLeft = ValueNotifier(30);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorHideTimer?.cancel();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timeLeft.dispose();
    super.dispose();
  }

  /// Запускает таймер обратного отсчета.
  void _startTimer() {
    _timer?.cancel();
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
  String get _fullCode =>
      _codeControllers.map((controller) => controller.text).join();

  /// Проверяет код OTP.
  Future<void> _verifyCode() async {
    final code = _fullCode;
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _isCodeValid = false;
    });

    try {
      await ref.read(authProvider.notifier).verifyEmailOtp(widget.email, code);

      if (!mounted) return;

      // Используем небольшой delay для гарантированного обновления состояния
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Проверяем текущий статус после верификации
      final currentState = ref.read(authProvider);

      if (currentState.status == AuthStatus.authenticated ||
          currentState.status == AuthStatus.pendingApproval) {
        setState(() {
          _isCodeValid = true;
          _isVerifying = false;
        });
        // Не закрываем модальное окно сразу, даем пользователю увидеть зеленые границы
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = 'Код неверный';
          _isVerifying = false;
          _isCodeValid = false;
        });
        _clearCode();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Код неверный';
          _isVerifying = false;
          _isCodeValid = false;
        });
        _clearCode();
      }
    }
  }

  /// Очищает все поля ввода.
  void _clearCode() {
    for (final controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();

    // Сбрасываем состояние успешной верификации
    setState(() {
      _isCodeValid = false;
    });

    // Автоматически убираем сообщение об ошибке через 3 секунды
    // Отменяем предыдущий таймер ошибки, если он существует
    _errorHideTimer?.cancel();
    _errorHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  /// Повторно отправляет код.
  Future<void> _resendCode() async {
    try {
      await ref.read(authProvider.notifier).requestEmailOtp(widget.email);
      // Отменяем старый таймер перед запуском нового
      _timer?.cancel();
      _timeLeft.value = 30;
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

  /// Создаёт поле ввода для одной цифры.
  Widget _buildCodeInput(int index) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    // Определяем состояние поля
    final bool hasError = _errorMessage != null;
    final bool hasFocus = _focusNodes[index].hasFocus;
    final bool hasValue = _codeControllers[index].text.isNotEmpty;

    // Единый цвет и толщина границы для всех состояний
    Color borderColor;
    double borderWidth = 1.5;

    if (_isCodeValid) {
      // Зеленый цвет при успешной верификации
      borderColor = Colors.green;
      borderWidth = 2.0; // Более толстая граница для акцента
    } else if (hasError) {
      borderColor = theme.colorScheme.error;
    } else if (hasFocus) {
      borderColor = theme.colorScheme.primary;
    } else if (hasValue) {
      borderColor = onSurface.withValues(alpha: 0.6);
    } else {
      borderColor = onSurface.withValues(alpha: 0.2);
    }

    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        color: Colors.transparent,
      ),
      // СТРОГО ПО ЦЕНТРУ - тройное центрирование!!!
      child: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: Align(
            alignment: Alignment.center, // СТРОГО ПО ЦЕНТРУ
            child: TextField(
              controller: _codeControllers[index],
              focusNode: _focusNodes[index],
              readOnly: _isVerifying,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              mouseCursor: SystemMouseCursors.click, // Стандартный курсор
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              maxLength: 1,
              style: theme.textTheme.titleLarge?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.bold,
                height: 1.0, // Фиксированная высота
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hoverColor:
                    Colors.transparent, // УБИРАЕМ выделение при наведении
                fillColor: Colors.transparent, // УБИРАЕМ заливку
                contentPadding: EdgeInsets.zero, // НИКАКИХ отступов!
                isDense: true,
              ),
              onChanged: (value) => _handleInputChange(index, value),
              textInputAction:
                  index == 5 ? TextInputAction.done : TextInputAction.next,
            ),
          ),
        ),
      ),
    );
  }

  /// Обрабатывает изменение в поле ввода.
  void _handleInputChange(int index, String value) {
    if (_isVerifying) return;

    // Сбрасываем ошибку и состояние успешной верификации при начале нового ввода
    if (value.isNotEmpty && (_errorMessage != null || _isCodeValid)) {
      setState(() {
        _errorMessage = null;
        _isCodeValid = false;
      });
    }

    if (value.isNotEmpty) {
      // Переходим к следующему полю или проверяем код
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      // Возвращаемся к предыдущему полю при удалении
      _focusNodes[index - 1].requestFocus();
    }
    // Если удаляем символ в первом поле, остаемся на первом поле
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Заголовок
          Text(
            'Введите 6-значный код',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Код отправлен на ${widget.email}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Поля ввода кода
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => _buildCodeInput(index),
            ),
          ),

          // Сообщение об ошибке
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 32),

          // Таймер и кнопка повтора
          ValueListenableBuilder<int>(
            valueListenable: _timeLeft,
            builder: (context, timeLeft, _) {
              if (timeLeft > 0) {
                return Column(
                  children: [
                    Text(
                      'Повторная отправка через ${_formatTime(timeLeft)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (_isVerifying) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                );
              } else {
                return OutlinedButton(
                  onPressed: _resendCode,
                  child: const Text('Отправить код повторно'),
                );
              }
            },
          ),

          // Дополнительное пространство для мобильных устройств
          if (!isDesktop) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

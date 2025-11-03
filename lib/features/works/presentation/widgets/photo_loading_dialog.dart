import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, LinearProgressIndicator;

/// Тип фото для загрузки.
///
/// Используется для адаптации текстовых сообщений в диалоге загрузки.
enum PhotoType {
  /// Утреннее фото (на начало смены).
  morning,

  /// Вечернее фото (на конец смены).
  evening,
}

/// Универсальный диалог загрузки фото (утреннего или вечернего).
///
/// [PhotoLoadingDialog] отображает модальный диалог с линейным индикатором
/// прогресса (0-100%) и адаптирует текст в зависимости от типа фото.
class PhotoLoadingDialog extends StatefulWidget {
  /// Значение прогресса загрузки (0.0 - 1.0)
  final double progress;

  /// Флаг завершения загрузки
  final bool isComplete;

  /// Тип фото: утреннее или вечернее
  final PhotoType photoType;

  /// Callback при нажатии "Готово"
  final VoidCallback? onDone;

  /// Создаёт диалог загрузки фото.
  const PhotoLoadingDialog({
    super.key,
    required this.progress,
    required this.isComplete,
    required this.photoType,
    this.onDone,
  });

  @override
  State<PhotoLoadingDialog> createState() => _PhotoLoadingDialogState();
}

class _PhotoLoadingDialogState extends State<PhotoLoadingDialog>
    with TickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 300);
  static const _progressBarHeight = 6.0;
  static const _progressBarRadius = 3.0;
  static const _shadowBlur = 8.0;
  static const _circleShowDelay = Duration(milliseconds: 50);
  static const _successCircleSize = 48.0;
  static const _successCheckSize = 32.0;
  static const _successBorderWidth = 2.5;
  static const _fadeControllerDuration = Duration(milliseconds: 100);
  static const _progressBarShadowColor = 0x33007AFF;
  static const _progressBarValueColor = 0xD9007AFF;
  static const _successCircleGreenBg = 0x1900C34E;

  static const _colorGreen = CupertinoColors.systemGreen;
  static const _colorBlue = CupertinoColors.systemBlue;
  static const _colorGrey = CupertinoColors.systemGrey;
  static const _colorGrey5 = CupertinoColors.systemGrey5;
  static const _colorGrey3 = CupertinoColors.systemGrey3;

  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeOutAnimation;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: _fadeControllerDuration,
      vsync: this,
    );
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    if (widget.isComplete) {
      _showSuccess();
    }
  }

  @override
  void didUpdateWidget(PhotoLoadingDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isComplete && widget.isComplete) {
      _showSuccess();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _showSuccess() {
    _fadeController.forward().then((_) {
      if (mounted) {
        Future.delayed(_circleShowDelay, () {
          if (mounted) {
            _scaleController.forward();
          }
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _showButton = true);
      }
    });
  }

  String _getLoadingMessage() {
    return widget.photoType == PhotoType.morning
        ? 'Подожидите, идёт загрузка утреннего фото'
        : 'Подожидите, идёт загрузка вечернего фото';
  }

  String _getSuccessMessage() {
    return widget.photoType == PhotoType.morning
        ? 'Утреннее фото успешно загружено'
        : 'Вечернее фото успешно загружено';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: CupertinoAlertDialog(
        title: widget.isComplete
            ? const Text(
                'Загружено!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              )
            : const Text(
                'Загрузка…',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _fadeOutAnimation,
                child: _buildProgressBar(widget.progress),
              ),
              const SizedBox(height: 12),
              if (!widget.isComplete) ...[
                AnimatedDefaultTextStyle(
                  duration: _animationDuration,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _colorGrey,
                    letterSpacing: 0.3,
                  ),
                  child: Text(
                    '${(widget.progress * 100).toStringAsFixed(0)}%',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLoadingMessage(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _colorGrey,
                    letterSpacing: 0.2,
                  ),
                ),
              ] else ...[
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildSuccessCircle(),
                ),
                const SizedBox(height: 12),
                Text(
                  _getSuccessMessage(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _colorGrey,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (widget.isComplete) _buildDoneButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(_progressBarShadowColor),
            blurRadius: _shadowBlur,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: _progressBarHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_progressBarRadius),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _colorGrey5,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(_progressBarValueColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCircle() {
    return SizedBox(
      width: _successCircleSize,
      height: _successCircleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(_successCircleGreenBg),
          border: Border.all(
            color: _colorGreen,
            width: _successBorderWidth,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.check,
            color: _colorGreen,
            size: _successCheckSize,
          ),
        ),
      ),
    );
  }

  CupertinoDialogAction _buildDoneButton() {
    return CupertinoDialogAction(
      onPressed: _showButton ? widget.onDone : null,
      child: AnimatedDefaultTextStyle(
        duration: _animationDuration,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _showButton ? _colorBlue : _colorGrey3,
        ),
        child: const Text('Готово'),
      ),
    );
  }
}

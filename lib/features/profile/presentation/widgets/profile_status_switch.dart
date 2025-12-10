import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Переключатель статуса профиля с подтверждением при отключении.
/// Реализован в виде кнопки-статуса.
class ProfileStatusSwitch extends StatelessWidget {
  /// Текущее значение статуса (true = активен).
  final bool value;

  /// Можно ли переключать (права доступа).
  final bool canToggle;

  /// Идёт ли операция — отключает переключатель на время.
  final bool isBusy;

  /// Колбэк при подтверждённом изменении значения.
  final ValueChanged<bool> onChanged;

  /// Создает [ProfileStatusSwitch] с заданными параметрами.
  const ProfileStatusSwitch({
    super.key,
    required this.value,
    required this.canToggle,
    required this.isBusy,
    required this.onChanged,
  });

  Future<bool> _confirmDisable(BuildContext context) async {
    bool? result;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Подтвердите действие',
      message:
          'Профиль будет отключён, и пользователь будет автоматически разлогинен на всех устройствах.',
      actions: [
        AlertAction(
          title: 'Отмена',
          style: AlertActionStyle.cancel,
          onPressed: () {
            result = false;
          },
        ),
        AlertAction(
          title: 'Отключить',
          style: AlertActionStyle.primary,
          onPressed: () {
            result = true;
          },
        ),
      ],
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final onChangedCallback = (!canToggle || isBusy)
        ? null
        : () async {
            final next = !value;
            if (!next) {
              final ok = await _confirmDisable(context);
              if (!ok) return;
            }
            onChanged(next);
          };

    final theme = Theme.of(context);
    final color =
        value ? CupertinoColors.activeGreen : CupertinoColors.systemRed;

    return SizedBox(
      height: 36,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: color,
        disabledColor: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        minimumSize: Size.zero,
        onPressed: onChangedCallback,
        child: Text(
          value ? 'Активен' : 'Отключен',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

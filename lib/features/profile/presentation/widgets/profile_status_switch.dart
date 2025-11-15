import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Переключатель статуса профиля с подтверждением при отключении.
/// Лёгкий, без зависимостей от состояния — всю работу делает onChanged.
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
    return AdaptiveSwitch(
      value: value,
      onChanged: (!canToggle || isBusy)
          ? null
          : (next) async {
              if (!next) {
                final ok = await _confirmDisable(context);
                if (!ok) return;
              }
              onChanged(next);
            },
    );
  }
}

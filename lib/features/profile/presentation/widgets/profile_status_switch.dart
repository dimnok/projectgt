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
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Подтвердите действие'),
        content: const Text('Сделать профиль неактивным?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Отключить'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = value ? 'Активен' : 'Не активен';
    final statusColor = value ? Colors.green : Colors.red;

    return Row(
      children: [
        Expanded(
          child: Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ),
        Switch.adaptive(
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
        ),
      ],
    );
  }
}

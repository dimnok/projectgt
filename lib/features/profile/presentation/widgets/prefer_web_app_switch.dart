import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Переключатель перевода пользователя на новую (веб) версию.
class PreferWebAppSwitch extends StatelessWidget {
  /// Текущее значение (`true` — только новая версия).
  final bool value;

  /// Можно ли менять значение.
  final bool canToggle;

  /// Идёт сохранение.
  final bool isBusy;

  /// Вызывается после подтверждения.
  final ValueChanged<bool> onChanged;

  /// Создаёт переключатель перевода на веб-приложение.
  const PreferWebAppSwitch({
    super.key,
    required this.value,
    required this.canToggle,
    required this.isBusy,
    required this.onChanged,
  });

  Future<bool> _confirmEnable(BuildContext context) async {
    bool? result;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Перевести на новую версию?',
      message:
          'В старом приложении сразу появится экран перехода. '
          'Человек сможет работать только на сайте app.progt.ru.',
      actions: [
        AlertAction(
          title: 'Отмена',
          style: AlertActionStyle.cancel,
          onPressed: () {
            result = false;
          },
        ),
        AlertAction(
          title: 'Перевести',
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
    final theme = Theme.of(context);
    final onChangedCallback = (!canToggle || isBusy)
        ? null
        : () async {
            final next = !value;
            if (next) {
              final ok = await _confirmEnable(context);
              if (!ok) return;
            }
            onChanged(next);
          };

    final color = value
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

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
          value ? 'Новая версия' : 'Старое приложение',
          style: theme.textTheme.labelMedium?.copyWith(
            color: value
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

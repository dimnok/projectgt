import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/contract.dart';

/// Вспомогательные методы для отображения статуса договора.
class ContractStatusHelper {
  /// Возвращает текстовое описание и цвет, соответствующие заданному статусу договора.
  ///
  /// Принимает [status] (перечисление [ContractStatus]) и [theme] для подбора цветов.
  /// Возвращает кортеж (Record) с названием статуса и цветом для индикации.
  static (String, Color) getStatusInfo(ContractStatus status, ThemeData theme) {
    switch (status) {
      case ContractStatus.active:
        return ('В работе', Colors.green);
      case ContractStatus.suspended:
        return ('Приостановлен', Colors.orange);
      case ContractStatus.completed:
        return ('Завершен', Colors.grey);
    }
  }
}

/// Виджет для отображения пары "Заголовок: Значение" в деталях договора.
class ContractDetailItem extends StatelessWidget {
  /// Текстовая метка (заголовок) поля.
  final String label;

  /// Значение поля, отображаемое под заголовком.
  final String value;

  /// Создает элемент детализации договора с заданными [label] и [value].
  const ContractDetailItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Хелпер для построения иконки предупреждения о сроке действия договора.
class ContractWarningHelper {
  /// Анализирует дату окончания договора и возвращает иконку предупреждения, если срок истек или истекает.
  ///
  /// Если дата окончания не указана, возвращает null.
  /// Если срок истек, возвращает красную иконку с ошибкой.
  /// Если до окончания осталось 30 дней и меньше, возвращает желтую иконку с предупреждением.
  static Widget? buildWarningIcon(Contract contract) {
    if (contract.endDate == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      contract.endDate!.year,
      contract.endDate!.month,
      contract.endDate!.day,
    );
    final difference = end.difference(today).inDays;

    if (difference < 0) {
      return const Tooltip(
        message: 'Срок действия истёк',
        child: Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Icon(
            Icons.report_problem_rounded,
            color: Colors.red,
            size: 20,
          ),
        ),
      );
    } else if (difference <= 30) {
      return const Tooltip(
        message: 'Срок действия истекает',
        child: Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20,
          ),
        ),
      );
    }
    return null;
  }
}

/// Виджет для заголовка раздела в деталях договора.
class ContractSectionTitle extends StatelessWidget {
  /// Текст заголовка раздела.
  final String title;

  /// Создает заголовок раздела с заданным текстом [title].
  const ContractSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

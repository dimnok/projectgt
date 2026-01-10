import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'contract_list_shared.dart';

/// Элемент списка договоров для мобильной версии интерфейса (карточка).
///
/// Отображает детальную информацию о договоре: номер, статус, контрагента,
/// объект, дату и сумму. Имеет увеличенную область нажатия.
class ContractRowItemMobile extends StatelessWidget {
  /// Сущность договора для отображения в карточке.
  final Contract contract;

  /// Колбэк, вызываемый при нажатии на карточку (обычно для перехода к редактированию).
  final VoidCallback onEdit;

  /// Создает карточку договора для мобильного списка.
  const ContractRowItemMobile({
    super.key,
    required this.contract,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final numberStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );

    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
      fontWeight: FontWeight.w400,
    );

    final amountStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final warningIcon = ContractWarningHelper.buildWarningIcon(contract);
    final statusInfo = ContractStatusHelper.getStatusInfo(
      contract.status,
      theme,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (warningIcon != null) warningIcon,
                          Flexible(
                            child: Text(
                              '№ ${contract.number}',
                              style: numberStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppBadge(text: statusInfo.$1, color: statusInfo.$2),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Контрагент', style: labelStyle),
                          const SizedBox(height: 2),
                          Text(
                            contract.contractorName ?? '—',
                            style: valueStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Объект', style: labelStyle),
                          const SizedBox(height: 2),
                          Text(contract.objectName ?? '—', style: valueStyle),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Дата', style: labelStyle),
                        Text(formatRuDate(contract.date), style: valueStyle),
                      ],
                    ),
                    Text(formatCurrency(contract.amount), style: amountStyle),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

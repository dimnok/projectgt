import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'contract_list_shared.dart';

/// Компактный элемент списка договоров для десктопной версии интерфейса.
///
/// Отображает номер договора, дату, название контрагента, сумму и текущий статус.
/// Поддерживает индикацию выбора (выделение цветом) и предупреждающие иконки.
class ContractListItemDesktop extends StatelessWidget {
  /// Сущность договора для отображения.
  final Contract contract;

  /// Флаг, указывающий, выбран ли данный договор в общем списке.
  final bool isSelected;

  /// Колбэк, вызываемый при нажатии на элемент списка.
  final VoidCallback onTap;

  /// Создает элемент списка договоров.
  const ContractListItemDesktop({
    super.key,
    required this.contract,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusInfo = ContractStatusHelper.getStatusInfo(
      contract.status,
      theme,
    );
    final warningIcon = ContractWarningHelper.buildWarningIcon(contract);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Material(
        color: isSelected
            ? (isDark ? Colors.grey[800] : Colors.grey[200])
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (warningIcon != null) ...[
                  warningIcon,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '№ ${contract.number}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? Colors.blue : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatRuDate(contract.date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.blue.withValues(alpha: 0.8)
                                  : theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contract.contractorName ?? '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.8)
                              : theme.textTheme.bodySmall?.color?.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              formatCurrency(contract.amount),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.blue : null,
                              ),
                            ),
                          ),
                          AppBadge(text: statusInfo.$1, color: statusInfo.$2),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

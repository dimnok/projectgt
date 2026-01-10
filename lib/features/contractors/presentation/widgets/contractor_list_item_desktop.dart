import 'package:flutter/material.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'contractor_list_shared.dart';

/// Виджет элемента списка контрагентов для десктопной версии.
///
/// Компактная строка списка, подсвечиваемая при выборе. Отображает иконку типа,
/// краткое название контрагента, ИНН и бейдж типа.
class ContractorListItemDesktop extends StatelessWidget {
  /// Данные контрагента для отображения.
  final Contractor contractor;

  /// Флаг, указывающий, выбран ли данный элемент в списке.
  final bool isSelected;

  /// Колбэк, вызываемый при нажатии на элемент.
  final VoidCallback onTap;

  /// Создает компактный элемент списка контрагентов.
  const ContractorListItemDesktop({
    super.key,
    required this.contractor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            ContractorHelper.typeIcon(contractor.type),
                            size: 16,
                            color: isSelected
                                ? Colors.blue
                                : theme.iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              contractor.shortName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? Colors.blue : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(
                      text: contractor.type.label,
                      color: ContractorHelper.typeColor(contractor.type),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    'ИНН: ${contractor.inn}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.8)
                          : theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.6,
                            ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';

/// Табличное представление списка договоров для десктопа.
///
/// Отображает договора в виде карточек на всю ширину экрана.
/// Каждая строка - это карточка с полями: номер договора, контрагент,
/// дата окончания, сумма, статус.
class ContractTableView extends ConsumerWidget {
  /// Создает табличное представление списка договоров.
  const ContractTableView({
    super.key,
    required this.contracts,
    required this.onEdit,
    required this.onDelete,
    this.onSelect,
    this.selectedId,
  });

  /// Список договоров для отображения.
  final List<Contract> contracts;

  /// ID выбранного договора для выделения.
  final String? selectedId;

  /// Обратный вызов при выборе договора.
  final void Function(Contract)? onSelect;

  /// Обратный вызов для редактирования договора.
  final void Function(Contract) onEdit;

  /// Обратный вызов для удаления договора.
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionService = ref.watch(permissionServiceProvider);
    final canUpdate = permissionService.can('contracts', 'update');
    final canDelete = permissionService.can('contracts', 'delete');

    if (contracts.isEmpty) {
      return Center(
        child: Text('Нет договоров', style: theme.textTheme.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: contracts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        final isSelected = selectedId == contract.id;

        return _ContractCard(
          contract: contract,
          isSelected: isSelected,
          canUpdate: canUpdate,
          canDelete: canDelete,
          onTap: () => onSelect?.call(contract),
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}

/// Карточка договора на всю ширину экрана.
class _ContractCard extends StatefulWidget {
  const _ContractCard({
    required this.contract,
    required this.isSelected,
    required this.canUpdate,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Contract contract;
  final bool isSelected;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onTap;
  final void Function(Contract) onEdit;
  final void Function(String) onDelete;

  @override
  State<_ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends State<_ContractCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final warningIcon = ContractWarningHelper.buildWarningIcon(widget.contract);
    final statusInfo = ContractStatusHelper.getStatusInfo(
      widget.contract.status,
      theme,
    );

    final daysRemainingText = _getDaysRemainingText(widget.contract.endDate);
    final daysRemainingColor = _getDaysRemainingColor(widget.contract.endDate);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05))
              : (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Номер договора
              Expanded(
                flex: 12,
                child: _buildField(
                  label: 'Номер',
                  value: '№ ${widget.contract.number}',
                  icon: warningIcon,
                ),
              ),
              const SizedBox(width: 16),
              // Контрагент
              Expanded(
                flex: 20,
                child: _buildField(
                  label: 'Контрагент',
                  value: widget.contract.contractorName ?? '—',
                ),
              ),
              const SizedBox(width: 16),
              // Объект
              Expanded(
                flex: 20,
                child: _buildField(
                  label: 'Объект',
                  value: widget.contract.objectName ?? '—',
                ),
              ),
              const SizedBox(width: 16),
              // Дата окончания
              Expanded(
                flex: 10,
                child: _buildField(
                  label: 'Дата окончания',
                  value: widget.contract.endDate != null
                      ? formatRuDate(widget.contract.endDate!)
                      : '—',
                  subtitle: daysRemainingText,
                  subtitleColor: daysRemainingColor,
                ),
              ),
              const SizedBox(width: 16),
              // Сумма
              Expanded(
                flex: 12,
                child: _buildField(
                  label: 'Сумма',
                  value: formatCurrency(widget.contract.amount),
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Статус
              Expanded(
                flex: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'СТАТУС',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppBadge(text: statusInfo.$1, color: statusInfo.$2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getDaysRemainingText(DateTime? endDate) {
    if (endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final difference = end.difference(today).inDays;

    if (difference < 0) {
      final days = difference.abs();
      return 'Просрочено на $days ${_pluralDays(days)}';
    } else if (difference == 0) {
      return 'Истекает сегодня';
    } else {
      return 'Осталось $difference ${_pluralDays(difference)}';
    }
  }

  Color? _getDaysRemainingColor(DateTime? endDate) {
    if (endDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final difference = end.difference(today).inDays;

    if (difference < 0) return Colors.red;
    if (difference <= 30) return Colors.amber;
    return null;
  }

  String _pluralDays(int n) {
    int n10 = n % 10;
    int n100 = n % 100;
    if (n10 == 1 && n100 != 11) return 'день';
    if (n10 >= 2 && n10 <= 4 && (n100 < 10 || n100 >= 20)) return 'дня';
    return 'дней';
  }

  Widget _buildField({
    required String label,
    required String value,
    Widget? icon,
    TextStyle? valueStyle,
    String? subtitle,
    Color? subtitleColor,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 8)],
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: (valueStyle ?? theme.textTheme.bodyMedium)?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color:
                  subtitleColor ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: subtitleColor != null ? FontWeight.w600 : null,
            ),
          ),
        ],
      ],
    );
  }
}

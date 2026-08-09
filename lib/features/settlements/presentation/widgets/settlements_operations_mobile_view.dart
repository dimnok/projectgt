import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlement_operation_card.dart';

/// Мобильный список счетов карточками с итоговой панелью внизу.
class SettlementsOperationsMobileView extends StatelessWidget {
  /// Создаёт мобильный список.
  const SettlementsOperationsMobileView({
    super.key,
    required this.operations,
    required this.onCardTap,
  });

  /// Отфильтрованные операции.
  final List<SettlementOperation> operations;

  /// Тап по карточке.
  final ValueChanged<SettlementOperation> onCardTap;

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final cardStyle = MobileAtmosphereCardStyle.fromAppearance(appearance);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            itemCount: operations.length,
            itemBuilder: (context, index) {
              final op = operations[index];
              return SettlementOperationCard(
                operation: op,
                style: cardStyle,
                onTap: () => onCardTap(op),
              );
            },
          ),
        ),
        _MobileTotalsBar(
          theme: theme,
          isDark: isDark,
          totalAmount: operations.totalAmount,
          totalPaid: operations.totalPaid,
          totalDebt: operations.totalDebt,
        ),
      ],
    );
  }
}

class _MobileTotalsBar extends StatelessWidget {
  const _MobileTotalsBar({
    required this.theme,
    required this.isDark,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalDebt,
  });

  final ThemeData theme;
  final bool isDark;
  final double totalAmount;
  final double totalPaid;
  final double totalDebt;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              theme: theme,
              label: 'К оплате',
              value: formatCurrency(totalAmount),
              color: scheme.primary,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              theme: theme,
              label: 'Оплачено',
              value: formatCurrency(totalPaid),
              color: const Color(0xFF1565C0),
            ),
          ),
          Expanded(
            child: _SummaryItem(
              theme: theme,
              label: 'Остаток',
              value: formatCurrency(totalDebt),
              color: totalDebt > SettlementOperation.amountEpsilon
                  ? scheme.error
                  : scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.theme,
    required this.label,
    required this.value,
    required this.color,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

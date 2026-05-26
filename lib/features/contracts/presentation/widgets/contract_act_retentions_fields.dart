import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/domain/entities/contract_act.dart';

/// Значения удержаний для сохранения акта.
class ContractActRetentionInput {
  /// Создаёт набор удержаний.
  const ContractActRetentionInput({
    required this.advanceRetention,
    required this.warrantyRetention,
    required this.otherRetentions,
  });

  /// Авансовое удержание.
  final double advanceRetention;

  /// Гарантийное удержание.
  final double warrantyRetention;

  /// Прочие удержания.
  final double otherRetentions;
}

/// Поля удержаний и «Итого к оплате» для формы акта (ручной ввод и КС-2).
class ContractActRetentionsFields extends StatelessWidget {
  /// Создаёт блок удержаний.
  const ContractActRetentionsFields({
    super.key,
    required this.advanceController,
    required this.warrantyController,
    required this.otherController,
    required this.totalDisplayController,
    required this.amount,
    required this.vatAmount,
    this.enabled = true,
    this.compact = false,
    this.onChanged,
  });

  /// Компактный вид для формы КС-2 (карточки вместо линейной строки).
  final bool compact;

  /// Авансовое удержание.
  final TextEditingController advanceController;

  /// Гарантийное удержание.
  final TextEditingController warrantyController;

  /// Прочие удержания.
  final TextEditingController otherController;

  /// Итого к оплате (только чтение).
  final TextEditingController totalDisplayController;

  /// Сумма акта без НДС (или база по строкам).
  final double amount;

  /// НДС акта.
  final double vatAmount;

  /// Доступность редактирования.
  final bool enabled;

  /// После изменения удержаний (пересчёт итога).
  final VoidCallback? onChanged;

  static double _readAmount(TextEditingController c) =>
      parseAmount(c.text) ?? 0;

  /// Пересчитывает [totalDisplayController] по текущим полям.
  static void refreshTotalDisplay({
    required TextEditingController totalDisplayController,
    required TextEditingController advanceController,
    required TextEditingController warrantyController,
    required TextEditingController otherController,
    required double amount,
    required double vatAmount,
  }) {
    final total = computeContractActTotalToPay(
      amount: amount,
      vatAmount: vatAmount,
      advanceRetention: _readAmount(advanceController),
      warrantyRetention: _readAmount(warrantyController),
      otherRetentions: _readAmount(otherController),
    );
    totalDisplayController.text = formatCurrency(total);
  }

  void _handleChanged() {
    refreshTotalDisplay(
      totalDisplayController: totalDisplayController,
      advanceController: advanceController,
      warrantyController: warrantyController,
      otherController: otherController,
      amount: amount,
      vatAmount: vatAmount,
    );
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _Ks2RetentionsLayout(
        advanceController: advanceController,
        warrantyController: warrantyController,
        otherController: otherController,
        totalDisplayController: totalDisplayController,
        amount: amount,
        vatAmount: vatAmount,
        enabled: enabled,
        onFieldChanged: enabled ? _handleChanged : null,
      );
    }

    final theme = Theme.of(context);
    final showTotal = amount > 0 || vatAmount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GTTextField(
                controller: advanceController,
                labelText: 'Авансовое удержание',
                hintText: '0,00',
                suffixText: '₽',
                prefixIcon: CupertinoIcons.arrow_down_circle,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [amountFormatter()],
                enabled: enabled,
                onChanged: enabled ? (_) => _handleChanged() : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTTextField(
                controller: warrantyController,
                labelText: 'Гарантийное удержание',
                hintText: '0,00',
                suffixText: '₽',
                prefixIcon: CupertinoIcons.shield,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [amountFormatter()],
                enabled: enabled,
                onChanged: enabled ? (_) => _handleChanged() : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GTTextField(
                controller: otherController,
                labelText: 'Прочие удержания',
                hintText: '0,00',
                suffixText: '₽',
                prefixIcon: CupertinoIcons.list_bullet,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [amountFormatter()],
                enabled: enabled,
                onChanged: enabled ? (_) => _handleChanged() : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GTTextField(
          labelText: 'Итого к оплате',
          readOnly: true,
          prefixIcon: CupertinoIcons.equal_circle_fill,
          controller: totalDisplayController,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            showTotal
                ? 'Сумма акта + НДС − удержания'
                : 'Итог появится после выбора ВОР и загрузки таблицы работ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

/// Карточный блок удержаний для формы КС-2.
class _Ks2RetentionsLayout extends StatelessWidget {
  const _Ks2RetentionsLayout({
    required this.advanceController,
    required this.warrantyController,
    required this.otherController,
    required this.totalDisplayController,
    required this.amount,
    required this.vatAmount,
    required this.enabled,
    this.onFieldChanged,
  });

  final TextEditingController advanceController;
  final TextEditingController warrantyController;
  final TextEditingController otherController;
  final TextEditingController totalDisplayController;
  final double amount;
  final double vatAmount;
  final bool enabled;
  final VoidCallback? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showFinance = amount > 0 || vatAmount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFinance) ...[
          Row(
            children: [
              Expanded(
                child: _FinanceStatCard(
                  label: 'Сумма без НДС',
                  value: formatCurrency(amount),
                  icon: CupertinoIcons.sum,
                  accent: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FinanceStatCard(
                  label: 'НДС',
                  value: formatCurrency(vatAmount),
                  icon: CupertinoIcons.percent,
                  accent: scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Text(
          'УДЕРЖАНИЯ',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.85,
            fontWeight: FontWeight.w800,
            fontSize: 9.5,
            color: scheme.primary.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _RetentionInputCard(
                  label: 'Аванс',
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  accent: scheme.tertiary,
                  controller: advanceController,
                  enabled: enabled,
                  onChanged: onFieldChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RetentionInputCard(
                  label: 'Гарантия',
                  icon: CupertinoIcons.shield_fill,
                  accent: scheme.primary,
                  controller: warrantyController,
                  enabled: enabled,
                  onChanged: onFieldChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RetentionInputCard(
                  label: 'Прочие',
                  icon: CupertinoIcons.list_bullet_indent,
                  accent: scheme.secondary,
                  controller: otherController,
                  enabled: enabled,
                  onChanged: onFieldChanged,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _TotalToPayCard(
          totalText: totalDisplayController.text,
          showPlaceholder: !showFinance,
        ),
      ],
    );
  }
}

class _FinanceStatCard extends StatelessWidget {
  const _FinanceStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetentionInputCard extends StatelessWidget {
  const _RetentionInputCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.controller,
    required this.enabled,
    this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.55 : 0.85,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(icon, size: 14, color: accent),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GTTextField(
              controller: controller,
              hintText: '0,00',
              suffixText: '₽',
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [amountFormatter()],
              enabled: enabled,
              onChanged: enabled && onChanged != null
                  ? (_) => onChanged!()
                  : null,
              borderRadius: 8,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              fillColor: scheme.surface.withValues(alpha: isDark ? 0.45 : 0.95),
              borderSide: BorderSide(
                color: scheme.outline.withValues(alpha: 0.18),
              ),
              focusedBorderSide: BorderSide(color: accent, width: 1.25),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalToPayCard extends StatelessWidget {
  const _TotalToPayCard({
    required this.totalText,
    required this.showPlaceholder,
  });

  final String totalText;
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: isDark ? 0.55 : 0.85),
            scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CupertinoIcons.money_rubl_circle_fill,
                  size: 22,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'К оплате',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    showPlaceholder ? '—' : totalText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_line.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';

/// Сумма по разделу сметы в акте.
class ContractActSectionTotal {
  /// Создаёт запись итога по разделу.
  const ContractActSectionTotal({
    required this.title,
    required this.amount,
  });

  /// Название раздела.
  final String title;

  /// Сумма строк раздела.
  final double amount;
}

/// Группирует строки акта по [ContractActLine.sectionTitle].
List<ContractActSectionTotal> groupActLinesBySection(
  List<ContractActLine> lines,
) {
  if (lines.isEmpty) return const [];

  final sorted = List<ContractActLine>.from(lines)
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final order = <String>[];
  final amounts = <String, double>{};

  for (final line in sorted) {
    final title = line.sectionTitle.trim().isEmpty
        ? 'Без раздела'
        : line.sectionTitle.trim();
    if (!amounts.containsKey(title)) {
      order.add(title);
      amounts[title] = 0;
    }
    amounts[title] = amounts[title]! + line.amount;
  }

  return order
      .map((t) => ContractActSectionTotal(title: t, amount: amounts[t]!))
      .toList();
}

/// Раскрывающаяся панель деталей акта под строкой списка.
///
/// Показывает суммы по разделам (для КС-2) и финансовый итог с удержаниями.
class ContractActDetailPanel extends ConsumerWidget {
  /// Создаёт панель деталей.
  const ContractActDetailPanel({
    super.key,
    required this.act,
  });

  /// Акт, для которого показываются детали.
  final ContractAct act;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final panelBg = scheme.surfaceContainerLow.withValues(
      alpha: isDark ? 0.55 : 0.92,
    );

    final borderColor = scheme.outline.withValues(alpha: 0.1);
    final accentColor = scheme.primary.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 4, bottom: 2),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: panelBg,
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: accentColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 12, 14, 14),
                child: act.isKs2
                    ? _Ks2DetailBody(act: act)
                    : _ManualActBody(
                        act: act,
                        theme: theme,
                        scheme: scheme,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ks2DetailBody extends ConsumerWidget {
  const _Ks2DetailBody({required this.act});

  final ContractAct act;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linesAsync = ref.watch(contractActLinesProvider(act.id));
    return linesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => _ErrorText(message: 'Не удалось загрузить строки: $e'),
      data: (lines) => _DetailContent(
        act: act,
        sections: groupActLinesBySection(lines),
      ),
    );
  }
}

class _ManualActBody extends StatelessWidget {
  const _ManualActBody({
    required this.act,
    required this.theme,
    required this.scheme,
  });

  final ContractAct act;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return _DetailContent(
      act: act,
      sections: const [],
      sectionsPlaceholder:
          'Ручной акт — разбивка по разделам сметы не ведётся.',
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.act,
    required this.sections,
    this.sectionsPlaceholder,
  });

  final ContractAct act;
  final List<ContractActSectionTotal> sections;
  final String? sectionsPlaceholder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final sectionsBlock = _SectionsBlock(
          sections: sections,
          placeholder: sectionsPlaceholder,
        );
        final totalsBlock = _FinancialSummaryBlock(act: act);

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: sectionsBlock),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: totalsBlock),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionsBlock,
            const SizedBox(height: 14),
            totalsBlock,
          ],
        );
      },
    );
  }
}

class _SectionsBlock extends StatelessWidget {
  const _SectionsBlock({
    required this.sections,
    this.placeholder,
  });

  final List<ContractActSectionTotal> sections;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BlockTitle(label: 'По разделам'),
        const SizedBox(height: 8),
        if (sections.isEmpty)
          Text(
            placeholder ?? 'Нет строк в акте.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
              height: 1.35,
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: sections.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: scheme.outline.withValues(alpha: 0.08),
              ),
              itemBuilder: (context, index) {
                final s = sections[index];
                return _SectionRow(
                  title: s.title,
                  amount: s.amount,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.title,
    required this.amount,
  });

  final String title;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(amount),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummaryBlock extends StatelessWidget {
  const _FinancialSummaryBlock({required this.act});

  final ContractAct act;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountWithVat = act.amount + act.vatAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BlockTitle(label: 'Итоги'),
        const SizedBox(height: 8),
        _SummaryCard(
          children: [
            _MoneyRow(
              label: 'Общая сумма',
              value: formatCurrency(act.amount),
            ),
            if (act.vatAmount > 0)
              _MoneyRow(
                label: 'Сумма НДС',
                value: formatCurrency(act.vatAmount),
              ),
            _MoneyRow(
              label: 'Сумма с НДС',
              value: formatCurrency(amountWithVat),
              emphasized: true,
            ),
            Divider(
              height: 20,
              color: scheme.outline.withValues(alpha: 0.12),
            ),
            if (act.advanceRetention > 0)
              _MoneyRow(
                label: 'Авансовые удержания',
                value: formatCurrency(-act.advanceRetention),
                negative: true,
              ),
            if (act.warrantyRetention > 0)
              _MoneyRow(
                label: 'Гарантийные удержания',
                value: formatCurrency(-act.warrantyRetention),
                negative: true,
              ),
            if (act.otherRetentions > 0)
              _MoneyRow(
                label: 'Прочие удержания',
                value: formatCurrency(-act.otherRetentions),
                negative: true,
              ),
            if (act.advanceRetention == 0 &&
                act.warrantyRetention == 0 &&
                act.otherRetentions == 0)
              _MoneyRow(
                label: 'Удержания',
                value: formatCurrency(0),
                muted: true,
              ),
            const SizedBox(height: 4),
            _MoneyRow(
              label: 'К оплате',
              value: formatCurrency(act.totalToPay),
              isTotal: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 0.85,
        fontWeight: FontWeight.w800,
        fontSize: 9.5,
        color: scheme.primary.withValues(alpha: 0.85),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.negative = false,
    this.muted = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool negative;
  final bool muted;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isTotal) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final valueColor = negative
        ? scheme.error
        : muted
        ? scheme.onSurface.withValues(alpha: 0.45)
        : emphasized
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.88);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

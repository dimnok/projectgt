import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_list_shared.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';

/// Обзор «Общие данные»: группируем поля карточки договора в читаемые блоки
/// (dashboard-паттерн: KPI-секция → карточки по темам → идентификаторы).
///
/// На ширине ≥920 px — два столбца: слева финансы и сроки, справа стороны,
/// платежная структура и подписанты.
class ContractDetailsMainInformationSection extends StatelessWidget {
  /// Создаёт секцию основной информации по [contract].
  const ContractDetailsMainInformationSection({
    super.key,
    required this.contract,
  });

  /// Договор-источник данных.
  final Contract contract;

  static const double _wideBreakpoint = 920;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        final isWide = c.maxWidth >= _wideBreakpoint;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
          child: isWide
              ? _buildWide(theme, scheme, contract)
              : _buildStacked(theme, scheme, contract),
        );
      },
    );
  }

  /// Двухколоночная сетка (см. analytics dashboard: основной KPI + вторичные карточки).
  static Widget _buildWide(
    ThemeData theme,
    ColorScheme scheme,
    Contract contract,
  ) {
    final gutter = SizedBox(height: scheme.brightness == Brightness.dark ? 16 : 15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageIntro(theme, scheme),
        gutter,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cardFinancialCore(theme, contract),
                  gutter,
                  _cardTiming(theme, contract),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cardParties(theme, contract),
                  gutter,
                  _cardPaymentTerms(theme, contract),
                  if (_hasDocLines(contract)) ...[
                    gutter,
                    _cardSigners(theme, contract),
                  ],
                ],
              ),
            ),
          ],
        ),
        gutter,
        _identifiersPanel(theme, contract),
      ],
    );
  }

  static Widget _buildStacked(
    ThemeData theme,
    ColorScheme scheme,
    Contract contract,
  ) {
    final g = SizedBox(height: scheme.brightness == Brightness.dark ? 14 : 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageIntro(theme, scheme),
        g,
        _cardFinancialCore(theme, contract),
        g,
        _cardTiming(theme, contract),
        g,
        _cardParties(theme, contract),
        g,
        _cardPaymentTerms(theme, contract),
        if (_hasDocLines(contract)) ...[
          g,
          _cardSigners(theme, contract),
        ],
        g,
        _identifiersPanel(theme, contract),
      ],
    );
  }

  static Widget _pageIntro(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.square_grid_2x2_fill,
              size: 18,
              color: scheme.primary.withValues(alpha: 0.88),
            ),
            const SizedBox(width: 8),
            Text(
              'ОБЗОР ПО ДОГОВОРУ',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: scheme.primary.withValues(alpha: 0.92),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Ключевые суммы, сроки и участники собраны в одном экране. '
          'Платежи, сметы и файлы — на отдельных вкладках.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  static Widget _identifiersPanel(ThemeData theme, Contract contract) {
    final scheme = theme.colorScheme;

    Widget mono(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.85,
                fontWeight: FontWeight.w700,
                fontSize: 8.5,
                color: scheme.onSurface.withValues(alpha: 0.42),
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.028),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
        child: Builder(
          builder: (context) {
            final auditStamp = contract.updatedAt ?? contract.createdAt;
            final auditText = auditStamp != null
                ? formatRuDateTime(auditStamp)
                : 'Нет времени сохранения';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Технический контекст',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                mono('Запись', _shortUuid(contract.id)),
                mono('Компания (company)', _shortUuid(contract.companyId)),
                mono('Карточка обновлена', auditText),
                Text(
                  'Используйте при обращении в поддержку или в логах.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.48),
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _shortUuid(String raw) {
    final t = raw.trim();
    if (t.length <= 14) return t;
    return '${t.substring(0, 8)}…${t.substring(t.length - 4)}';
  }

  static Widget _cardFinancialCore(ThemeData theme, Contract contract) {
    final scheme = theme.colorScheme;
    final advancePct = contract.amount > 0 && contract.advanceAmount > 0
        ? (contract.advanceAmount / contract.amount * 100)
            .clamp(0, 999)
            .toStringAsFixed(0)
        : null;
    final netBase = formatCurrency(_netContractBaseExcludingStoredVat(contract));

    final vatModeLine = contract.isVatIncluded
        ? 'Стоимость включает НДС; сумма «Без учёта НДС» — база без учётной суммы НДС в карте.'
        : 'НДС начисляется сверх указанной цены (смотрите поле суммы НДС и ставку ниже).';

    return _overviewSectionCard(
      theme,
      scheme,
      icon: CupertinoIcons.money_rubl_circle_fill,
      title: 'Финансы и расчётные параметры',
      subtitle:
          'Суммы условий договора. Факт оплат и регистров — во вкладке «Финансы».',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kvDataRow(
            theme,
            icon: CupertinoIcons.creditcard_fill,
            label: 'Стоимость по договору',
            value: formatCurrency(contract.amount),
            emphasize: true,
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.arrow_down_circle_fill,
            label: 'Аванс по договору',
            value: formatCurrency(contract.advanceAmount),
            footnote: advancePct != null
                ? '~$advancePct% от суммы договора'
                : (contract.advanceAmount > 0 ? null : 'Не указан'),
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.doc_text_fill,
            label: 'НДС',
            value: formatCurrency(contract.vatAmount),
            footnote: _vatFinanceRowFootnote(contract),
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.doc_plaintext,
            label: contract.isVatIncluded ? 'Без учёта НДС' : 'Базовая сумма договора',
            value: netBase,
            footnote: contract.vatAmount > 0
                ? 'НДС в карте: ${formatCurrency(contract.vatAmount)}'
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            vatModeLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.52),
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cardTiming(ThemeData theme, Contract contract) {
    final scheme = theme.colorScheme;
    final statusBadge = ContractStatusHelper.tableBadgePalette(
      contract.status,
      scheme,
    );

    return _overviewSectionCard(
      theme,
      scheme,
      icon: CupertinoIcons.hourglass_bottomhalf_fill,
      title: 'Сроки и статус',
      subtitle: 'Горизонт действия по договору и оперативный статус в системе.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kvDataRow(
            theme,
            icon: CupertinoIcons.calendar_circle_fill,
            label: 'Дата заключения',
            value: formatRuDate(contract.date),
          ),
          _kvDivider(theme),
          _mainInfoDatesAndStatusRow(theme, contract, statusBadge),
          if (_mainInfoDurationCaption(contract) != null) ...[
            const SizedBox(height: 12),
            Text(
              _mainInfoDurationCaption(contract)!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _cardParties(ThemeData theme, Contract contract) {
    final scheme = theme.colorScheme;
    return _overviewSectionCard(
      theme,
      scheme,
      icon: CupertinoIcons.person_3_fill,
      title: 'Стороны и объект',
      subtitle: 'На кого заведены отношения и по какому объекту недвижимости.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kvDataRow(
            theme,
            icon: CupertinoIcons.person_2_fill,
            label: 'Контрагент',
            value: contract.contractorName ?? '—',
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.building_2_fill,
            label: 'Объект строительства',
            value: contract.objectName ?? '—',
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.arrow_left_right,
            label: 'Роль контрагента',
            value: ContractKindUi.label(contract.kind),
            footnote: 'Тип договора в терминологии участия контрагента',
          ),
        ],
      ),
    );
  }

  static Widget _cardPaymentTerms(ThemeData theme, Contract contract) {
    final scheme = theme.colorScheme;
    final advancePct = contract.amount > 0 && contract.advanceAmount > 0
        ? (contract.advanceAmount / contract.amount * 100)
            .clamp(0, 999)
            .toStringAsFixed(0)
        : null;
    final vatBasis = contract.isVatIncluded
        ? 'в том числе НДС'
        : 'НДС сверху';
    final warrantySubtitle = contract.warrantyPeriodMonths > 0
        ? '${contract.warrantyRetentionRate.toStringAsFixed(0)}% · '
            '${contract.warrantyPeriodMonths} мес.'
        : (contract.warrantyRetentionAmount > 0 ? null : 'Не заданы');
    final genSubtitle = contract.generalContractorFeeRate > 0
        ? '${contract.generalContractorFeeRate.toStringAsFixed(0)}% от контракта'
        : (contract.generalContractorFeeAmount > 0 ? null : 'Не заданы');

    return _overviewSectionCard(
      theme,
      scheme,
      icon: CupertinoIcons.chart_bar_circle_fill,
      title: 'Платежи и удержания',
      subtitle:
          'Налоговая ставка и зарезервированные суммы по условиям договора.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kvDataRow(
            theme,
            icon: CupertinoIcons.percent,
            label: 'НДС (${contract.vatRate.toStringAsFixed(0)}%)',
            value: formatCurrency(contract.vatAmount),
            footnote: vatBasis,
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.arrow_down_circle_fill,
            label: 'Аванс',
            value: formatCurrency(contract.advanceAmount),
            footnote: advancePct != null
                ? '~$advancePct% от суммы договора'
                : (contract.advanceAmount > 0 ? null : 'Не указан в карточке'),
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.shield_fill,
            label: 'Гарантийные удержания',
            value: formatCurrency(contract.warrantyRetentionAmount),
            footnote: warrantySubtitle,
          ),
          _kvDivider(theme),
          _kvDataRow(
            theme,
            icon: CupertinoIcons.briefcase_fill,
            label: 'Генподрядное удержание',
            value: formatCurrency(contract.generalContractorFeeAmount),
            footnote: genSubtitle,
          ),
        ],
      ),
    );
  }

  static bool _hasDocLines(Contract contract) =>
      [
        contract.contractorOrgName,
        contract.contractorPosition,
        contract.contractorSigner,
        contract.customerOrgName,
        contract.customerPosition,
        contract.customerSigner,
      ].any((e) => e != null && e.trim().isNotEmpty);

  static Widget _cardSigners(ThemeData theme, Contract contract) {
    final scheme = theme.colorScheme;
    return _overviewSectionCard(
      theme,
      scheme,
      icon: CupertinoIcons.pencil_ellipsis_rectangle,
      title: 'Подписанты для документов',
      subtitle: 'Реквизиты и ФИО, если заполнены в карточке.',
      child: _mainInfoDocumentMetaBlock(theme, contract),
    );
  }

  static Widget _overviewSectionCard(
    ThemeData theme,
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final fill = scheme.surfaceContainerHighest.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.32 : 0.65,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.11)),
        color: fill,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 10),
            blurRadius: 22,
            color: Colors.black.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.32 : 0.05,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: scheme.primary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.53),
                            height: 1.38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            child,
          ],
        ),
      ),
    );
  }

  static Widget _kvDivider(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Divider(
      height: 20,
      thickness: 1,
      color: scheme.outline.withValues(alpha: 0.088),
    );
  }

  static Widget _kvDataRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    String? footnote,
    bool emphasize = false,
  }) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 17,
              color: scheme.primary.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 38,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  value,
                  style: (emphasize
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(
                        fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                        height: 1.28,
                      ),
                ),
                if (footnote != null && footnote.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    footnote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      height: 1.32,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// --- Расчёты без новых доменных полей ---
  static String? _mainInfoDurationCaption(Contract contract) {
    final end = contract.endDate;
    if (end == null) return null;
    final start = DateTime(
      contract.date.year,
      contract.date.month,
      contract.date.day,
    );
    final endDay = DateTime(end.year, end.month, end.day);
    final totalDays = endDay.difference(start).inDays;
    if (totalDays < 0) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = endDay.difference(today).inDays;

    if (daysLeft < 0) {
      return 'Календарная длительность: $totalDays дней · '
          'срок истёк ${-daysLeft} дней назад';
    }
    if (daysLeft == 0) {
      return 'Календарная длительность: $totalDays дней · срок истекает сегодня';
    }
    return 'Календарная длительность: $totalDays дней · '
        'до окончания $daysLeft дн.';
  }

  static double _netContractBaseExcludingStoredVat(Contract contract) {
    if (!contract.isVatIncluded) return contract.amount;
    final raw = contract.amount - contract.vatAmount;
    if (raw.isFinite && raw >= 0) return raw;
    return contract.amount;
  }

  /// Подпись к строке «НДС» в блоке финансов (ставка и способ учёта).
  static String _vatFinanceRowFootnote(Contract contract) {
    final full =
        'НДС ${formatCurrency(contract.vatAmount)} · '
        '${contract.vatRate.toStringAsFixed(0)}% · '
        '${contract.isVatIncluded ? 'включён' : 'сверху'}';
    if (full.length <= 52) return full;
    return '${contract.vatRate.toStringAsFixed(0)}% · '
        '${contract.isVatIncluded ? 'включён в сумму' : 'начисляется сверху'}';
  }

  static Widget _mainInfoDatesAndStatusRow(
    ThemeData theme,
    Contract contract,
    ({String label, Color foreground, Color fill, Color border}) statusBadge,
  ) {
    final startCard = _mainInfoDateCard(
      theme,
      icon: CupertinoIcons.calendar_badge_plus,
      caption: 'Дата начала действия',
      value: formatRuDate(contract.date),
    );
    final endCard = _mainInfoDateCard(
      theme,
      icon: CupertinoIcons.calendar_badge_minus,
      caption: 'Окончание',
      value:
          contract.endDate != null ? formatRuDate(contract.endDate!) : '— не задано',
    );
    final statusCard = _mainInfoDateCard(
      theme,
      icon: CupertinoIcons.flag_fill,
      caption: 'Статус цикла',
      valueWidget: Align(
        alignment: Alignment.centerLeft,
        child: AppBadge(
          text: statusBadge.label,
          color: statusBadge.foreground,
          fillColor: statusBadge.fill,
          borderColor: statusBadge.border,
          borderRadius: 8,
          fontSize: 11,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              startCard,
              const SizedBox(height: 8),
              endCard,
              const SizedBox(height: 8),
              statusCard,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: startCard),
            const SizedBox(width: 10),
            Expanded(child: endCard),
            const SizedBox(width: 10),
            Expanded(child: statusCard),
          ],
        );
      },
    );
  }

  static Widget _mainInfoDateCard(
    ThemeData theme, {
    required IconData icon,
    required String caption,
    String? value,
    Widget? valueWidget,
  }) {
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary.withValues(alpha: 0.74)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                      letterSpacing: 0.58,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (valueWidget != null)
                    valueWidget
                  else
                    SelectableText(
                      value ?? '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        height: 1.22,
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

  static Widget _mainInfoDocumentMetaBlock(ThemeData theme, Contract contract) {
    final scheme = theme.colorScheme;
    final lineStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.32,
      color: scheme.onSurface.withValues(alpha: 0.84),
    );

    Widget line(String title, String? v) {
      if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SelectableText.rich(
          TextSpan(
            style: lineStyle,
            children: [
              TextSpan(
                text: '$title\n',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.48),
                  fontSize: theme.textTheme.labelSmall?.fontSize,
                ),
              ),
              TextSpan(text: v.trim()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line('Организация контрагента', contract.contractorOrgName),
        line(
          'Подписант (контрагент)',
          _mainInfoSignerLine(
            contract.contractorSigner,
            contract.contractorPosition,
          ),
        ),
        line('Организация заказчика', contract.customerOrgName),
        line(
          'Подписант (заказчик)',
          _mainInfoSignerLine(
            contract.customerSigner,
            contract.customerPosition,
          ),
        ),
      ],
    );
  }

  static String? _mainInfoSignerLine(String? name, String? position) {
    final n = name?.trim();
    final p = position?.trim();
    if ((n == null || n.isEmpty) && (p == null || p.isEmpty)) return null;
    if (p == null || p.isEmpty) return n;
    if (n == null || n.isEmpty) return p;
    return '$n · $p';
  }
}

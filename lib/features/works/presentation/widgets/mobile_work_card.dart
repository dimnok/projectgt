import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';

/// Карточка смены для мобильного списка.
///
/// [listMonth] и [listIndex] участвуют в [Hero.tag], чтобы не было коллизий при
/// пагинации или нескольких группах месяцев в одном скролле.
///
/// Оболочка как у карточки сотрудника (градиент, рамка, подсветка, тень).
/// Слева — компактный **календарный блок** (полоса + день недели, число, месяц),
/// без квадрата «под фото»; справа от даты — слева точка, объект и сумма смены;
/// справа вверху — ФИО; при известном [Work.employeesCount] ниже справа число людей;
/// нижняя строка: общая сумма смены слева; справа — сумма на человека в формате «… ₽/чел»
/// (числитель — [Work.ownTotalAmount] при наличии, иначе [Work.totalAmount]).
class MobileWorkCard extends StatelessWidget {
  /// Создаёт карточку смены.
  const MobileWorkCard({
    super.key,
    required this.work,
    required this.listMonth,
    required this.listIndex,
    required this.style,
    required this.objectName,
    required this.createdBy,
    required this.onTap,
    required this.statusColor,
    required this.statusSemanticsLabel,
  });

  /// Данные о смене.
  final Work work;

  /// Первый день месяца группы списка (вместе с [listIndex] задаёт уникальный [Hero.tag]).
  final DateTime listMonth;

  /// Индекс карточки в списке месяца.
  final int listIndex;

  /// Стили оболочки карточки ([MobileAtmosphereCardStyle]).
  final MobileAtmosphereCardStyle style;

  /// Название объекта.
  final String objectName;

  /// Кто открыл смену (краткое имя).
  final String createdBy;

  /// Нажатие по карточке.
  final VoidCallback onTap;

  /// Цвет индикатора статуса.
  final Color statusColor;

  /// Подпись статуса для [Semantics] (на экране — только точка).
  final String statusSemanticsLabel;

  static const double _cardDecorationRadius = 16;
  static const double _cardClipRadius = 15;
  /// Ширина колонки даты (полоса + типографика), уже квадрата аватара.
  static const double _dateRailWidth = 56;
  static const EdgeInsets _contentPadding = EdgeInsets.all(10);
  static const double _statusDotDiameter = 10;

  static String _dayOfMonthFromRuDate(String ruDate) {
    final parts = ruDate.split('.');
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first;
    }
    return ruDate;
  }

  /// Число людей и сумма на человека в формате как раньше (`… ₽/чел`).
  ///
  /// Числитель: [Work.ownTotalAmount] при наличии, иначе [Work.totalAmount] (старый API).
  /// `null`, если [Work.employeesCount] не задан.
  static ({String peopleLabel, String? perHeadLine})? _peopleMetrics(Work work) {
    final n = work.employeesCount;
    if (n == null) return null;
    if (n <= 0) {
      return (peopleLabel: '0 чел.', perHeadLine: null);
    }
    final ownTotal = work.ownTotalAmount ?? work.totalAmount ?? 0;
    final perHead = ownTotal / n;
    return (
      peopleLabel: '$n чел.',
      perHeadLine: '${formatCurrency(perHead)}/чел',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = style.scheme;
    final hi = style.cardHighlight;
    final ru = formatRuDate(work.date);
    final dayLine = _dayOfMonthFromRuDate(ru);
    final weekdayLine = formatRuWeekdayShort(work.date);
    final monthYearLine = formatCompactMonthYear(work.date);
    final amountLine = formatCurrency(work.totalAmount ?? 0);
    final peopleMetrics = _peopleMetrics(work);

    return Hero(
      tag:
          'work_card_${listMonth.millisecondsSinceEpoch}_${work.id ?? 'null'}_$listIndex',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_cardDecorationRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_cardDecorationRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [style.cardTop, style.cardBottom],
              ),
              border: Border.all(width: 1, color: style.cardBorder),
              boxShadow: style.cardShadows,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_cardClipRadius),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            hi.withValues(alpha: 0.0),
                            hi,
                            hi.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: _contentPadding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: 'Дата смены: $ru',
                          child: SizedBox(
                            width: _dateRailWidth,
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: scheme.primary.withValues(
                                        alpha: 0.28,
                                      ),
                                    ),
                                    child: const SizedBox(width: 3),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (weekdayLine.isNotEmpty)
                                          Text(
                                            weekdayLine,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              height: 1,
                                              letterSpacing: 0.9,
                                            ),
                                          ),
                                        if (weekdayLine.isNotEmpty)
                                          const SizedBox(height: 4),
                                        Text(
                                          dayLine,
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        if (monthYearLine.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            monthYearLine,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: scheme.outline,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              height: 1.2,
                                              letterSpacing: 0.08,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            label:
                                'Статус: $statusSemanticsLabel. $objectName. $createdBy. Сумма $amountLine'
                                '${peopleMetrics != null ? '. ${peopleMetrics.peopleLabel}' : ''}'
                                '${peopleMetrics?.perHeadLine != null ? ' ${peopleMetrics!.perHeadLine}' : ''}',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Container(
                                              width: _statusDotDiameter,
                                              height: _statusDotDiameter,
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              objectName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: scheme.onSurface,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                height: 1.22,
                                                letterSpacing: -0.25,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        createdBy,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          height: 1.28,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (peopleMetrics != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Expanded(
                                        flex: 3,
                                        child: SizedBox.shrink(),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          peopleMetrics.peopleLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            color: scheme.outline,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            height: 1.25,
                                            letterSpacing: 0.06,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ] else
                                  const SizedBox(height: 7),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: _statusDotDiameter + 8,
                                        ),
                                        child: Text(
                                          amountLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                            letterSpacing: 0.12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: peopleMetrics?.perHeadLine != null
                                          ? Text(
                                              peopleMetrics!.perHeadLine!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                height: 1.25,
                                                letterSpacing: 0.06,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

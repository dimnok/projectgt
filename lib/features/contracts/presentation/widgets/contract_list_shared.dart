import 'package:flutter/material.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/domain/entities/contract.dart';

/// Веса flex-колонок строки таблицы списка договоров (десктоп и мобильный).
///
/// Совпадает с порядком: номер · тип · контрагент · объект · период · сумма · статус.
abstract final class ContractListTableColumnFlex {
  /// Колонка «Номер» (длинные номера — приоритет по ширине).
  static const int number = 26;

  /// Колонка «Тип» ([ContractKind]) — короткие подписи.
  static const int kind = 8;

  /// Колонка «Контрагент».
  static const int contractor = 14;

  /// Колонка «Объект».
  static const int object = 14;

  /// Колонка «Период» (начало и окончание в две строки).
  static const int period = 10;

  /// Колонка «Сумма».
  static const int amount = 13;

  /// Колонка «Статус».
  static const int status = 9;
}

/// Тексты заголовков колонок списка договоров.
abstract final class ContractListTableHeaders {
  /// Заголовок колонки номера.
  static const String number = 'Номер';

  /// Заголовок колонки типа договора.
  static const String kind = 'Тип';

  /// Заголовок колонки контрагента.
  static const String contractor = 'Контрагент';

  /// Заголовок колонки объекта.
  static const String object = 'Объект';

  /// Заголовок колонки периода действия договора.
  static const String period = 'Период';

  /// Заголовок колонки суммы.
  static const String amount = 'Сумма';

  /// Заголовок колонки статуса.
  static const String status = 'Статус';
}

/// Одна строка заголовков таблицы договоров (без собственных отступов контейнера).
class ContractTableHeaderRow extends StatelessWidget {
  /// Создаёт строку заголовков с тем же шагом колонок, что и у строк данных.
  const ContractTableHeaderRow({super.key});

  static const double _columnGap = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.42),
      fontSize: 10,
      letterSpacing: 1.0,
      fontWeight: FontWeight.w600,
    );

    Widget cell(String header) =>
        Text(header.toUpperCase(), style: style, maxLines: 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: ContractListTableColumnFlex.number,
          child: cell(ContractListTableHeaders.number),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          flex: ContractListTableColumnFlex.kind,
          child: cell(ContractListTableHeaders.kind),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          flex: ContractListTableColumnFlex.contractor,
          child: cell(ContractListTableHeaders.contractor),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          flex: ContractListTableColumnFlex.object,
          child: cell(ContractListTableHeaders.object),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          flex: ContractListTableColumnFlex.period,
          child: cell(ContractListTableHeaders.period),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          flex: ContractListTableColumnFlex.amount,
          child: cell(ContractListTableHeaders.amount),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          flex: ContractListTableColumnFlex.status,
          child: cell(ContractListTableHeaders.status),
        ),
      ],
    );
  }
}

/// Вертикальная геометрия шапки таблицы над первой карточкой — синхронно с
/// [ContractTableView] (`Padding` + [ContractTableHeaderRow]).
abstract final class ContractListTableLayout {
  /// Отступ между строкой заголовков колонок и первой карточкой списка.
  static const double headerBottomSpacing = 8;

  /// Нижнее поле [ListView.separated] в [ContractTableView] (без горизонтальных inset).
  static const double listBottomPadding = 12;

  /// Высота от верха [ContractTableView] до верха первой карточки договора.
  ///
  /// Используется для выравнивания боковых панелей с рядом карточек на десктопе.
  static double offsetTopToFirstCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.42),
      fontSize: 10,
      letterSpacing: 1.0,
      fontWeight: FontWeight.w600,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: ContractListTableHeaders.number.toUpperCase(),
        style: style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.height + headerBottomSpacing;
  }
}

/// Горизонтальная сетка экрана списка договоров.
///
/// Один модуль [gridGutter]: экран — край карточки, карточка — сайдбар,
/// сайдбар — экран (внешний [desktopBodyOuterPadding] +
/// [listToSidebarRowGap]; [tableListHorizontalPadding] = 0).
abstract final class ContractListScreenDesktopChrome {
  /// Единый шаг между экраном, карточками и сайдбаром.
  static const double gridGutter = 16;

  /// Совпадает с [gridGutter] и с полями шапки экрана (`fromLTRB(16,…)`).
  static const double pageHorizontalPadding = gridGutter;

  /// Без дополнительного inset у [ListView]: поле до карточек — только внешний
  /// [Padding] экрана ([desktopBodyOuterPadding]).
  static const double tableListHorizontalPadding = 0;

  /// Зазор между колонкой [ContractTableView] и сайдбаром в [Row].
  static const double listToSidebarRowGap = gridGutter;

  /// Поля блока со списком (слева, справа, снизу).
  static const EdgeInsets desktopBodyOuterPadding = EdgeInsets.fromLTRB(
    pageHorizontalPadding,
    0,
    pageHorizontalPadding,
    10,
  );

  /// Шапка экрана (меню, поиск, тема): горизонтали как у [desktopBodyOuterPadding].
  static const EdgeInsets desktopHeaderOuterPadding = EdgeInsets.fromLTRB(
    pageHorizontalPadding,
    20,
    pageHorizontalPadding,
    8,
  );
}

/// Карточка в том же визуальном языке, что и строка [ContractTableView]: градиент
/// атмосферы, тень, внутренняя подсветка верхнего края и обводка.
///
/// Для статичных блоков деталей договора (без hover / lift).
class ContractAtmosphereCard extends StatelessWidget {
  /// Контент внутри полей, совпадающих по ширине с содержимым строки списка.
  const ContractAtmosphereCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 15, 18, 15),
    this.selected = false,
  });

  /// Вложенный виджет.
  final Widget child;

  /// Внутренние поля (18×15×18×15 — как у строки таблицы договоров).
  final EdgeInsetsGeometry padding;

  /// Если true — акцентная обводка [ColorScheme.primary] (как у выбранной строки).
  final bool selected;

  static const double _outerRadius = 16;
  static const double _clipRadius = 15;

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final cardStyle = MobileAtmosphereCardStyle.fromAppearance(appearance);
    final scheme = appearance.scheme;
    final hi = cardStyle.cardHighlight;

    final borderColor =
        selected ? scheme.primary : cardStyle.cardBorder;
    final borderWidth = selected ? 1.5 : 1.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardStyle.cardTop, cardStyle.cardBottom],
        ),
        boxShadow: cardStyle.cardShadows,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
        border: Border.fromBorderSide(
          BorderSide(
            color: borderColor,
            width: borderWidth,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_clipRadius),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.antiAlias,
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
                      hi.withValues(alpha: 0),
                      hi.withValues(alpha: selected ? 0.95 : 0.65),
                      hi.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Колонка «Период» в строке таблицы: на первой строке дата начала и тире, на второй —
/// дата окончания (или «—»).
class ContractPeriodTableCell extends StatelessWidget {
  /// Договор, даты берутся из [Contract.date] и [Contract.endDate].
  final Contract contract;

  /// Общий стиль текста дат (как у других ячеек строки).
  final TextStyle? valueStyle;

  /// Виджет ячейки периода.
  const ContractPeriodTableCell({
    super.key,
    required this.contract,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = formatRuDate(contract.date);
    final endStr = contract.endDate != null
        ? formatRuDate(contract.endDate!)
        : '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$startStr –',
          style: valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          endStr,
          style: valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Подписи для [ContractKind] в списках и формах.
abstract final class ContractKindUi {
  /// Краткий текст для колонки «Тип» и выпадающих списков.
  static String label(ContractKind kind) {
    switch (kind) {
      case ContractKind.customer:
        return 'Заказчик';
      case ContractKind.subcontract:
        return 'Подряд';
      case ContractKind.supply:
        return 'Поставка';
    }
  }
}

/// Вспомогательные методы для отображения статуса договора.
class ContractStatusHelper {
  /// Стили бейджа статуса в строке таблицы договоров ([ContractTableView]).
  ///
  /// Явные **зелёный / оранжевый / серый** семантические цвета (как в [getStatusInfo]),
  /// с заливкой и обводкой; для тёмной темы подобраны более светлые оттенки текста.
  static ({String label, Color foreground, Color fill, Color border})
  tableBadgePalette(ContractStatus status, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    switch (status) {
      case ContractStatus.active:
        if (isDark) {
          return (
            label: 'В работе',
            foreground: const Color(0xFFC8E6C9),
            fill: Colors.green.withValues(alpha: 0.28),
            border: const Color(0xFF66BB6A).withValues(alpha: 0.85),
          );
        }
        return (
          label: 'В работе',
          foreground: const Color(0xFF1B5E20),
          fill: Colors.green.withValues(alpha: 0.22),
          border: const Color(0xFF43A047).withValues(alpha: 0.9),
        );
      case ContractStatus.suspended:
        if (isDark) {
          return (
            label: 'Приостановлен',
            foreground: const Color(0xFFFFE0B2),
            fill: Colors.orange.withValues(alpha: 0.28),
            border: const Color(0xFFFFB74D).withValues(alpha: 0.88),
          );
        }
        return (
          label: 'Приостановлен',
          foreground: const Color(0xFFE65100),
          fill: Colors.orange.withValues(alpha: 0.22),
          border: const Color(0xFFFF9800).withValues(alpha: 0.95),
        );
      case ContractStatus.completed:
        if (isDark) {
          return (
            label: 'Завершен',
            foreground: const Color(0xFFE0E0E0),
            fill: Colors.blueGrey.withValues(alpha: 0.32),
            border: const Color(0xFF90A4AE).withValues(alpha: 0.75),
          );
        }
        return (
          label: 'Завершен',
          foreground: const Color(0xFF424242),
          fill: Colors.grey.withValues(alpha: 0.22),
          border: const Color(0xFF9E9E9E).withValues(alpha: 0.95),
        );
    }
  }

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

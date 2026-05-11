import 'package:flutter/widgets.dart';

import 'package:projectgt/core/utils/responsive_utils.dart';

/// Единые отступы вкладки «Данные» и карточек сводки по смене.
///
/// Базовые константы ([cardPadding], [betweenCards], …) сохраняют прежний ритм
/// для планшета и десктопа. Для узкого телефона ([ResponsiveUtils.isMobile],
/// ширина меньше [ResponsiveUtils.tabletBreakpoint]) используйте методы `*Of`,
/// ориентированные на Material 3 (48dp цели касания, зазоры 8dp+) и iOS HIG
/// (44pt минимум для интерактива).
abstract final class WorkDetailDataSpacing {
  /// Внутренние поля карточек сводки (планшет, десктоп, общий fallback).
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(18, 18, 18, 16);

  /// Внутренние поля карточек на узком телефоне.
  static const EdgeInsets mobileCardPadding = EdgeInsets.fromLTRB(
    20,
    20,
    20,
    18,
  );

  /// Заголовок секции → основной контент карточки.
  static const double titleToContent = 12;

  /// То же для узкого телефона.
  static const double mobileTitleToContent = 14;

  /// Между строками внутри списка в карточке.
  static const double listRowGap = 12;

  /// То же для узкого телефона (ритм между строками списков).
  static const double mobileListRowGap = 16;

  /// Вертикальный зазор между карточками на вкладке «Данные».
  static const double betweenCards = 16;

  /// То же для узкого телефона.
  static const double mobileBetweenCards = 20;

  /// Разделитель между блоками внутри одной карточки (вертикальные поля вокруг [Divider]).
  static const double dividerVerticalPadding = 14;

  /// То же для узкого телефона.
  static const double mobileDividerVerticalPadding = 16;

  /// Зазор между колонками фото на десктопе.
  static const double photoTwinGap = 18;

  /// Иконка ↔ подпись в сегменте табов «Данные / Работы / Сотрудники».
  static const double segmentIconGap = 8;

  /// Иконка ↔ подпись в сегменте на узком телефоне.
  static const double mobileSegmentIconGap = 10;

  /// Внутренние поля одного сегмента (телефон вне десктопного хрома).
  static const EdgeInsets segmentItemPadding = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 10,
  );

  /// Поля сегмента на узком телефоне (~48dp по высоте с иконкой и подписью).
  static const EdgeInsets mobileSegmentItemPadding = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 10,
  );

  /// Радиус внешней «капсулы» сегмент-контроля «Данные / Работы / Сотрудники».
  ///
  /// Согласован с [TimesheetEmployeeListScopeSegment] (`_radius`).
  static const double segmentControlTrackRadius = 18;

  /// Внутренний отступ трека сегмент-контроля (ползунок ближе к краю капсулы).
  ///
  /// Согласован с [TimesheetEmployeeListScopeSegment] (padding вокруг `Row`).
  static const EdgeInsets segmentControlTrackPadding = EdgeInsets.all(2);

  /// Высота переключателя вкладок смены на узком телефоне (как у [TimesheetEmployeeListScopeSegment]).
  static const double mobileWorkTabSegmentBarHeight = 34;

  /// Поля подписи в компактной ячейке переключателя вкладок смены на телефоне (как в табеле).
  static const EdgeInsets mobileWorkTabSegmentTextPadding =
      EdgeInsets.symmetric(horizontal: 4, vertical: 4);

  /// Скругление внешней карточки «вкладки + фильтры» на узком телефоне.
  static const double mobileUnifiedToolbarRadius = 20;

  /// Радиус внутреннего трека сегмента внутри карточки [mobileUnifiedToolbarRadius].
  static const double mobileEmbeddedSegmentRadius = 14;

  /// Горизонтальные поля скролла вкладки «Данные» на узком телефоне.
  static const double mobileScrollHorizontal = 20;

  /// Нижний отступ скролла вкладки «Данные» на узком телефоне.
  static const double mobileScrollBottom = 28;

  /// Отступ от верха контента до сегмент-бара на узком телефоне.
  static const double mobileSegmentTopGap = 16;

  /// Поля вертикальных списков вкладок «Работы» и «Сотрудники» на узком телефоне.
  static const EdgeInsets mobileTabListPadding = EdgeInsets.fromLTRB(
    mobileScrollHorizontal,
    16,
    mobileScrollHorizontal,
    16,
  );

  /// Заголовок карточки фото (иконка + текст) — планшет и десктоп.
  static const EdgeInsets photoCardHeaderPadding = EdgeInsets.fromLTRB(
    18,
    16,
    18,
    12,
  );

  /// Заголовок карточки фото на узком телефоне.
  static const EdgeInsets mobilePhotoCardHeaderPadding = EdgeInsets.fromLTRB(
    20,
    18,
    20,
    14,
  );

  /// Зазор под кругом KPI до числа в [WorkStatsCard] (планшет/десктоп).
  static const double statIconToValueGap = 10;

  /// То же на узком телефоне.
  static const double mobileStatIconToValueGap = 12;

  /// Зазор между числом и подписью KPI.
  static const double statValueToLabelGap = 6;

  /// То же на узком телефоне.
  static const double mobileStatValueToLabelGap = 8;

  // --- Десктоп: единый блок «табы + фильтры» в правой панели ---

  /// Внешние поля карточки-хрома (согласовано с отступами списка договоров / панели месяца).
  static const EdgeInsets desktopHeaderOuter = EdgeInsets.fromLTRB(
    20,
    20,
    20,
    0,
  );

  /// Скругление внешней оболочки блока табов.
  static const double desktopHeaderRadius = 14;

  /// Поля вокруг сегментированного переключателя внутри хрома.
  static const EdgeInsets desktopHeaderSegmentInner = EdgeInsets.fromLTRB(
    12,
    10,
    12,
    10,
  );

  /// Горизонтальный отступ обводки разделителя «табы | фильтры».
  static const double desktopHeaderDividerInset = 12;

  /// Поля зоны фильтров под разделителем.
  static const EdgeInsets desktopHeaderFiltersInner = EdgeInsets.fromLTRB(
    14,
    12,
    14,
    16,
  );

  /// Поля сегмента таба в десктопном хроме (≈44px по высоте цели).
  static const EdgeInsets desktopSegmentItemPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 12,
  );

  /// Внутренние поля карточки сводки: телефон — [mobileCardPadding], иначе [cardPadding].
  static EdgeInsets cardPaddingOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context) ? mobileCardPadding : cardPadding;
  }

  /// Вертикальный зазор между карточками на вкладке «Данные» (телефон или планшет/десктоп).
  static double betweenCardsOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobileBetweenCards
        : betweenCards;
  }

  /// Заголовок карточки → контент.
  static double titleToContentOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobileTitleToContent
        : titleToContent;
  }

  /// Между строками списка внутри карточки.
  static double listRowGapOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context) ? mobileListRowGap : listRowGap;
  }

  /// Вертикальные поля вокруг разделителя внутри карточки.
  static double dividerVerticalPaddingOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobileDividerVerticalPadding
        : dividerVerticalPadding;
  }

  /// Поля ячейки сегмента (не десктопный хром).
  static EdgeInsets segmentItemPaddingOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobileSegmentItemPadding
        : segmentItemPadding;
  }

  /// Зазор иконка — подпись в сегменте.
  static double segmentIconGapOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobileSegmentIconGap
        : segmentIconGap;
  }

  /// Поля заголовка в карточке фото смены.
  static EdgeInsets photoCardHeaderPaddingOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobilePhotoCardHeaderPadding
        : photoCardHeaderPadding;
  }

  /// Зазор «иконка KPI → значение» в [WorkStatsCard].
  static double statIconToValueGapOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobileStatIconToValueGap
        : statIconToValueGap;
  }

  /// Зазор «значение KPI → подпись» в [WorkStatsCard].
  static double statValueToLabelGapOf(BuildContext context) {
    return ResponsiveUtils.isMobile(context)
        ? mobileStatValueToLabelGap
        : statValueToLabelGap;
  }
}
